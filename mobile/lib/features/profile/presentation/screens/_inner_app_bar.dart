import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class InnerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InnerAppBar({super.key, required this.title, this.actions});
  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.lightBgBase,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightBorderSubtle),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                size: 18,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
      ),
      actions: actions,
    );
  }
}
