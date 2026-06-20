import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/expense_summary_model.dart';
import '../../data/repositories/expense_repository.dart';

part 'expense_provider.g.dart';

@riverpod
ExpenseRepository expenseRepository(ExpenseRepositoryRef ref) =>
    ExpenseRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(syncEngineProvider),
    );

@riverpod
class SelectedExpenseMonth extends _$SelectedExpenseMonth {
  @override
  DateTime build() => DateTime.now();

  void setMonth(int year, int month) => state = DateTime(year, month);
}

@riverpod
class ExpenseListNotifier extends _$ExpenseListNotifier {
  @override
  Future<List<ExpenseModel>> build() async {
    final month = ref.watch(selectedExpenseMonthProvider);
    return _fetchMonth(month);
  }

  Future<List<ExpenseModel>> _fetchMonth(DateTime month) {
    final repo = ref.read(expenseRepositoryProvider);
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return repo.getExpenses(from: from, to: to);
  }

  Future<void> create({
    required double amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    String? accountId,
    String? categoryId,
  }) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final expense = await repo.createExpense(
        amount: amount,
        description: description,
        category: category,
        paymentMethod: paymentMethod,
        accountId: accountId,
        categoryId: categoryId,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([expense, ...current]);
      _invalidateRelated();
    } on AppException {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.deleteExpense(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
    _invalidateRelated();
  }

  Future<void> edit(
    String id, {
    double? amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
  }) async {
    final repo = ref.read(expenseRepositoryProvider);
    final updated = await repo.updateExpense(
      id,
      amount: amount,
      description: description,
      category: category,
      paymentMethod: paymentMethod,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((e) => e.id == id ? updated : e).toList(),
    );
    _invalidateRelated();
  }

  void _invalidateRelated() {
    ref.invalidate(expenseSummaryProvider);
    ref.invalidate(currentMonthExpensesProvider);
    ref.invalidate(expensesForMonthProvider);
    ref.invalidate(currentMonthSavingsProvider);
    ref.invalidate(allTimeSavingsProvider);
    // Account balances change when an expense is added/edited/removed.
    ref.invalidate(accountListNotifierProvider);
  }
}

@riverpod
Future<ExpenseSummaryModel> expenseSummary(ExpenseSummaryRef ref) =>
    ref.watch(expenseRepositoryProvider).getExpenseSummary();

@riverpod
Future<List<ExpenseModel>> currentMonthExpenses(
  CurrentMonthExpensesRef ref,
) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month);
  final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return repo.getExpenses(from: from, to: to);
}

@riverpod
Future<List<ExpenseModel>> expensesForMonth(
  ExpensesForMonthRef ref,
  DateTime month,
) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final from = DateTime(month.year, month.month);
  final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  return repo.getExpenses(from: from, to: to);
}
