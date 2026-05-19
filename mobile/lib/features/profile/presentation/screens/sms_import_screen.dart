import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sms_import/presentation/screens/sms_preview_screen.dart';
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
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'SMS Auto-Import'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Scan-now CTA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: PhosphorIcon(
                          PhosphorIcons.chatText(PhosphorIconsStyle.fill),
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan inbox for transactions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            'We read the last 30 days of bank SMS and let '
                            'you review before importing.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SmsPreviewScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Scan now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Options card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
                  Divider(height: 24, color: context.borderSubtle),
                  _ToggleRow(
                    icon: PhosphorIcons.question(PhosphorIconsStyle.fill),
                    iconBg: context.textTertiary,
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
            SizedBox(height: 24),
            Text(
              'ACCURACY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _StatRow(label: 'SMS scanned this month', value: '143'),
                  Divider(height: 20, color: context.borderSubtle),
                  _StatRow(label: 'Transactions imported', value: '87'),
                  Divider(height: 20, color: context.borderSubtle),
                  _StatRow(
                    label: 'Parse accuracy',
                    value: '98%',
                    valueColor: AppColors.success,
                  ),
                  Divider(height: 20, color: context.borderSubtle),
                  _StatRow(label: 'Unrecognised', value: '3'),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'SUPPORTED BANKS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children:
                    [
                      'HDFC Bank',
                      'ICICI Bank',
                      'SBI',
                      'Axis Bank',
                      'Kotak',
                      'Yes Bank',
                      'IndusInd',
                    ].map((bank) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.bank(PhosphorIconsStyle.fill),
                                  size: 18,
                                  color: context.textSecondary,
                                ),
                                SizedBox(width: 14),
                                Text(
                                  bank,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (bank != 'IndusInd')
                            Divider(
                              height: 1,
                              indent: 46,
                              color: context.borderSubtle,
                            ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
          SizedBox(height: 150),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: PhosphorIcon(icon, size: 17, color: Colors.white),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary500,
        ),
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
        Text(
          label,
          style: TextStyle(fontSize: 14, color: context.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? context.textPrimary,
          ),
        ),
      ],
    );
  }
}
