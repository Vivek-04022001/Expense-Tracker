import 'package:intl/intl.dart';

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.paymentMethod,
    required this.date,
    required this.createdAt,
    required this.userId,
  });

  final String id;
  final double amount;
  final String category;
  final String? description;
  final String paymentMethod;
  final DateTime date;
  final DateTime createdAt;
  final String userId;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        amount: double.parse(json['amount'] as String),
        category: json['category'] as String,
        description: json['description'] as String?,
        paymentMethod: json['paymentMethod'] as String,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        userId: json['userId'] as String,
      );

  String get formattedAmount =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);

  String get formattedDate => DateFormat('d MMM yyyy').format(date);
}

class PaginationModel {
  const PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory PaginationModel.fromJson(Map<String, dynamic> json) => PaginationModel(
        page: json['page'] as int,
        limit: json['limit'] as int,
        total: json['total'] as int,
        totalPages: json['totalPages'] as int,
      );
}

class ExpenseListResponse {
  const ExpenseListResponse({
    required this.expenses,
    required this.pagination,
  });

  final List<ExpenseModel> expenses;
  final PaginationModel pagination;

  factory ExpenseListResponse.fromJson(Map<String, dynamic> json) =>
      ExpenseListResponse(
        expenses: (json['expenses'] as List<dynamic>)
            .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination:
            PaginationModel.fromJson(json['pagination'] as Map<String, dynamic>),
      );
}

class ExpenseSummaryCategory {
  const ExpenseSummaryCategory({
    required this.category,
    required this.total,
    required this.count,
  });

  final String category;
  final double total;
  final int count;

  factory ExpenseSummaryCategory.fromJson(Map<String, dynamic> json) =>
      ExpenseSummaryCategory(
        category: json['category'] as String,
        total: (json['total'] as num).toDouble(),
        count: json['count'] as int,
      );
}

class ExpenseSummary {
  const ExpenseSummary({
    required this.totalExpenses,
    required this.byCategory,
  });

  final double totalExpenses;
  final List<ExpenseSummaryCategory> byCategory;

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>;
    return ExpenseSummary(
      totalExpenses: (summary['totalExpenses'] as num).toDouble(),
      byCategory: (summary['byCategory'] as List<dynamic>)
          .map((e) =>
              ExpenseSummaryCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
