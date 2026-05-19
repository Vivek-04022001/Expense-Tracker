import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/insights_screen.dart';

class InsightsHeader extends StatelessWidget {
  const InsightsHeader({
    super.key,
    required this.selected,
    required this.months,
    required this.onSelect,
  });

  final InsightsMonth selected;
  final List<InsightsMonth> months;
  final void Function(InsightsMonth) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Insights',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: context.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4),
                  PhosphorIcon(
                    PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                    size: 12,
                    color: context.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MonthPickerSheet(
        selected: selected,
        months: months,
        onSelect: (m) {
          onSelect(m);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  const _MonthPickerSheet({
    required this.selected,
    required this.months,
    required this.onSelect,
  });

  final InsightsMonth selected;
  final List<InsightsMonth> months;
  final void Function(InsightsMonth) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ...months.map((m) {
            final isSelected =
                m.month == selected.month && m.year == selected.year;
            return GestureDetector(
              onTap: () => onSelect(m),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary500.withValues(alpha: 0.4)
                        : context.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary500
                            : context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      PhosphorIcon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        size: 16,
                        color: AppColors.primary500,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
