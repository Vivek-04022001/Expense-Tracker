import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '_inner_app_bar.dart';

class _ThemeOption {
  const _ThemeOption(this.label, this.icon, this.color, this.subtitle);
  final String label;
  final PhosphorIconData icon;
  final Color color;
  final String subtitle;
}

final _themeOptions = [
  _ThemeOption(
    'Light',
    PhosphorIcons.sun(PhosphorIconsStyle.fill),
    AppColors.warning,
    'Always use light mode',
  ),
  _ThemeOption(
    'Dark',
    PhosphorIcons.moon(PhosphorIconsStyle.fill),
    const Color(0xFF3D3D4E),
    'Always use dark mode',
  ),
  _ThemeOption(
    'System',
    PhosphorIcons.deviceMobile(PhosphorIconsStyle.fill),
    AppColors.info,
    'Follow device setting',
  ),
];

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Theme'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _themeOptions.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 64, color: context.borderSubtle),
            itemBuilder: (_, i) {
              final opt = _themeOptions[i];
              final isSelected = opt.label == current;
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(opt.label),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: opt.color,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            opt.icon,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary500
                                    : context.textPrimary,
                              ),
                            ),
                            Text(
                              opt.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
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
            },
          ),
        ),
      ),
    );
  }
}
