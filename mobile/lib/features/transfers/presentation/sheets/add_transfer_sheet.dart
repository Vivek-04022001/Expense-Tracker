import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/widgets/account_selector.dart';
import '../providers/transfer_provider.dart';

class AddTransferSheet extends ConsumerStatefulWidget {
  const AddTransferSheet({super.key});

  @override
  ConsumerState<AddTransferSheet> createState() => _AddTransferSheetState();
}

class _AddTransferSheetState extends ConsumerState<AddTransferSheet> {
  String _amount = '';
  String? _fromId;
  String? _toId;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _numpadTap(String key) {
    setState(() {
      switch (key) {
        case '⌫':
          if (_amount.isNotEmpty) {
            _amount = _amount.substring(0, _amount.length - 1);
          }
        case '.':
          if (!_amount.contains('.')) {
            _amount = _amount.isEmpty ? '0.' : '$_amount.';
          }
        default:
          if (_amount.length < 10) _amount += key;
      }
    });
  }

  bool get _canSave {
    final value = double.tryParse(_amount);
    return value != null &&
        value > 0 &&
        _fromId != null &&
        _toId != null &&
        _fromId != _toId &&
        !_saving;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      await ref.read(transferListNotifierProvider.notifier).create(
            amount: double.parse(_amount),
            fromAccountId: _fromId!,
            toAccountId: _toId!,
            description: _noteCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transfer')),
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
                      'Transfer',
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
              const SizedBox(height: 20),
              // Amount
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
                      color: _amount.isEmpty
                          ? context.textTertiary
                          : context.textPrimary,
                    ),
                  ),
                  Text(
                    _amount.isEmpty ? '0' : _amount,
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: _amount.isEmpty
                          ? context.textTertiary
                          : context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Label('From'),
              const SizedBox(height: 6),
              AccountSelector(
                selectedId: _fromId,
                includeNone: false,
                excludeId: _toId,
                onChanged: (id) => setState(() => _fromId = id),
              ),
              const SizedBox(height: 12),
              _Label('To'),
              const SizedBox(height: 6),
              AccountSelector(
                selectedId: _toId,
                includeNone: false,
                excludeId: _fromId,
                onChanged: (id) => setState(() => _toId = id),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _noteCtrl,
                  style: TextStyle(color: context.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Note (optional)',
                    hintStyle: TextStyle(color: context.textTertiary),
                    filled: true,
                    fillColor: context.bgSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
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
                    onPressed: _canSave ? _save : null,
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
                        : const Text(
                            'Save transfer',
                            style: TextStyle(
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: context.textTertiary,
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
