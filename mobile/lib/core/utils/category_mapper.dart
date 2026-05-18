import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';
import '../../features/expenses/data/models/expense_model.dart';

abstract class CategoryMapper {
  static String label(ExpenseCategory cat) => switch (cat) {
        ExpenseCategory.foodAndDrink => 'Food & Drink',
        ExpenseCategory.transport => 'Transport',
        ExpenseCategory.billsAndUtilities => 'Bills & Utils',
        ExpenseCategory.shopping => 'Shopping',
        ExpenseCategory.health => 'Health',
        ExpenseCategory.entertainment => 'Entertainment',
        ExpenseCategory.education => 'Education',
        ExpenseCategory.other => 'Other',
      };

  static Color color(ExpenseCategory cat) => switch (cat) {
        ExpenseCategory.foodAndDrink => AppColors.categoryFood,
        ExpenseCategory.transport => AppColors.categoryTransport,
        ExpenseCategory.billsAndUtilities => AppColors.categoryBills,
        ExpenseCategory.shopping => AppColors.categoryShopping,
        ExpenseCategory.health => AppColors.categoryHealth,
        ExpenseCategory.entertainment => AppColors.categoryEntertainment,
        ExpenseCategory.education => AppColors.categoryEducation,
        ExpenseCategory.other => AppColors.categoryOther,
      };

  static PhosphorIconData icon(ExpenseCategory cat) => switch (cat) {
        ExpenseCategory.foodAndDrink =>
          PhosphorIcons.forkKnife(PhosphorIconsStyle.fill),
        ExpenseCategory.transport =>
          PhosphorIcons.car(PhosphorIconsStyle.fill),
        ExpenseCategory.billsAndUtilities =>
          PhosphorIcons.receipt(PhosphorIconsStyle.fill),
        ExpenseCategory.shopping =>
          PhosphorIcons.bag(PhosphorIconsStyle.fill),
        ExpenseCategory.health =>
          PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
        ExpenseCategory.entertainment =>
          PhosphorIcons.ticket(PhosphorIconsStyle.fill),
        ExpenseCategory.education =>
          PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
        ExpenseCategory.other =>
          PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
      };
}
