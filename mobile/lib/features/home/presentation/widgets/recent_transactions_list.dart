import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  static const _transactions = [
    _Tx(name: 'Swiggy', category: 'Food', time: '7:12 PM', payment: 'UPI', amount: 342),
    _Tx(name: 'Uber', category: 'Transport', time: '5:44 PM', payment: 'UPI', amount: 218),
    _Tx(name: 'Blue Tokai', category: 'Food', time: '11:20 AM', payment: 'Card', amount: 480),
    _Tx(name: 'Namma Metro', category: 'Transport', time: '9:08 AM', payment: 'UPI', amount: 90),
    _Tx(name: 'BigBasket', category: 'Groceries', time: '8:55 PM', payment: 'UPI', amount: 2840),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section header
        Row(
          children: [
            const Text(
              'Recent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _transactions.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 60,
              color: AppColors.lightBorderSubtle,
            ),
            itemBuilder: (_, i) => _TransactionTile(tx: _transactions[i]),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final _Tx tx;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Category icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _categoryColor(tx.category).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: PhosphorIcon(
                _categoryIcon(tx.category),
                size: 18,
                color: _categoryColor(tx.category),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _AutoBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.category} · ${tx.time} · ${tx.payment}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '-₹${_fmt(tx.amount)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    if (v >= 1000) {
      final s = v.toString();
      // Indian grouping: last 3 then groups of 2
      if (s.length <= 3) return s;
      final last3 = s.substring(s.length - 3);
      final rest = s.substring(0, s.length - 3);
      final buf = StringBuffer();
      for (var i = 0; i < rest.length; i++) {
        if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
        buf.write(rest[i]);
      }
      return '$buf,$last3';
    }
    return v.toString();
  }

  PhosphorIconData _categoryIcon(String cat) => switch (cat) {
    'Food' => PhosphorIcons.forkKnife(PhosphorIconsStyle.fill),
    'Transport' => PhosphorIcons.car(PhosphorIconsStyle.fill),
    'Groceries' => PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill),
    _ => PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
  };

  Color _categoryColor(String cat) => switch (cat) {
    'Food' => AppColors.categoryFood,
    'Transport' => AppColors.categoryTransport,
    'Groceries' => AppColors.categoryHealth,
    _ => AppColors.categoryOther,
  };
}

class _AutoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'AUTO',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.primary500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Tx {
  const _Tx({
    required this.name,
    required this.category,
    required this.time,
    required this.payment,
    required this.amount,
  });

  final String name;
  final String category;
  final String time;
  final String payment;
  final int amount;
}
