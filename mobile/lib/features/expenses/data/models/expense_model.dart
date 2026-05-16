import 'package:intl/intl.dart';

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    this.description,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final double amount;       // Prisma Decimal → arrives as string, parsed here
  final String category;     // Category enum: food_and_drink | transport | ...
  final String paymentMethod; // PaymentMethod enum: upi | bank_transfer | cash | other
  final String? description;
  final String userId;
  final DateTime createdAt;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        amount: double.parse(json['amount'] as String),
        category: json['category'] as String,
        paymentMethod: json['paymentMethod'] as String,
        description: json['description'] as String?,
        userId: json['userId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get formattedAmount =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);

  String get formattedDate => DateFormat('d MMM yyyy').format(createdAt);
}

// GET /expenses → { expenses: [...] }  — no pagination
class ExpenseListResponse {
  const ExpenseListResponse({required this.expenses});

  final List<ExpenseModel> expenses;

  factory ExpenseListResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseListResponse(
        expenses: (json['expenses'] as List<dynamic>)
            .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// GET /expenses/summary — byCategory uses Prisma groupBy result shape
// { category, _sum: { amount } }
class ExpenseByCategoryItem {
  const ExpenseByCategoryItem({
    required this.category,
    required this.total,
  });

  final String category;
  final double total; // parsed from _sum.amount (Prisma Decimal string)

  factory ExpenseByCategoryItem.fromJson(Map<String, dynamic> json) {
    final sum = json['_sum'] as Map<String, dynamic>;
    final raw = sum['amount'];
    return ExpenseByCategoryItem(
      category: json['category'] as String,
      total: raw == null ? 0 : double.parse(raw.toString()),
    );
  }
}

// { month: "YYYY-MM", total: "string" }
class ExpenseByMonthItem {
  const ExpenseByMonthItem({required this.month, required this.total});

  final String month;
  final double total; // parsed from toFixed(2) string

  factory ExpenseByMonthItem.fromJson(Map<String, dynamic> json) =>
      ExpenseByMonthItem(
        month: json['month'] as String,
        total: double.parse(json['total'] as String),
      );
}

// { category, total: "string" } — inside byCategoryPerMonth
class MonthlyCategoryItem {
  const MonthlyCategoryItem({required this.category, required this.total});

  final String category;
  final double total;

  factory MonthlyCategoryItem.fromJson(Map<String, dynamic> json) =>
      MonthlyCategoryItem(
        category: json['category'] as String,
        total: double.parse(json['total'] as String),
      );
}

// { month: "YYYY-MM", categories: [...] }
class ExpenseByCategoryPerMonth {
  const ExpenseByCategoryPerMonth({
    required this.month,
    required this.categories,
  });

  final String month;
  final List<MonthlyCategoryItem> categories;

  factory ExpenseByCategoryPerMonth.fromJson(Map<String, dynamic> json) =>
      ExpenseByCategoryPerMonth(
        month: json['month'] as String,
        categories: (json['categories'] as List<dynamic>)
            .map((e) => MonthlyCategoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// Full GET /expenses/summary response
class ExpenseSummary {
  const ExpenseSummary({
    required this.allTimeTotal,
    required this.byCategory,
    required this.byMonth,
    required this.byCategoryPerMonth,
  });

  final double allTimeTotal;
  final List<ExpenseByCategoryItem> byCategory;
  final List<ExpenseByMonthItem> byMonth;
  final List<ExpenseByCategoryPerMonth> byCategoryPerMonth;

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) => ExpenseSummary(
        allTimeTotal: double.parse(json['allTimeTotal'] as String),
        byCategory: (json['byCategory'] as List<dynamic>)
            .map((e) =>
                ExpenseByCategoryItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        byMonth: (json['byMonth'] as List<dynamic>)
            .map((e) => ExpenseByMonthItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        byCategoryPerMonth: (json['byCategoryPerMonth'] as List<dynamic>)
            .map((e) => ExpenseByCategoryPerMonth.fromJson(
                e as Map<String, dynamic>))
            .toList(),
      );
}
