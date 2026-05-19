import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final Set<int> _expanded = {};

  static const _faqs = [
    _Faq('How does SMS auto-import work?', 'The app reads your bank SMS messages to automatically detect and import transactions. It supports all major Indian banks. No SMS is sent to any server — parsing happens fully on-device.'),
    _Faq('Is my data stored securely?', 'All your financial data is stored locally on your device. We do not upload your transaction history to any cloud server.'),
    _Faq('How do I add a custom category?', 'Go to Profile → Categories, then tap the + button to create a new category with a custom name, icon, and color.'),
    _Faq('Can I edit an auto-imported transaction?', 'Yes. Tap any transaction to open its detail screen, then use the Recategorize or Edit options to update the details.'),
    _Faq('Why is a transaction not being imported?', 'Some SMS formats may not be recognised. You can report unrecognised SMS from Profile → SMS Auto-Import → Show unrecognised SMS.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary500.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary500, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: PhosphorIcon(PhosphorIcons.envelope(PhosphorIconsStyle.fill), size: 22, color: Colors.white)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary500)),
                      SizedBox(height: 2),
                      Text('We typically reply within 24 hours', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                    ],
                  ),
                ),
                PhosphorIcon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 14, color: AppColors.primary500),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text('FREQUENTLY ASKED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textTertiary, letterSpacing: 0.8)),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqs.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: context.borderSubtle),
              itemBuilder: (_, i) {
                final isOpen = _expanded.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isOpen) { _expanded.remove(i); } else { _expanded.add(i); }
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(_faqs[i].q, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isOpen ? AppColors.primary500 : context.textPrimary))),
                            PhosphorIcon(isOpen ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold) : PhosphorIcons.caretDown(PhosphorIconsStyle.bold), size: 14, color: context.textTertiary),
                          ],
                        ),
                        if (isOpen) ...[
                          SizedBox(height: 10),
                          Text(_faqs[i].a, style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.5)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  const _Faq(this.q, this.a);
  final String q;
  final String a;
}
