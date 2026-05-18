class SavingsModel {
  const SavingsModel({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netSavings,
    required this.savingsRate,
  });

  final double totalIncome;
  final double totalExpenses;
  final double netSavings;
  final double savingsRate;

  factory SavingsModel.fromJson(Map<String, dynamic> json) => SavingsModel(
        totalIncome: double.parse(json['totalIncome'].toString()),
        totalExpenses: double.parse(json['totalExpenses'].toString()),
        netSavings: double.parse(json['netSavings'].toString()),
        savingsRate: double.parse(json['savingsRate'].toString()),
      );
}
