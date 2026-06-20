import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budget_repository.dart';

part 'budget_provider.g.dart';

@riverpod
BudgetRepository budgetRepository(BudgetRepositoryRef ref) =>
    BudgetRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(syncEngineProvider),
    );

@riverpod
class SelectedBudgetMonth extends _$SelectedBudgetMonth {
  @override
  DateTime build() => DateTime.now();

  void setMonth(int year, int month) => state = DateTime(year, month);
}

@riverpod
class BudgetListNotifier extends _$BudgetListNotifier {
  @override
  Future<List<BudgetModel>> build() async {
    final month = ref.watch(selectedBudgetMonthProvider);
    return ref
        .watch(budgetRepositoryProvider)
        .getBudgets(month: month.month, year: month.year);
  }

  Future<void> upsert({
    required ExpenseCategory category,
    required double limitAmount,
  }) async {
    final month = ref.read(selectedBudgetMonthProvider);
    final repo = ref.read(budgetRepositoryProvider);
    final updated = await repo.upsertBudget(
      category: category,
      limitAmount: limitAmount,
      month: month.month,
      year: month.year,
    );
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((b) => b.id == updated.id);
    if (idx >= 0) {
      final list = [...current];
      list[idx] = updated;
      state = AsyncValue.data(list);
    } else {
      state = AsyncValue.data([updated, ...current]);
    }
  }

  Future<void> delete(String id) async {
    await ref.read(budgetRepositoryProvider).deleteBudget(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((b) => b.id != id).toList());
  }
}

@riverpod
Future<List<BudgetModel>> budgetsForMonth(
  BudgetsForMonthRef ref,
  DateTime month,
) =>
    ref
        .watch(budgetRepositoryProvider)
        .getBudgets(month: month.month, year: month.year);

/// Derives spent-per-category for a given month from the expense summary.
/// Avoids N+1 API calls (one summary call covers all categories & months).
@riverpod
Future<Map<ExpenseCategory, double>> spentForBudgetMonth(
  SpentForBudgetMonthRef ref,
  DateTime month,
) async {
  final summary = await ref.watch(expenseSummaryProvider.future);
  final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
  final breakdown = summary.byCategoryPerMonth
      .where((b) => b.month == key)
      .firstOrNull;
  if (breakdown == null) return {};
  return Map.fromEntries(
    breakdown.categories.map(
      (c) => MapEntry(ExpenseCategory.fromServer(c.category), c.total),
    ),
  );
}
