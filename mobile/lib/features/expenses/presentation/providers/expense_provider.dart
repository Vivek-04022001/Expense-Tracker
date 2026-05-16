import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

part 'expense_provider.g.dart';

class ExpenseFilter {
  const ExpenseFilter({
    this.category,
    this.startDate,
    this.endDate,
    this.page = 1,
  });

  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
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
      startDate: _filter.startDate,
      endDate: _filter.endDate,
      page: _filter.page,
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
