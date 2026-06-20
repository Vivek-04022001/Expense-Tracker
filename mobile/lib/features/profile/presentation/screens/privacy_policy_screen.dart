import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _PolicySection(
      title: 'Data Collection',
      body: 'We collect only the information necessary to provide the expense tracking service. This includes the transaction data you enter in the app.',
    ),
    _PolicySection(
      title: 'Data Storage',
      body: 'Your transaction data is stored in your private account on our secure backend so it stays in sync across sessions. It is protected by your login credentials and is only accessible after you sign in.',
    ),
    _PolicySection(
      title: 'Third-Party Services',
      body: 'We do not share your personal or financial data with any third-party analytics, advertising, or data-broker services.',
    ),
    _PolicySection(
      title: 'Data Deletion',
      body: 'You can sign out at any time to remove your data from this device. To permanently delete your account and its data, contact us via Help & Support.',
    ),
    _PolicySection(
      title: 'Changes to This Policy',
      body: 'We may update this privacy policy from time to time. Any changes will be communicated through an in-app notice before they take effect.',
    ),
    _PolicySection(
      title: 'Contact',
      body: 'For privacy-related questions or requests, please reach out via the Help & Support section in the app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Last updated: May 2026',
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
          SizedBox(height: 16),
          ..._sections.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                  SizedBox(height: 8),
                  Text(s.body, style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.6)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({required this.title, required this.body});
  final String title;
  final String body;
}
