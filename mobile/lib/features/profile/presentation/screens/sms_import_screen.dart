import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  bool _enabled = true;
  bool _showUnknown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      appBar: const InnerAppBar(title: 'SMS Auto-Import'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _ToggleRow(
                  icon: PhosphorIcons.chatText(PhosphorIconsStyle.fill),
                  iconBg: AppColors.success,
                  label: 'Enable SMS import',
                  subtitle: 'Auto-detect transactions from bank SMS',
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                if (_enabled) ...[
                  const Divider(height: 24, color: AppColors.lightBorderSubtle),
                  _ToggleRow(
                    icon: PhosphorIcons.question(PhosphorIconsStyle.fill),
                    iconBg: AppColors.lightTextTertiary,
                    label: 'Show unrecognised SMS',
                    subtitle: 'Review SMS that could not be parsed',
                    value: _showUnknown,
                    onChanged: (v) => setState(() => _showUnknown = v),
                  ),
                ],
              ],
            ),
          ),
          if (_enabled) ...[
            const SizedBox(height: 24),
            const Text('ACCURACY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  _StatRow(label: 'SMS scanned this month', value: '143'),
                  const Divider(height: 20, color: AppColors.lightBorderSubtle),
                  _StatRow(label: 'Transactions imported', value: '87'),
                  const Divider(height: 20, color: AppColors.lightBorderSubtle),
                  _StatRow(label: 'Parse accuracy', value: '98%', valueColor: AppColors.success),
                  const Divider(height: 20, color: AppColors.lightBorderSubtle),
                  _StatRow(label: 'Unrecognised', value: '3'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('SUPPORTED BANKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: ['HDFC Bank', 'ICICI Bank', 'SBI', 'Axis Bank', 'Kotak', 'Yes Bank', 'IndusInd'].map((bank) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            PhosphorIcon(PhosphorIcons.bank(PhosphorIconsStyle.fill), size: 18, color: AppColors.lightTextSecondary),
                            const SizedBox(width: 14),
                            Text(bank, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
                            ),
                          ],
                        ),
                      ),
                      if (bank != 'IndusInd') const Divider(height: 1, indent: 46, color: AppColors.lightBorderSubtle),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.icon, required this.iconBg, required this.label, required this.subtitle, required this.value, required this.onChanged});
  final PhosphorIconData icon;
  final Color iconBg;
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)), child: Center(child: PhosphorIcon(icon, size: 17, color: Colors.white))),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary500),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.lightTextSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.lightTextPrimary)),
      ],
    );
  }
}
