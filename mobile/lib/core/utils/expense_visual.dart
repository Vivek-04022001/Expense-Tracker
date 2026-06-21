import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../features/categories/data/models/category_model.dart';
import '../../features/expenses/data/models/expense_model.dart';
import 'category_mapper.dart';

/// The icon / color / label to render for an expense.
///
/// Custom (user-created) categories are matched by [ExpenseModel.categoryId]
/// against the user's category list; when there's no match we fall back to the
/// legacy built-in [ExpenseCategory] enum so older rows still render correctly.
class ExpenseVisual {
  const ExpenseVisual({
    required this.icon,
    required this.color,
    required this.label,
  });

  final PhosphorIconData icon;
  final Color color;
  final String label;

  static ExpenseVisual of(ExpenseModel expense, List<CategoryModel> categories) {
    if (expense.categoryId != null) {
      for (final c in categories) {
        if (c.id == expense.categoryId) {
          return ExpenseVisual(
            icon: c.phosphorIcon,
            color: c.displayColor,
            label: c.name,
          );
        }
      }
    }
    return ExpenseVisual(
      icon: CategoryMapper.icon(expense.category),
      color: CategoryMapper.color(expense.category),
      label: CategoryMapper.label(expense.category),
    );
  }
}
