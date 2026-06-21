enum ExpenseCategory {
  foodAndDrink,
  transport,
  billsAndUtilities,
  shopping,
  health,
  entertainment,
  education,
  other;

  static ExpenseCategory fromServer(String value) => switch (value) {
        'food_and_drink' => foodAndDrink,
        'transport' => transport,
        'bills_and_utilities' => billsAndUtilities,
        'shopping' => shopping,
        'health' => health,
        'entertainment' => entertainment,
        'education' => education,
        _ => other,
      };

  String toServer() => switch (this) {
        ExpenseCategory.foodAndDrink => 'food_and_drink',
        ExpenseCategory.transport => 'transport',
        ExpenseCategory.billsAndUtilities => 'bills_and_utilities',
        ExpenseCategory.shopping => 'shopping',
        ExpenseCategory.health => 'health',
        ExpenseCategory.entertainment => 'entertainment',
        ExpenseCategory.education => 'education',
        ExpenseCategory.other => 'other',
      };
}

enum ExpensePaymentMethod {
  upi,
  bankTransfer,
  cash,
  other;

  static ExpensePaymentMethod fromServer(String value) => switch (value) {
        'upi' => upi,
        'bank_transfer' => bankTransfer,
        'cash' => cash,
        _ => other,
      };

  String toServer() => switch (this) {
        ExpensePaymentMethod.upi => 'upi',
        ExpensePaymentMethod.bankTransfer => 'bank_transfer',
        ExpensePaymentMethod.cash => 'cash',
        ExpensePaymentMethod.other => 'other',
      };

  String get displayLabel => switch (this) {
        ExpensePaymentMethod.upi => 'UPI',
        ExpensePaymentMethod.bankTransfer => 'Bank Transfer',
        ExpensePaymentMethod.cash => 'Cash',
        ExpensePaymentMethod.other => 'Other',
      };
}

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.userId,
    required this.createdAt,
    this.description,
    this.accountId,
    this.categoryId,
  });

  final String id;
  final double amount;
  final ExpenseCategory category;
  final ExpensePaymentMethod paymentMethod;
  final String userId;
  final DateTime createdAt;
  final String? description;
  final String? accountId;

  /// Id of the user-managed category this expense was logged under (null for
  /// expenses that only carry the legacy built-in [category] enum).
  final String? categoryId;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        amount: double.parse(json['amount'].toString()),
        category: ExpenseCategory.fromServer(json['category'] as String? ?? 'other'),
        paymentMethod: ExpensePaymentMethod.fromServer(
          json['paymentMethod'] as String? ?? 'other',
        ),
        userId: json['userId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String?,
        accountId: json['accountId'] as String?,
        categoryId: json['categoryId'] as String?,
      );
}
