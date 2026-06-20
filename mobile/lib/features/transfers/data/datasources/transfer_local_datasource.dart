import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../models/transfer_model.dart';

/// Local Drift access for transfers between accounts.
class TransferLocalDataSource {
  TransferLocalDataSource(this._db);

  final AppDatabase _db;

  TransferModel _toModel(TransferRow r) => TransferModel(
        id: r.id,
        amount: r.amount,
        fromAccountId: r.fromAccountId,
        toAccountId: r.toAccountId,
        createdAt: r.createdAt,
        description: r.description,
      );

  Future<List<TransferModel>> getTransfers({DateTime? from, DateTime? to}) async {
    final query = _db.select(_db.transfers)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (from != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(to));
    }
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<void> upsert(TransfersCompanion row) =>
      _db.into(_db.transfers).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<TransfersCompanion> rows) async {
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.transfers, rows));
  }

  Future<void> softDelete(String id, DateTime updatedAt,
      {required String syncStatus}) async {
    await (_db.update(_db.transfers)..where((t) => t.id.equals(id))).write(
      TransfersCompanion(
        deletedAt: Value(updatedAt),
        updatedAt: Value(updatedAt),
        syncStatus: Value(syncStatus),
      ),
    );
  }
}
