class TransferModel {
  const TransferModel({
    required this.id,
    required this.amount,
    required this.fromAccountId,
    required this.toAccountId,
    required this.createdAt,
    this.description,
  });

  final String id;
  final double amount;
  final String fromAccountId;
  final String toAccountId;
  final DateTime createdAt;
  final String? description;

  factory TransferModel.fromJson(Map<String, dynamic> json) => TransferModel(
        id: json['id'] as String,
        amount: double.parse(json['amount'].toString()),
        fromAccountId: json['fromAccountId'] as String,
        toAccountId: json['toAccountId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String?,
      );
}
