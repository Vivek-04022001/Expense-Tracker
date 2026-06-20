import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../models/expense_model.dart';

/// Reads and writes expenses against the local Drift database. The repository
/// layer (Phase 3+) talks to this instead of the network for instant,
/// offline-safe access. Mapping between the persisted row and the domain
/// [ExpenseModel] lives here.
class ExpenseLocalDataSource {
  ExpenseLocalDataSource(this._db);

  final AppDatabase _db;

  ExpenseModel _toModel(ExpenseRow r) => ExpenseModel(
        id: r.id,
        amount: r.amount,
        category: ExpenseCategory.fromServer(r.category),
        paymentMethod: ExpensePaymentMethod.fromServer(r.paymentMethod),
        userId: r.userId ?? '',
        createdAt: r.createdAt,
        description: r.description,
        accountId: r.accountId,
      );

  /// Non-deleted expenses whose createdAt falls in [from, to], newest first.
  Future<List<ExpenseModel>> getExpenses({
    required DateTime from,
    required DateTime to,
    String? category,
  }) async {
    final query = _db.select(_db.expenses)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.createdAt.isBiggerOrEqualValue(from) &
          t.createdAt.isSmallerOrEqualValue(to))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<ExpenseModel?> getById(String id) async {
    final row = await (_db.select(_db.expenses)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// Inserts or updates a single expense row (used by local writes and by the
  /// sync engine when applying pulled changes).
  Future<void> upsert(ExpensesCompanion row) =>
      _db.into(_db.expenses).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<ExpensesCompanion> rows) async {
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.expenses, rows));
  }

  /// Local soft delete — marks the row deleted and stamps [updatedAt].
  Future<void> softDelete(String id, DateTime updatedAt, {required String syncStatus}) async {
    await (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
      ExpensesCompanion(
        deletedAt: Value(updatedAt),
        updatedAt: Value(updatedAt),
        syncStatus: Value(syncStatus),
      ),
    );
  }
}
