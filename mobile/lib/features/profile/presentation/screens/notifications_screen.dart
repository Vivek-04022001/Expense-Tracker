import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _budgetAlerts = true;
  bool _weeklyReport = true;
  bool _importSuccess = false;
  bool _overBudget = true;
  bool _monthlyInsights = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Notifications'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupCard(
            title: 'Alerts',
            rows: [
              _NotifRow(
                icon: PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                iconBg: AppColors.primary500,
                label: 'Budget alerts',
                subtitle: 'When you exceed a budget limit',
                value: _budgetAlerts,
                onChanged: (v) => setState(() => _budgetAlerts = v),
              ),
              _NotifRow(
                icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
                iconBg: AppColors.danger,
                label: 'Over budget warning',
                subtitle: 'At 80% and 100% of budget',
                value: _overBudget,
                onChanged: (v) => setState(() => _overBudget = v),
              ),
            ],
          ),
          SizedBox(height: 20),
          _GroupCard(
            title: 'Reports',
            rows: [
              _NotifRow(
                icon: PhosphorIcons.chartBar(PhosphorIconsStyle.fill),
                iconBg: AppColors.info,
                label: 'Weekly summary',
                subtitle: 'Every Monday morning',
                value: _weeklyReport,
                onChanged: (v) => setState(() => _weeklyReport = v),
              ),
              _NotifRow(
                icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                iconBg: AppColors.categoryShopping,
                label: 'Monthly insights',
                subtitle: 'On the 1st of each month',
                value: _monthlyInsights,
                onChanged: (v) => setState(() => _monthlyInsights = v),
              ),
            ],
          ),
          SizedBox(height: 20),
          _GroupCard(
            title: 'Activity',
            rows: [
              _NotifRow(
                icon: PhosphorIcons.chatText(PhosphorIconsStyle.fill),
                iconBg: AppColors.success,
                label: 'SMS import success',
                subtitle: 'When transactions are auto-imported',
                value: _importSuccess,
                onChanged: (v) => setState(() => _importSuccess = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textTertiary, letterSpacing: 0.8)),
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
            itemCount: rows.length,
            separatorBuilder: (_, __) => Divider(height: 1, indent: 64, color: context.borderSubtle),
            itemBuilder: (_, i) => rows[i],
          ),
        ),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.icon, required this.iconBg, required this.label, required this.subtitle, required this.value, required this.onChanged});
  final PhosphorIconData icon;
  final Color iconBg;
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)), child: Center(child: PhosphorIcon(icon, size: 17, color: Colors.white))),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary500),
        ],
      ),
    );
  }
}
