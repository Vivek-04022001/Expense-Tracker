import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables.dart';
import '../../../../core/sync/outbox_service.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/account_local_datasource.dart';
import '../models/account_model.dart';

class AccountsResult {
  const AccountsResult({required this.accounts, required this.totalBalance});

  final List<AccountModel> accounts;
  final double totalBalance;
}

/// Offline-first account repository. The entered balance is stored as
/// `openingBalance`; `balance` is derived. Local-first writes via outbox.
class AccountRepository {
  AccountRepository(AppDatabase db, this._sync)
      : _db = db,
        _local = AccountLocalDataSource(db),
        _outbox = OutboxService(db);

  final AppDatabase _db;
  final AccountLocalDataSource _local;
  final OutboxService _outbox;
  final SyncEngine _sync;
  final _uuid = const Uuid();

  Future<AccountsResult> getAccounts() async {
    final accounts = await _local.getAccounts();
    final total = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    return AccountsResult(accounts: accounts, totalBalance: total);
  }

  Future<AccountModel> createAccount({
    required String name,
    required AccountType type,
    required double balance,
    String? color,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _local.upsert(AccountsCompanion.insert(
        id: id,
        name: name,
        type: Value(type.toServer()),
        openingBalance: Value(balance),
        balance: Value(balance),
        color: Value(color),
        createdAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await _outbox.enqueue(
        entity: 'account',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          'name': name,
          'type': type.toServer(),
          'openingBalance': balance,
          if (color != null) 'color': color,
        },
      );
    });

    _sync.syncQuietly();
    return AccountModel(id: id, name: name, type: type, balance: balance, color: color);
  }

  Future<AccountModel> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required double balance,
    String? color,
  }) async {
    final now = DateTime.now();
    final row = await (_db.select(_db.accounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    // Shift openingBalance so the recomputed balance lands on the entered value
    // while preserving existing activity.
    final activity =
        row == null ? 0.0 : row.balance - row.openingBalance;
    final newOpening = balance - activity;

    await _db.transaction(() async {
      await (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
        AccountsCompanion(
          name: Value(name),
          type: Value(type.toServer()),
          color: Value(color),
          openingBalance: Value(newOpening),
          balance: Value(balance),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
      await _outbox.enqueue(
        entity: 'account',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          'name': name,
          'type': type.toServer(),
          'openingBalance': newOpening,
          if (color != null) 'color': color,
        },
      );
    });

    _sync.syncQuietly();
    return AccountModel(id: id, name: name, type: type, balance: balance, color: color);
  }

  Future<void> deleteAccount(String id) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await _local.softDelete(id, now, syncStatus: SyncStatus.pending);
      await _outbox.enqueue(
        entity: 'account',
        op: 'delete',
        entityId: id,
        updatedAt: now,
      );
    });
    _sync.syncQuietly();
  }
}
