import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/expense_model.dart';
import 'category_chip.dart';

final _indiaFormat = NumberFormat('##,##,##0.00', 'en_IN');

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CategoryChip(category: expense.category),
      title: Text(
        expense.description != null && expense.description!.isNotEmpty
            ? expense.description!
            : formatCategory(expense.category),
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        _formatPaymentMethod(expense.paymentMethod),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '₹${_indiaFormat.format(expense.amount)}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      onTap: () => debugPrint('expense id: ${expense.id}'),
    );
  }

  static String _formatPaymentMethod(String method) => switch (method) {
        'upi' => 'UPI',
        'bank_transfer' => 'Bank Transfer',
        'cash' => 'Cash',
        _ => 'Other',
      };
}
