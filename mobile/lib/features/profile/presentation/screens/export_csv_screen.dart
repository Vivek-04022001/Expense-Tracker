import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class ExportCsvScreen extends StatefulWidget {
  const ExportCsvScreen({super.key});

  @override
  State<ExportCsvScreen> createState() => _ExportCsvScreenState();
}

class _ExportCsvScreenState extends State<ExportCsvScreen> {
  String _range = 'This month';
  bool _includeIncome = true;
  bool _groupByCategory = false;
  bool _exporting = false;

  final _ranges = ['This month', 'Last month', 'Last 3 months', 'Last 6 months', 'This year', 'All time'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      appBar: const InnerAppBar(title: 'Export CSV'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Date Range'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: _ranges.map((r) {
                final isSelected = r == _range;
                return GestureDetector(
                  onTap: () => setState(() => _range = r),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Text(r, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isSelected ? AppColors.primary500 : AppColors.lightTextPrimary)),
                            const Spacer(),
                            if (isSelected) PhosphorIcon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 16, color: AppColors.primary500),
                          ],
                        ),
                      ),
                      if (r != _ranges.last) const Divider(height: 1, indent: 16, color: AppColors.lightBorderSubtle),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Options'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _SwitchRow(label: 'Include income', value: _includeIncome, onChanged: (v) => setState(() => _includeIncome = v)),
                const Divider(height: 1, color: AppColors.lightBorderSubtle),
                _SwitchRow(label: 'Group by category', value: _groupByCategory, onChanged: (v) => setState(() => _groupByCategory = v)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _exporting
                ? null
                : () {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _exporting = true);
                    Future.delayed(const Duration(seconds: 2)).then((_) {
                      if (!mounted) return;
                      setState(() => _exporting = false);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('CSV exported successfully'), backgroundColor: AppColors.success),
                      );
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _exporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold), size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Export CSV', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextTertiary, letterSpacing: 0.8),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary)),
          const Spacer(),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary500),
        ],
      ),
    );
  }
}
