import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class _CatItem {
  const _CatItem(this.name, this.icon, this.color);
  final String name;
  final PhosphorIconData icon;
  final Color color;
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static final _cats = [
    _CatItem('Food', PhosphorIcons.forkKnife(PhosphorIconsStyle.fill), AppColors.categoryFood),
    _CatItem('Transport', PhosphorIcons.car(PhosphorIconsStyle.fill), AppColors.categoryTransport),
    _CatItem('Groceries', PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill), AppColors.categoryHealth),
    _CatItem('Bills', PhosphorIcons.receipt(PhosphorIconsStyle.fill), AppColors.categoryBills),
    _CatItem('Shopping', PhosphorIcons.bag(PhosphorIconsStyle.fill), AppColors.categoryShopping),
    _CatItem('Entertainment', PhosphorIcons.ticket(PhosphorIconsStyle.fill), AppColors.categoryEntertainment),
    _CatItem('Health', PhosphorIcons.heartbeat(PhosphorIconsStyle.fill), AppColors.categoryHealth),
    _CatItem('Income', PhosphorIcons.arrowDown(PhosphorIconsStyle.bold), AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      appBar: const InnerAppBar(title: 'Categories'),
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cats.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 64, color: AppColors.lightBorderSubtle),
          itemBuilder: (_, i) {
            final c = _cats[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: c.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Center(child: PhosphorIcon(c.icon, size: 18, color: c.color)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary))),
                  PhosphorIcon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 14, color: AppColors.lightTextTertiary),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
