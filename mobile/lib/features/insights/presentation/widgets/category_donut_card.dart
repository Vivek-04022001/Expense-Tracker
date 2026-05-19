import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/insights_screen.dart';

class CategoryDonutCard extends StatefulWidget {
  const CategoryDonutCard({super.key, required this.data});
  final InsightsData data;

  @override
  State<CategoryDonutCard> createState() => _CategoryDonutCardState();
}

class _CategoryDonutCardState extends State<CategoryDonutCard> {
  int _touchedIndex = -1;

  // Merge budget limits into category slices (match by label)
  Map<String, int> get _budgetLimits {
    final map = <String, int>{};
    for (final b in widget.data.budgets) {
      map[b.category] = b.limit;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.totalSpend;
    final slices = widget.data.categories;
    final budgetLimits = _budgetLimits;

    if (slices.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              Text(
                'By category',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.textTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Donut chart
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3.0,
                    centerSpaceRadius: 68.0,
                    startDegreeOffset: -90.0,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                          } else {
                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          }
                        });
                      },
                    ),
                    sections: List.generate(slices.length, (i) {
                      final s = slices[i];
                      final pct = total > 0 ? s.amount / total * 100 : 0.0;
                      final isTouched = i == _touchedIndex;
                      final budget = budgetLimits[s.label];
                      final budgetPct = (budget != null && budget > 0)
                          ? (s.amount / budget * 100).round()
                          : null;
                      final overBudget =
                          budget != null && s.amount > budget;

                      return PieChartSectionData(
                        color: s.color,
                        value: s.amount.toDouble(),
                        title: '',
                        showTitle: false,
                        radius: isTouched ? 56.0 : 48.0,
                        borderSide: overBudget
                            ? BorderSide(
                                color: AppColors.danger,
                                width: 2,
                              )
                            : BorderSide.none,
                        badgeWidget: pct >= 6
                            ? _SegmentBadge(
                                pct: pct.round(),
                                budgetPct: budgetPct,
                                isTouched: isTouched,
                                overBudget: overBudget,
                              )
                            : null,
                        badgePositionPercentageOffset: 0.55,
                      );
                    }),
                  ),
                ),

                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmtRupee(total),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Total Expenses',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Divider
          Container(height: 1, color: context.borderSubtle),
          SizedBox(height: 16),

          // Legend — 2-column grid
          _buildLegend(slices, total, budgetLimits),
        ],
      ),
    );
  }

  Widget _buildLegend(
    List<CategorySlice> slices,
    int total,
    Map<String, int> budgetLimits,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < slices.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _legendItem(slices[i], total, budgetLimits)),
            SizedBox(width: 12),
            if (i + 1 < slices.length)
              Expanded(
                child: _legendItem(slices[i + 1], total, budgetLimits),
              )
            else
              Expanded(child: SizedBox()),
          ],
        ),
      );
      if (i + 2 < slices.length) SizedBox(height: 0);
      rows.add(SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _legendItem(
    CategorySlice s,
    int total,
    Map<String, int> budgetLimits,
  ) {
    final pct = total > 0 ? (s.amount / total * 100).round() : 0;
    final budget = budgetLimits[s.label];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color indicator
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: s.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textTertiary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                _fmtRupee(s.amount),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (budget != null) ...[
                SizedBox(height: 1),
                Text(
                  'Budget ${_fmtRupee(budget)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: s.amount > budget
                        ? AppColors.danger
                        : context.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentBadge extends StatelessWidget {
  const _SegmentBadge({
    required this.pct,
    required this.budgetPct,
    required this.isTouched,
    required this.overBudget,
  });

  final int pct;
  final int? budgetPct;
  final bool isTouched;
  final bool overBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pct%',
          style: GoogleFonts.inter(
            fontSize: isTouched ? 14 : 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        if (budgetPct != null) ...[
          SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: overBudget
                  ? AppColors.danger.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$budgetPct%',
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String _fmtRupee(int v) => '₹${_fmtNum(v)}';

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
