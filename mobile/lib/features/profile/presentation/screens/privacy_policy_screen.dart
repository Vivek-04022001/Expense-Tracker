import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _PolicySection(
      title: 'Data Collection',
      body: 'We collect only the information necessary to provide the expense tracking service. This includes transaction data you enter manually or that is auto-imported from SMS messages on your device.',
    ),
    _PolicySection(
      title: 'Local Storage',
      body: 'All your financial data is stored locally on your device. We do not upload your transaction history, bank details, or SMS content to any external server.',
    ),
    _PolicySection(
      title: 'SMS Access',
      body: 'When you enable SMS auto-import, the app reads your SMS inbox on-device to detect bank transaction messages. This data is processed locally and never transmitted externally.',
    ),
    _PolicySection(
      title: 'Third-Party Services',
      body: 'We do not share your personal or financial data with any third-party analytics, advertising, or data-broker services.',
    ),
    _PolicySection(
      title: 'Data Deletion',
      body: 'You can delete all your data at any time from Profile → Data → Clear all data. Uninstalling the app will also remove all locally stored information.',
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
      backgroundColor: AppColors.lightBgBase,
      appBar: const InnerAppBar(title: 'Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Last updated: May 2026',
            style: TextStyle(fontSize: 12, color: AppColors.lightTextTertiary),
          ),
          const SizedBox(height: 16),
          ..._sections.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
                  const SizedBox(height: 8),
                  Text(s.body, style: const TextStyle(fontSize: 14, color: AppColors.lightTextSecondary, height: 1.6)),
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
