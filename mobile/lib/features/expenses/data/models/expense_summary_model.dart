class CategoryTotal {
  const CategoryTotal({required this.category, required this.total});
  final String category;
  final double total;

  factory CategoryTotal.fromJson(Map<String, dynamic> json) => CategoryTotal(
        category: json['category'] as String,
        total: double.parse(
          (json['_sum'] as Map<String, dynamic>)['amount']?.toString() ?? '0',
        ),
      );
}

class MonthTotal {
  const MonthTotal({required this.month, required this.total});
  final String month;
  final double total;

  factory MonthTotal.fromJson(Map<String, dynamic> json) => MonthTotal(
        month: json['month'] as String,
        total: double.parse(json['total']?.toString() ?? '0'),
      );
}

class MonthCategoryBreakdown {
  const MonthCategoryBreakdown({required this.month, required this.categories});
  final String month;
  final List<CategoryTotal> categories;

  factory MonthCategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      MonthCategoryBreakdown(
        month: json['month'] as String,
        categories: (json['categories'] as List)
            .cast<Map<String, dynamic>>()
            .map((c) => CategoryTotal(
                  category: c['category'] as String,
                  total: double.parse(c['total']?.toString() ?? '0'),
                ))
            .toList(),
      );
}

class ExpenseSummaryModel {
  const ExpenseSummaryModel({
    required this.allTimeTotal,
    required this.byCategory,
    required this.byMonth,
    required this.byCategoryPerMonth,
  });

  final double allTimeTotal;
  final List<CategoryTotal> byCategory;
  final List<MonthTotal> byMonth;
  final List<MonthCategoryBreakdown> byCategoryPerMonth;

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) =>
      ExpenseSummaryModel(
        allTimeTotal: double.parse(json['allTimeTotal']?.toString() ?? '0'),
        byCategory: (json['byCategory'] as List)
            .cast<Map<String, dynamic>>()
            .map(CategoryTotal.fromJson)
            .toList(),
        byMonth: (json['byMonth'] as List)
            .cast<Map<String, dynamic>>()
            .map(MonthTotal.fromJson)
            .toList(),
        byCategoryPerMonth: (json['byCategoryPerMonth'] as List)
            .cast<Map<String, dynamic>>()
            .map(MonthCategoryBreakdown.fromJson)
            .toList(),
      );
}
