import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class _Recurring {
  const _Recurring({required this.name, required this.amount, required this.freq, required this.next, required this.color});
  final String name;
  final int amount;
  final String freq;
  final String next;
  final Color color;
}

const _items = [
  _Recurring(name: 'Rent - K. Sharma', amount: 22000, freq: 'Monthly', next: 'Jun 1', color: AppColors.categoryBills),
  _Recurring(name: 'Netflix', amount: 649, freq: 'Monthly', next: 'Jun 10', color: AppColors.categoryEntertainment),
  _Recurring(name: 'Cult Fit', amount: 999, freq: 'Monthly', next: 'Jun 5', color: AppColors.categoryHealth),
];

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      appBar: const InnerAppBar(title: 'Recurring Expenses'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final item = _items[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Center(child: PhosphorIcon(PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.fill), size: 18, color: item.color)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
                      const SizedBox(height: 3),
                      Text('${item.freq} · Next: ${item.next}', style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                    ],
                  ),
                ),
                Text(_fmtR(item.amount), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary500,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}

String _fmtR(int v) {
  if (v < 1000) return '₹$v';
  final s = v.toString();
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '₹$buf,$last3';
}
