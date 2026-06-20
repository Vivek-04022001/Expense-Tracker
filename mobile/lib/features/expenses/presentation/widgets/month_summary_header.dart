import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// `‹ Month YYYY ›` navigator with prev/next arrows and a tappable label that
/// opens the month picker. "Next" is disabled once the selected month reaches
/// the current month (no future months).
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    super.key,
    required this.selected,
    required this.onPrev,
    required this.onNext,
    required this.onTapLabel,
  });

  final DateTime selected;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTapLabel;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return selected.year == now.year && selected.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final nextEnabled = !_isCurrentMonth;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          _Arrow(
            icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
            enabled: true,
            onTap: onPrev,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTapLabel,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(selected),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    PhosphorIcon(
                      PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                      size: 12,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Arrow(
            icon: PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            enabled: nextEnabled,
            onTap: nextEnabled ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.enabled, this.onTap});
  final PhosphorIconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Center(
          child: PhosphorIcon(
            icon,
            size: 16,
            color: enabled ? context.textSecondary : context.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// 3-column Expense / Income / Total strip for the visible month.
class MonthSummaryHeader extends StatelessWidget {
  const MonthSummaryHeader({
    super.key,
    required this.expense,
    required this.income,
  });

  final double expense;
  final double income;

  @override
  Widget build(BuildContext context) {
    final total = income - expense;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          _Col(label: 'EXPENSE', value: expense, color: AppColors.danger),
          _Divider(),
          _Col(label: 'INCOME', value: income, color: AppColors.success),
          _Divider(),
          _Col(
            label: 'TOTAL',
            value: total,
            color: total < 0 ? AppColors.danger : context.textPrimary,
            signed: true,
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({
    required this.label,
    required this.value,
    required this.color,
    this.signed = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final prefix = signed && value > 0 ? '+' : '';
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: context.textTertiary,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$prefix${_fmtRupee(value.abs())}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: context.borderSubtle);
  }
}

// Indian-grouped rupee, no decimals (matches the records list style).
String _fmtRupee(double v) => '₹${_fmtNum(v.round())}';

String _fmtNum(int v) {
  if (v < 1000) return v.toString();
  final s = v.toString();
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '$buf,$last3';
}
