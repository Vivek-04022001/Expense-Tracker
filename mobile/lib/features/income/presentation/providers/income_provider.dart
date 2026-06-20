import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../savings/presentation/providers/savings_provider.dart';
import '../../data/models/income_model.dart';
import '../../data/repositories/income_repository.dart';

part 'income_provider.g.dart';

@riverpod
IncomeRepository incomeRepository(IncomeRepositoryRef ref) =>
    IncomeRepository(ref.watch(dioClientProvider));

@riverpod
class IncomeListNotifier extends _$IncomeListNotifier {
  @override
  Future<List<IncomeModel>> build() async {
    final month = ref.watch(selectedIncomeMonthProvider);
    return _fetchMonth(month);
  }

  Future<List<IncomeModel>> _fetchMonth(DateTime month) {
    final repo = ref.read(incomeRepositoryProvider);
    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return repo.getIncomes(from: from, to: to);
  }

  Future<void> create({
    required double amount,
    IncomeType? incomeType,
    String? description,
    String? accountId,
    String? categoryId,
  }) async {
    final repo = ref.read(incomeRepositoryProvider);
    final income = await repo.createIncome(
      amount: amount,
      incomeType: incomeType,
      description: description,
      accountId: accountId,
      categoryId: categoryId,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([income, ...current]);
    _invalidateRelated();
  }

  Future<void> delete(String id) async {
    final repo = ref.read(incomeRepositoryProvider);
    await repo.deleteIncome(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
    _invalidateRelated();
  }

  Future<void> edit(
    String id, {
    double? amount,
    IncomeType? incomeType,
    String? description,
  }) async {
    final repo = ref.read(incomeRepositoryProvider);
    final updated = await repo.updateIncome(
      id,
      amount: amount,
      incomeType: incomeType,
      description: description,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((e) => e.id == id ? updated : e).toList(),
    );
    _invalidateRelated();
  }

  void _invalidateRelated() {
    ref.invalidate(currentMonthIncomesProvider);
    ref.invalidate(expenseSummaryProvider);
    ref.invalidate(currentMonthSavingsProvider);
    ref.invalidate(allTimeSavingsProvider);
    // Account balances change when income is added/edited/removed.
    ref.invalidate(accountListNotifierProvider);
  }
}

@riverpod
class SelectedIncomeMonth extends _$SelectedIncomeMonth {
  @override
  DateTime build() => DateTime.now();

  void setMonth(int year, int month) => state = DateTime(year, month);
}

@riverpod
Future<List<IncomeModel>> currentMonthIncomes(
  CurrentMonthIncomesRef ref,
) async {
  final repo = ref.watch(incomeRepositoryProvider);
  final now = DateTime.now();
  final from = DateTime(now.year, now.month);
  final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return repo.getIncomes(from: from, to: to);
}
