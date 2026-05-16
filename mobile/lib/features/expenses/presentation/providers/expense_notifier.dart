import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'expense_provider.dart';

part 'expense_notifier.g.dart';

// Mutation-only notifier — state is void.
// Reads are owned by ExpenseListNotifier in expense_provider.dart.
@riverpod
class ExpenseNotifier extends _$ExpenseNotifier {
  @override
  void build() {}

  Future<void> addExpense({
    required double amount,
    required String category,
    required String paymentMethod,
    String? note,
  }) async {
    await ref.read(expenseRepositoryProvider).createExpense(
          amount: amount,
          category: category,
          paymentMethod: paymentMethod,
          description: note, // backend field name is 'description'
        );
    ref.invalidate(expenseListNotifierProvider);
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    ref.invalidate(expenseListNotifierProvider);
  }
}
