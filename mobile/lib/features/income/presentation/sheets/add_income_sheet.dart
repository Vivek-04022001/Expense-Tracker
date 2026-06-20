import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/calculator_numpad.dart';
import '../../../accounts/presentation/widgets/account_selector.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/widgets/category_selector.dart';
import '../../data/models/income_model.dart';
import '../providers/income_provider.dart';

class AddIncomeSheet extends ConsumerStatefulWidget {
  const AddIncomeSheet({super.key});

  @override
  ConsumerState<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends ConsumerState<AddIncomeSheet> {
  String _expr = '';
  CategoryModel? _category;
  final _descCtrl = TextEditingController();
  String? _accountId;
  bool _saving = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _descCtrl.dispose();
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
      final desc = _descCtrl.text.trim();
      final cat = _category;
      // Keep the legacy enum populated; custom categories fall back to other.
      final legacyType = cat?.key != null
          ? IncomeType.fromServer(cat!.key!)
          : IncomeType.other;
      await ref.read(incomeListNotifierProvider.notifier).create(
            amount: value,
            incomeType: legacyType,
            description: desc.isNotEmpty ? desc : null,
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
          const SnackBar(content: Text('Failed to save income')),
        );
      }
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final result = _computeResult();
    final canSave = result != null && result > 0 && !_saving;
    final isEmpty = _expr.isEmpty;
    final textColor =
        isEmpty ? context.textTertiary : context.textPrimary;

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
                        'Add income',
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
                Column(
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
                          isEmpty ? '0' : _expr,
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
                      child: _hasFullExpression && result != null
                          ? Text(
                              '= ₹${_fmtNum(result)}',
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
                ),
                SizedBox(height: 16),
                // Category chips (dynamic, user-managed)
                CategorySelector(
                  kind: CategoryKind.income,
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
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderSubtle),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Note (optional)',
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
                ),
                SizedBox(height: 8),
                // Calculator numpad
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CalculatorNumpad(onKeyTap: _onKey),
                ),
                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.success.withValues(alpha: 0.4),
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
                                  : 'Save income',
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
            ),
        ],
      ),
    );
  }
}

// ─── Success overlay ─────────────────────────────────────────────────────────

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({required this.amount});

  final String amount;

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
            color: AppColors.success,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                child:
                    Icon(Icons.check, color: Colors.white, size: 36),
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
                'Income saved',
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
