import 'package:drift/drift.dart';

import '../../../../core/db/app_database.dart';
import '../models/account_model.dart';

/// Local Drift access for accounts. `balance` is read straight from the row
/// (kept current by the sync engine / local balance recompute).
class AccountLocalDataSource {
  AccountLocalDataSource(this._db);

  final AppDatabase _db;

  AccountModel _toModel(AccountRow r) => AccountModel(
        id: r.id,
        name: r.name,
        type: AccountType.fromServer(r.type),
        balance: r.balance,
        color: r.color,
      );

  Future<List<AccountModel>> getAccounts() async {
    final rows = await (_db.select(_db.accounts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  Future<AccountModel?> getById(String id) async {
    final row = await (_db.select(_db.accounts)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<void> upsert(AccountsCompanion row) =>
      _db.into(_db.accounts).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<AccountsCompanion> rows) async {
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.accounts, rows));
  }

  Future<void> softDelete(String id, DateTime updatedAt,
      {required String syncStatus}) async {
    await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(
        deletedAt: Value(updatedAt),
        updatedAt: Value(updatedAt),
        syncStatus: Value(syncStatus),
      ),
    );
  }
}
