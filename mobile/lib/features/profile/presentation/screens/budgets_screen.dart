import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class _Budget {
  _Budget({required this.category, required this.limit, required this.spent, required this.color});
  final String category;
  int limit;
  final int spent;
  final Color color;
}

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _budgets = [
    _Budget(category: 'Food', limit: 8000, spent: 8420, color: AppColors.categoryFood),
    _Budget(category: 'Groceries', limit: 6000, spent: 4120, color: AppColors.categoryHealth),
    _Budget(category: 'Transport', limit: 3000, spent: 1240, color: AppColors.categoryTransport),
    _Budget(category: 'Shopping', limit: 5000, spent: 3399, color: AppColors.categoryShopping),
    _Budget(category: 'Entertainment', limit: 2000, spent: 540, color: AppColors.categoryEntertainment),
  ];

  void _editBudget(_Budget b) {
    final ctrl = TextEditingController(text: b.limit.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit ${b.category} Budget',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
            SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.textPrimary),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.textSecondary),
                filled: true,
                fillColor: context.bgBase,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderSubtle)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.borderSubtle)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary500)),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = int.tryParse(ctrl.text.trim());
                  if (v != null && v > 0) setState(() => b.limit = v);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Budgets'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _budgets.length,
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (_, i) {
          final b = _budgets[i];
          final ratio = (b.spent / b.limit).clamp(0.0, 1.0);
          final isOver = b.spent > b.limit;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: b.color, shape: BoxShape.circle)),
                    SizedBox(width: 10),
                    Text(b.category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _editBudget(b),
                      child: PhosphorIcon(PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular), size: 18, color: context.textTertiary),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: context.borderSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.danger : b.color),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(_fmtR(b.spent),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isOver ? AppColors.danger : context.textPrimary)),
                    Text(' / ${_fmtR(b.limit)}', style: TextStyle(fontSize: 13, color: context.textTertiary)),
                    const Spacer(),
                    if (isOver)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text('Over budget', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary500,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: Colors.white, size: 24),
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
