import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/calculator_numpad.dart';
import '../../../accounts/presentation/widgets/account_selector.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/widgets/category_selector.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  String _expr = '';
  CategoryModel? _category;
  final _merchantCtrl = TextEditingController();
  ExpensePaymentMethod _payment = ExpensePaymentMethod.upi;
  DateTime _date = DateTime.now();
  String? _accountId;
  bool _saving = false;
  bool _showSuccess = false;

  static const _paymentLabels = ['Cash', 'UPI', 'Bank Transfer'];
  static const _paymentMethods = [
    ExpensePaymentMethod.cash,
    ExpensePaymentMethod.upi,
    ExpensePaymentMethod.bankTransfer,
  ];

  @override
  void dispose() {
    _merchantCtrl.dispose();
    super.dispose();
  }

  // ─── Expression logic ───────────────────────────────────────────────────────

  static int _opIdx(String expr) {
    for (int i = 1; i < expr.length; i++) {
      if ('+-×÷'.contains(expr[i])) return i;
    }
    return -1;
  }

  double? _computeResult() {
    if (_expr.isEmpty) return null;
    final idx = _opIdx(_expr);
    if (idx < 0) return double.tryParse(_expr);
    final left = double.tryParse(_expr.substring(0, idx));
    final op = _expr[idx];
    final rightStr = _expr.substring(idx + 1);
    if (rightStr.isEmpty) return left;
    final right = double.tryParse(rightStr);
    if (left == null || right == null) return null;
    return switch (op) {
      '+' => left + right,
      '-' => left - right,
      '×' => left * right,
      '÷' => right != 0 ? left / right : null,
      _ => null,
    };
  }

  bool get _hasFullExpression {
    final idx = _opIdx(_expr);
    return idx > 0 && _expr.substring(idx + 1).isNotEmpty;
  }

  String _fmtNum(double r) {
    if (r == r.roundToDouble() && !r.isInfinite) return r.toInt().toString();
    return r.toStringAsFixed(2);
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        return;
      }

      if ('+-×÷'.contains(key)) {
        if (_expr.isEmpty) return;
        final last = _expr[_expr.length - 1];
        if ('+-×÷'.contains(last)) {
          _expr = '${_expr.substring(0, _expr.length - 1)}$key';
        } else {
          final idx = _opIdx(_expr);
          if (idx > 0 && idx < _expr.length - 1) {
            final r = _computeResult();
            if (r != null) _expr = '${_fmtNum(r)}$key';
          } else {
            _expr += key;
          }
        }
        return;
      }

      if (key == '.') {
        final idx = _opIdx(_expr);
        final seg = idx < 0 ? _expr : _expr.substring(idx + 1);
        if (seg.contains('.')) return;
        _expr += seg.isEmpty ? '0.' : '.';
        return;
      }

      if (_expr.length < 12) _expr += key;
    });
  }

  // ─── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final value = _computeResult();
    if (value == null || value <= 0) return;
    setState(() => _saving = true);
    try {
      final desc = _merchantCtrl.text.trim();
      final cat = _category;
      // Keep the legacy enum populated (SMS classifier + charts rely on it):
      // built-ins map by their stable key, custom categories fall back to other.
      final legacyCategory = cat?.key != null
          ? ExpenseCategory.fromServer(cat!.key!)
          : ExpenseCategory.other;
      await ref.read(expenseListNotifierProvider.notifier).create(
            amount: value,
            description: desc.length >= 5 ? desc : null,
            category: legacyCategory,
            paymentMethod: _payment,
            accountId: _accountId,
            categoryId: cat?.id,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _showSuccess = true;
      });
      await Future.delayed(const Duration(milliseconds: 1300));
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save expense')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.day == now.day &&
        _date.month == now.month &&
        _date.year == now.year;
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final result = _computeResult();
    final canSave = result != null && result > 0 && !_saving;

    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE1EC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 14),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Add expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: context.bgSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Amount / expression display
                _AmountDisplay(
                  expr: _expr,
                  result: result,
                  hasFullExpression: _hasFullExpression,
                  fmtNum: _fmtNum,
                ),
                SizedBox(height: 16),
                // Category chips (dynamic, user-managed)
                CategorySelector(
                  kind: CategoryKind.expense,
                  selectedId: _category?.id,
                  onChanged: (c) => setState(() => _category = c),
                ),
                SizedBox(height: 10),
                // Account selector
                AccountSelector(
                  selectedId: _accountId,
                  onChanged: (id) => setState(() => _accountId = id),
                ),
                SizedBox(height: 12),
                // Merchant + Date
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderSubtle),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _merchantCtrl,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Merchant / Note',
                              hintStyle: TextStyle(
                                color: context.textTertiary,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: context.borderSubtle,
                        ),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.calendarBlank(),
                                  size: 15,
                                  color: context.textSecondary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _isToday
                                      ? 'Today'
                                      : DateFormat('MMM d').format(_date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Payment method
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.bgSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: List.generate(
                        _paymentLabels.length,
                        (i) => _PaymentTab(
                          label: _paymentLabels[i],
                          selected: _payment == _paymentMethods[i],
                          onTap: () =>
                              setState(() => _payment = _paymentMethods[i]),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Calculator numpad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CalculatorNumpad(onKeyTap: _onKey),
                ),
                // Save button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary500.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _hasFullExpression && result != null
                                  ? 'Save ₹${_fmtNum(result)}'
                                  : 'Save expense',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Success overlay
          if (_showSuccess)
            _SuccessOverlay(
              amount: _fmtNum(_computeResult() ?? 0),
              color: AppColors.primary500,
              label: 'Expense saved',
            ),
        ],
      ),
    );
  }
}

// ─── Amount display ───────────────────────────────────────────────────────────

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({
    required this.expr,
    required this.result,
    required this.hasFullExpression,
    required this.fmtNum,
  });

  final String expr;
  final double? result;
  final bool hasFullExpression;
  final String Function(double) fmtNum;

  @override
  Widget build(BuildContext context) {
    final isEmpty = expr.isEmpty;
    final displayText = isEmpty ? '0' : expr;
    final textColor =
        isEmpty ? context.textTertiary : context.textPrimary;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                height: 1,
                color: textColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: hasFullExpression && result != null
              ? Text(
                  '= ₹${fmtNum(result!)}',
                  key: const ValueKey('result'),
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text(
                  isEmpty ? 'Enter an amount' : '',
                  key: const ValueKey('hint'),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textTertiary,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Success overlay ─────────────────────────────────────────────────────────

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({
    required this.amount,
    required this.color,
    required this.label,
  });

  final String amount;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 36),
              ),
              SizedBox(height: 20),
              Text(
                '₹$amount',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Payment tab ─────────────────────────────────────────────────────────────

class _PaymentTab extends StatelessWidget {
  const _PaymentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary500 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? Colors.white
                    : context.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
