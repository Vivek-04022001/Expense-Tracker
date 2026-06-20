import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../models/budget_model.dart';

/// Local Drift access for budgets.
class BudgetLocalDataSource {
  BudgetLocalDataSource(this._db);

  final AppDatabase _db;

  BudgetModel _toModel(BudgetRow r) => BudgetModel(
        id: r.id,
        category: ExpenseCategory.fromServer(r.category),
        limitAmount: r.limitAmount,
        month: r.month,
        year: r.year,
      );

  Future<List<BudgetModel>> getBudgets({int? month, int? year}) async {
    final query = _db.select(_db.budgets)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.category)]);
    if (month != null) {
      query.where((t) => t.month.equals(month));
    }
    if (year != null) {
      query.where((t) => t.year.equals(year));
    }
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  /// Computes a budget's progress locally: sums non-deleted expenses in the
  /// budget's category for its month/year window. Mirrors `/budgets/:id/status`.
  Future<BudgetStatusModel?> getBudgetStatus(String id) async {
    final budgetRow = await (_db.select(_db.budgets)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (budgetRow == null) return null;

    final start = DateTime(budgetRow.year, budgetRow.month);
    final end = DateTime(budgetRow.year, budgetRow.month + 1);

    final expenses = await (_db.select(_db.expenses)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.category.equals(budgetRow.category) &
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end)))
        .get();

    final spent = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final limit = budgetRow.limitAmount;
    final remaining = limit - spent;
    final percentUsed = limit == 0 ? 0.0 : (spent / limit * 100);

    return BudgetStatusModel(
      budget: _toModel(budgetRow),
      spent: spent,
      remaining: remaining,
      percentUsed: double.parse(percentUsed.toStringAsFixed(1)),
      isOverBudget: spent > limit,
    );
  }

  Future<void> upsert(BudgetsCompanion row) =>
      _db.into(_db.budgets).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<BudgetsCompanion> rows) async {
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.budgets, rows));
  }

  Future<void> softDelete(String id, DateTime updatedAt,
      {required String syncStatus}) async {
    await (_db.update(_db.budgets)..where((t) => t.id.equals(id))).write(
      BudgetsCompanion(
        deletedAt: Value(updatedAt),
        updatedAt: Value(updatedAt),
        syncStatus: Value(syncStatus),
      ),
    );
  }
}
