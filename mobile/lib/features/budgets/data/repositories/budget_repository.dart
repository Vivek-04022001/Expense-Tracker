import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables.dart';
import '../../../../core/sync/outbox_service.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../datasources/budget_local_datasource.dart';
import '../models/budget_model.dart';

/// Offline-first budget repository. Local-first writes via outbox. Budgets are
/// keyed by (category, month, year); an existing local row for a slot is reused
/// so there's at most one budget per slot, matching the server's unique key.
class BudgetRepository {
  BudgetRepository(AppDatabase db, this._sync)
      : _db = db,
        _local = BudgetLocalDataSource(db),
        _outbox = OutboxService(db);

  final AppDatabase _db;
  final BudgetLocalDataSource _local;
  final OutboxService _outbox;
  final SyncEngine _sync;

  Future<List<BudgetModel>> getBudgets({
    required int month,
    required int year,
  }) {
    return _local.getBudgets(month: month, year: year);
  }

  Future<BudgetModel> upsertBudget({
    required ExpenseCategory category,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    final now = DateTime.now();
    final cat = category.toServer();

    // Reuse the existing row for this slot (it may carry a server-assigned id);
    // otherwise mint a deterministic id so two devices agree on new slots.
    final existing = await (_db.select(_db.budgets)
          ..where((t) =>
              t.category.equals(cat) &
              t.month.equals(month) &
              t.year.equals(year)))
        .getSingleOrNull();
    final id = existing?.id ?? 'bgt-$year-$month-$cat';

    await _db.transaction(() async {
      await _local.upsert(BudgetsCompanion.insert(
        id: id,
        limitAmount: limitAmount,
        category: cat,
        month: month,
        year: year,
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        deletedAt: const Value(null),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await _outbox.enqueue(
        entity: 'budget',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          'limitAmount': limitAmount,
          'category': cat,
          'month': month,
          'year': year,
        },
      );
    });

    _sync.syncQuietly();
    return BudgetModel(
      id: id,
      category: category,
      limitAmount: limitAmount,
      month: month,
      year: year,
    );
  }

  Future<void> deleteBudget(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await _local.softDelete(id, now, syncStatus: SyncStatus.pending);
      await _outbox.enqueue(
        entity: 'budget',
        op: 'delete',
        entityId: id,
        updatedAt: now,
      );
    });
    _sync.syncQuietly();
  }

  Future<BudgetStatusModel> getBudgetStatus(String id) async {
    final status = await _local.getBudgetStatus(id);
    if (status == null) {
      throw StateError('Budget not found: $id');
    }
    return status;
  }
}
