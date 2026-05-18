enum IncomeType {
  salary,
  freelance,
  investment,
  reward,
  other;

  static IncomeType fromServer(String value) => switch (value) {
        'salary' => salary,
        'freelance' => freelance,
        'investment' => investment,
        'reward' => reward,
        _ => other,
      };

  String toServer() => switch (this) {
        IncomeType.salary => 'salary',
        IncomeType.freelance => 'freelance',
        IncomeType.investment => 'investment',
        IncomeType.reward => 'reward',
        IncomeType.other => 'other',
      };

  String get displayLabel => switch (this) {
        IncomeType.salary => 'Salary',
        IncomeType.freelance => 'Freelance',
        IncomeType.investment => 'Investment',
        IncomeType.reward => 'Reward',
        IncomeType.other => 'Other',
      };
}

class IncomeModel {
  const IncomeModel({
    required this.id,
    required this.amount,
    required this.incomeType,
    required this.userId,
    required this.createdAt,
    this.description,
  });

  final String id;
  final double amount;
  final IncomeType incomeType;
  final String userId;
  final DateTime createdAt;
  final String? description;

  factory IncomeModel.fromJson(Map<String, dynamic> json) => IncomeModel(
        id: json['id'] as String,
        amount: double.parse(json['amount'].toString()),
        incomeType: IncomeType.fromServer(
          json['incomeType'] as String? ?? 'other',
        ),
        userId: json['userId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String?,
      );
}
