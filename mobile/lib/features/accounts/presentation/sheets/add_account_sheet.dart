import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';
import '../providers/account_provider.dart';

class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({super.key, this.existing});

  final AccountModel? existing;

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  late final TextEditingController _nameCtrl;
  late AccountType _type;
  late String _balance;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _type = e?.type ?? AccountType.cash;
    _balance = e == null
        ? ''
        : (e.balance == e.balance.roundToDouble()
            ? e.balance.round().toString()
            : e.balance.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _numpadTap(String key) {
    setState(() {
      switch (key) {
        case '⌫':
          if (_balance.isNotEmpty) {
            _balance = _balance.substring(0, _balance.length - 1);
          }
        case '.':
          if (!_balance.contains('.')) {
            _balance = _balance.isEmpty ? '0.' : '$_balance.';
          }
        default:
          if (_balance.length < 10) _balance += key;
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your account a name')),
      );
      return;
    }
    final balance = double.tryParse(_balance) ?? 0;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(accountListNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.edit(
          id: widget.existing!.id,
          name: name,
          type: _type,
          balance: balance,
          color: widget.existing!.color,
        );
      } else {
        await notifier.create(name: name, type: _type, balance: balance);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save account')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE1EC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _isEdit ? 'Edit account' : 'New account',
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
                        child: Icon(Icons.close,
                            size: 16, color: context.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Name field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Account name (e.g. HDFC Card)',
                    hintStyle: TextStyle(color: context.textTertiary),
                    filled: true,
                    fillColor: context.bgSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Account type visual guide
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Image.asset(
                  'assets/illustrations/account_type_icon.png',
                  width: double.infinity,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              // Type chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: AccountType.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final type = AccountType.values[i];
                    final selected = _type == type;
                    final color = type.defaultColor;
                    return GestureDetector(
                      onTap: () => setState(() => _type = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.15)
                              : context.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? color : context.borderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(type.icon,
                                size: 14,
                                color:
                                    selected ? color : context.textTertiary),
                            const SizedBox(width: 5),
                            Text(
                              type.displayLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color:
                                    selected ? color : context.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              // Balance display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: _balance.isEmpty
                          ? context.textTertiary
                          : context.textPrimary,
                    ),
                  ),
                  Text(
                    _balance.isEmpty ? '0' : _balance,
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: _balance.isEmpty
                          ? context.textTertiary
                          : context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('Current balance',
                  style: TextStyle(fontSize: 13, color: context.textTertiary)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _Numpad(onTap: _numpadTap),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
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
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            _isEdit ? 'Save changes' : 'Add account',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Numpad ────────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onTap});

  final void Function(String) onTap;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows
          .map(
            (row) => Row(
              children: row
                  .map((key) => Expanded(
                        child: _NumKey(label: key, onTap: () => onTap(key)),
                      ))
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Center(
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined,
                  size: 22, color: context.textPrimary)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
