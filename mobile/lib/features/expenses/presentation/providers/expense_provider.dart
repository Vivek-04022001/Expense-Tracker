import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

part 'expense_provider.g.dart';

// Filter mirrors the GET /expenses query params: category, from, to
class ExpenseFilter {
  const ExpenseFilter({
    this.category,
    this.from,
    this.to,
  });

  final String? category;
  final DateTime? from;
  final DateTime? to;
}

@riverpod
ExpenseRepository expenseRepository(ExpenseRepositoryRef ref) =>
    ExpenseRepository(ref.watch(dioClientProvider));

@riverpod
class ExpenseListNotifier extends _$ExpenseListNotifier {
  ExpenseFilter _filter = const ExpenseFilter();

  @override
  Future<ExpenseListResponse> build() {
    final repo = ref.read(expenseRepositoryProvider);
    return repo.getExpenses(
      category: _filter.category,
      from: _filter.from,
      to: _filter.to,
    );
  }

  void applyFilter(ExpenseFilter filter) {
    _filter = filter;
    ref.invalidateSelf();
  }

  void refresh() {
    ref.invalidateSelf();
  }

  Future<void> deleteExpense(String id) async {
    await ref.read(expenseRepositoryProvider).deleteExpense(id);
    ref.invalidateSelf();
  }
}

@riverpod
Future<ExpenseSummary> expenseSummary(ExpenseSummaryRef ref) {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getSummary();
}

@riverpod
Future<Map<String, List<ExpenseModel>>> groupedExpenses(
    GroupedExpensesRef ref) async {
  final response = await ref.watch(expenseListNotifierProvider.future);
  return _groupByDate(response.expenses);
}

Map<String, List<ExpenseModel>> _groupByDate(List<ExpenseModel> expenses) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final grouped = <String, List<ExpenseModel>>{};

  for (final expense in expenses) {
    final d = expense.createdAt;
    final expenseDay = DateTime(d.year, d.month, d.day);
    final String key;
    if (expenseDay == today) {
      key = 'Today';
    } else if (expenseDay == yesterday) {
      key = 'Yesterday';
    } else {
      key = DateFormat('d MMM yyyy').format(d);
    }
    grouped.putIfAbsent(key, () => []).add(expense);
  }

  return grouped;
}
