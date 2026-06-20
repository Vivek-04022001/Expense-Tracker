import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/tables.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'outbox_service.dart';
import 'sync_api.dart';

/// Coordinates reconciliation between the local Drift database and the server.
///
/// A sync cycle [push]es queued local mutations (the outbox) and then [pull]s
/// the server delta into Drift. A mutex prevents overlapping runs.
class SyncEngine {
  SyncEngine(this._db, this._api) : _outbox = OutboxService(_db);

  final AppDatabase _db;
  final SyncApi _api;
  final OutboxService _outbox;

  Future<void>? _inFlight;

  /// Runs a full sync cycle (push then pull). Concurrent callers share the same
  /// in-flight future instead of launching parallel syncs.
  Future<void> sync() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    await push();
    await pull();
  }

  /// Drains the outbox: sends queued mutations to the server in dependency
  /// order, then clears applied entries (and marks their rows synced) or records
  /// a failure for retry. `skipped-stale` is treated as applied — the following
  /// pull will overwrite the local row with the server's winning version.
  Future<void> push() async {
    final pending = await _outbox.pending();
    if (pending.isEmpty) return;

    final operations = pending
        .map((r) => {
              'entity': r.entity,
              'op': r.op,
              'id': r.entityId,
              'data': jsonDecode(r.payload) as Map<String, dynamic>,
              'updatedAt': r.updatedAt.toUtc().toIso8601String(),
            })
        .toList();

    final body = await _api.push(operations);
    final results = ((body['results'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    for (var i = 0; i < pending.length; i++) {
      final row = pending[i];
      final status = i < results.length ? results[i]['status'] as String? : null;
      if (status == 'applied' || status == 'skipped-stale') {
        await _markSynced(row.entity, row.entityId);
        await _outbox.remove(row.localId);
      } else {
        await _outbox.recordFailure(row.localId, status ?? 'unknown');
      }
    }
  }

  /// Marks a successfully-pushed local row as synced.
  Future<void> _markSynced(String entity, String id) async {
    switch (entity) {
      case 'account':
        await (_db.update(_db.accounts)..where((t) => t.id.equals(id)))
            .write(const AccountsCompanion(syncStatus: Value(SyncStatus.synced)));
      case 'category':
        await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
            const CategoriesCompanion(syncStatus: Value(SyncStatus.synced)));
      case 'expense':
        await (_db.update(_db.expenses)..where((t) => t.id.equals(id)))
            .write(const ExpensesCompanion(syncStatus: Value(SyncStatus.synced)));
      case 'income':
        await (_db.update(_db.incomes)..where((t) => t.id.equals(id)))
            .write(const IncomesCompanion(syncStatus: Value(SyncStatus.synced)));
      case 'transfer':
        await (_db.update(_db.transfers)..where((t) => t.id.equals(id))).write(
            const TransfersCompanion(syncStatus: Value(SyncStatus.synced)));
      case 'budget':
        await (_db.update(_db.budgets)..where((t) => t.id.equals(id)))
            .write(const BudgetsCompanion(syncStatus: Value(SyncStatus.synced)));
    }
  }

  /// Downloads everything changed since the stored cursor and applies it to the
  /// local database, then advances the cursor to the server's clock.
  Future<void> pull() async {
    final since = await _db.getLastPulledAt();
    final body = await _api.pull(since);

    final serverTime = DateTime.parse(body['serverTime'] as String);
    final changes = (body['changes'] as Map).cast<String, dynamic>();

    List<Map<String, dynamic>> rows(String key) =>
        ((changes[key] as List?) ?? const [])
            .cast<Map<String, dynamic>>();

    await _db.transaction(() async {
      await _ingestAccounts(rows('accounts'));
      await _ingestCategories(rows('categories'));
      await _ingestExpenses(rows('expenses'));
      await _ingestIncomes(rows('income'));
      await _ingestTransfers(rows('transfers'));
      await _ingestBudgets(rows('budgets'));
    });

    await _db.setLastPulledAt(serverTime);
  }

  // --- ingestion helpers: server JSON row -> Drift companion -------------------

  Future<void> _ingestAccounts(List<Map<String, dynamic>> list) async {
    if (list.isEmpty) return;
    final companions = list.map((j) => AccountsCompanion.insert(
          id: j['id'] as String,
          userId: Value(j['userId'] as String?),
          name: j['name'] as String,
          type: Value(j['type'] as String? ?? 'other'),
          openingBalance: Value(_num(j['openingBalance'])),
          balance: Value(_num(j['balance'])),
          color: Value(j['color'] as String?),
          createdAt: Value(_date(j['createdAt'])!),
          updatedAt: Value(_date(j['updatedAt'])!),
          deletedAt: Value(_date(j['deletedAt'])),
          syncStatus: const Value(SyncStatus.synced),
        ));
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.accounts, companions.toList()));
  }

  Future<void> _ingestCategories(List<Map<String, dynamic>> list) async {
    if (list.isEmpty) return;
    final companions = list.map((j) => CategoriesCompanion.insert(
          id: j['id'] as String,
          userId: Value(j['userId'] as String?),
          name: j['name'] as String,
          kind: j['kind'] as String,
          icon: j['icon'] as String,
          color: j['color'] as String,
          key: Value(j['key'] as String?),
          isSystem: Value(j['isSystem'] as bool? ?? false),
          sortOrder: Value(j['sortOrder'] as int? ?? 0),
          createdAt: Value(_date(j['createdAt'])!),
          updatedAt: Value(_date(j['updatedAt'])!),
          deletedAt: Value(_date(j['deletedAt'])),
          syncStatus: const Value(SyncStatus.synced),
        ));
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.categories, companions.toList()));
  }

  Future<void> _ingestExpenses(List<Map<String, dynamic>> list) async {
    if (list.isEmpty) return;
    final companions = list.map((j) => ExpensesCompanion.insert(
          id: j['id'] as String,
          userId: Value(j['userId'] as String?),
          amount: _num(j['amount']),
          category: Value(j['category'] as String? ?? 'other'),
          paymentMethod: Value(j['paymentMethod'] as String? ?? 'other'),
          description: Value(j['description'] as String?),
          accountId: Value(j['accountId'] as String?),
          categoryId: Value(j['categoryId'] as String?),
          createdAt: Value(_date(j['createdAt'])!),
          updatedAt: Value(_date(j['updatedAt'])!),
          deletedAt: Value(_date(j['deletedAt'])),
          syncStatus: const Value(SyncStatus.synced),
        ));
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.expenses, companions.toList()));
  }

  Future<void> _ingestIncomes(List<Map<String, dynamic>> list) async {
    if (list.isEmpty) return;
    final companions = list.map((j) => IncomesCompanion.insert(
          id: j['id'] as String,
          userId: Value(j['userId'] as String?),
          amount: _num(j['amount']),
          incomeType: Value(j['incomeType'] as String? ?? 'other'),
          description: Value(j['description'] as String?),
          accountId: Value(j['accountId'] as String?),
          categoryId: Value(j['categoryId'] as String?),
          createdAt: Value(_date(j['createdAt'])!),
          updatedAt: Value(_date(j['updatedAt'])!),
          deletedAt: Value(_date(j['deletedAt'])),
          syncStatus: const Value(SyncStatus.synced),
        ));
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.incomes, companions.toList()));
  }

  Future<void> _ingestTransfers(List<Map<String, dynamic>> list) async {
    if (list.isEmpty) return;
    final companions = list.map((j) => TransfersCompanion.insert(
          id: j['id'] as String,
          userId: Value(j['userId'] as String?),
          amount: _num(j['amount']),
          fromAccountId: j['fromAccountId'] as String,
          toAccountId: j['toAccountId'] as String,
          description: Value(j['description'] as String?),
          createdAt: Value(_date(j['createdAt'])!),
          updatedAt: Value(_date(j['updatedAt'])!),
          deletedAt: Value(_date(j['deletedAt'])),
          syncStatus: const Value(SyncStatus.synced),
        ));
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.transfers, companions.toList()));
  }

  Future<void> _ingestBudgets(List<Map<String, dynamic>> list) async {
    if (list.isEmpty) return;
    for (final j in list) {
      final id = j['id'] as String;
      final category = j['category'] as String;
      final month = j['month'] as int;
      final year = j['year'] as int;

      // The server enforces one budget per (category, month, year). Drop any
      // local row that occupies the same slot under a different id (e.g. a
      // client-generated id that the server reconciled to its own).
      await (_db.delete(_db.budgets)
            ..where((t) =>
                t.category.equals(category) &
                t.month.equals(month) &
                t.year.equals(year) &
                t.id.equals(id).not()))
          .go();

      await _db.into(_db.budgets).insertOnConflictUpdate(
            BudgetsCompanion.insert(
              id: id,
              userId: Value(j['userId'] as String?),
              limitAmount: _num(j['limitAmount']),
              category: category,
              categoryId: Value(j['categoryId'] as String?),
              month: month,
              year: year,
              createdAt: Value(_date(j['createdAt'])!),
              updatedAt: Value(_date(j['updatedAt'])!),
              deletedAt: Value(_date(j['deletedAt'])),
              syncStatus: const Value(SyncStatus.synced),
            ),
          );
    }
  }

  static double _num(dynamic v) => double.parse((v ?? 0).toString());
  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.parse(v as String);
}

/// Best-effort fire-and-forget sync that swallows errors (e.g. offline). Used
/// by triggers that should never surface a failure to the UI.
extension SyncEngineSafe on SyncEngine {
  Future<void> syncQuietly() async {
    try {
      await sync();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Sync skipped/failed: $e');
      }
    }
  }

  /// Pull-only variant used after a successful network write to refresh local
  /// state (rows + recomputed balances) without surfacing transient errors.
  Future<void> pullQuietly() async {
    try {
      await pull();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Pull skipped/failed: $e');
      }
    }
  }
}

final syncApiProvider = Provider<SyncApi>(
  (ref) => SyncApi(ref.watch(dioClientProvider)),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    ref.watch(appDatabaseProvider),
    ref.watch(syncApiProvider),
  ),
);
