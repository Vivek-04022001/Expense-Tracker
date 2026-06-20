import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/utils/category_mapper.dart';
import '../../features/expenses/data/models/expense_model.dart';

/// A colored circle (or rounded square) holding a category glyph.
///
/// Single source of truth for the "category avatar" look used across Records,
/// Budgets, transaction tiles and detail screens. Pass [radius] for a rounded
/// square; leave it null for a circle.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize,
    this.radius,
    this.backgroundAlpha = 0.12,
  });

  /// Builds an avatar for an [ExpenseCategory] using the shared [CategoryMapper].
  CategoryAvatar.expense(
    ExpenseCategory category, {
    super.key,
    this.size = 40,
    this.iconSize,
    this.radius,
    this.backgroundAlpha = 0.12,
  })  : icon = CategoryMapper.icon(category),
        color = CategoryMapper.color(category);

  final PhosphorIconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  /// Corner radius for a rounded square. When null the avatar is a circle.
  final double? radius;
  final double backgroundAlpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: backgroundAlpha),
        shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: radius == null ? null : BorderRadius.circular(radius!),
      ),
      child: Center(
        child: PhosphorIcon(
          icon,
          size: iconSize ?? size * 0.45,
          color: color,
        ),
      ),
    );
  }
}
