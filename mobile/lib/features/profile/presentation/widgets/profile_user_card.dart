import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileUserCard extends StatelessWidget {
  const ProfileUserCard({
    super.key,
    required this.name,
    required this.phone,
    required this.onEdit,
  });

  final String name;
  final String phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.categoryShopping,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: PhosphorIcon(
              PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
              size: 20,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
