import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/insights_screen.dart';

class TopMerchantsCard extends StatelessWidget {
  const TopMerchantsCard({super.key, required this.data});
  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Top merchants',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.merchants.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.lightBorderSubtle,
            ),
            itemBuilder: (_, i) => _MerchantRow(item: data.merchants[i]),
          ),
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.item});
  final MerchantItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lightBgBase,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightBorderSubtle),
            ),
            child: Center(
              child: Text(
                item.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.txCount} transaction${item.txCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmtRupee(item.amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
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
