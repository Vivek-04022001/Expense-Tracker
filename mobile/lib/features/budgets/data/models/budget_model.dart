import '../../../expenses/data/models/expense_model.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  final String id;
  final ExpenseCategory category;
  final double limitAmount;
  final int month;
  final int year;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        category: ExpenseCategory.fromServer(json['category'] as String? ?? 'other'),
        limitAmount: double.parse(json['limitAmount'].toString()),
        month: json['month'] as int,
        year: json['year'] as int,
      );
}

class BudgetStatusModel {
  const BudgetStatusModel({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.isOverBudget,
  });

  final BudgetModel budget;
  final double spent;
  final double remaining;
  final double percentUsed;
  final bool isOverBudget;

  factory BudgetStatusModel.fromJson(Map<String, dynamic> json) {
    final budget = BudgetModel.fromJson(json['budget'] as Map<String, dynamic>);
    final status = json['status'] as Map<String, dynamic>;
    return BudgetStatusModel(
      budget: budget,
      spent: double.parse(status['spent'].toString()),
      remaining: double.parse(status['remaining'].toString()),
      percentUsed: double.parse(status['percentUsed'].toString()),
      isOverBudget: status['isOverBudget'] as bool,
    );
  }
}
