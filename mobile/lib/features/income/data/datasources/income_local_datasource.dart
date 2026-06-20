import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../models/income_model.dart';

/// Local Drift access for income, mirroring the income repository's read shape.
class IncomeLocalDataSource {
  IncomeLocalDataSource(this._db);

  final AppDatabase _db;

  IncomeModel _toModel(IncomeRow r) => IncomeModel(
        id: r.id,
        amount: r.amount,
        incomeType: IncomeType.fromServer(r.incomeType),
        userId: r.userId ?? '',
        createdAt: r.createdAt,
        description: r.description,
        accountId: r.accountId,
      );

  Future<List<IncomeModel>> getIncomes({
    DateTime? from,
    DateTime? to,
    String? incomeType,
  }) async {
    final query = _db.select(_db.incomes)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (from != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(to));
    }
    if (incomeType != null) {
      query.where((t) => t.incomeType.equals(incomeType));
    }
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<void> upsert(IncomesCompanion row) =>
      _db.into(_db.incomes).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<IncomesCompanion> rows) async {
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.incomes, rows));
  }

  Future<void> softDelete(String id, DateTime updatedAt,
      {required String syncStatus}) async {
    await (_db.update(_db.incomes)..where((t) => t.id.equals(id))).write(
      IncomesCompanion(
        deletedAt: Value(updatedAt),
        updatedAt: Value(updatedAt),
        syncStatus: Value(syncStatus),
      ),
    );
  }
}
