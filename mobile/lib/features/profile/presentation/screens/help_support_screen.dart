import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

const _supportEmail = 'support@expensetracker.app';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final Set<int> _expanded = {};

  Future<void> _contactSupport() async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support email copied to clipboard'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  static const _faqs = [
    _Faq('How do I add an expense?', 'Tap the + button on the home or expenses screen, enter the amount on the calculator-style keypad, pick a category and account, then save.'),
    _Faq('Is my data stored securely?', 'Your data is stored in your private account on our backend and is only accessible after you sign in. We never share it with third parties.'),
    _Faq('How do I add a custom category?', 'Go to Profile → Categories, then tap the + button to create a new category with a custom name, icon, and color.'),
    _Faq('Can I edit a transaction?', 'Yes. Tap any transaction to open its detail screen, then use the Recategorize or Edit options to update the details.'),
    _Faq('How do budgets work?', 'Go to Profile → Budgets to set a monthly limit per category. The app tracks your spending against each budget and nudges you as you approach the limit.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _contactSupport,
            behavior: HitTestBehavior.opaque,
            child: Container(
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
                      Text(_supportEmail, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                    ],
                  ),
                ),
                PhosphorIcon(PhosphorIcons.copy(PhosphorIconsStyle.bold), size: 16, color: AppColors.primary500),
              ],
            ),
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
