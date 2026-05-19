import '../../../expenses/data/models/expense_model.dart';
import '../../../income/data/models/income_model.dart';

enum TxnDirection { debit, credit }

class ParsedTransaction {
  ParsedTransaction({
    required this.amount,
    required this.direction,
    required this.date,
    required this.bank,
    required this.rawSms,
    required this.sender,
    this.merchant,
    this.suggestedCategory,
    this.suggestedIncomeType,
    this.paymentMethod,
  });

  final double amount;
  final TxnDirection direction;
  final DateTime date;
  final String bank;
  final String rawSms;
  final String sender;
  final String? merchant;
  final ExpenseCategory? suggestedCategory;
  final IncomeType? suggestedIncomeType;
  final ExpensePaymentMethod? paymentMethod;

  bool get isDebit => direction == TxnDirection.debit;
  bool get isCredit => direction == TxnDirection.credit;

  String get displayTitle {
    if (merchant != null && merchant!.isNotEmpty) return merchant!;
    return isDebit ? '$bank debit' : '$bank credit';
  }

  String get fingerprint =>
      '${direction.name}_${amount.toStringAsFixed(2)}_'
      '${date.toIso8601String().substring(0, 16)}_'
      '${(merchant ?? sender).toLowerCase()}';

  ParsedTransaction copyWith({
    ExpenseCategory? suggestedCategory,
    IncomeType? suggestedIncomeType,
  }) =>
      ParsedTransaction(
        amount: amount,
        direction: direction,
        date: date,
        bank: bank,
        rawSms: rawSms,
        sender: sender,
        merchant: merchant,
        suggestedCategory: suggestedCategory ?? this.suggestedCategory,
        suggestedIncomeType: suggestedIncomeType ?? this.suggestedIncomeType,
        paymentMethod: paymentMethod,
      );
}
