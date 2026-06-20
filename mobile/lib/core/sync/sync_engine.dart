import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/tables.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'sync_api.dart';

/// Coordinates reconciliation between the local Drift database and the server.
///
/// Phase 3 implements [pull] (delta download → upsert into Drift). [push] is
/// wired in Phase 4 once the outbox drives local-first writes; for now [sync]
/// simply pulls. A mutex prevents overlapping runs.
class SyncEngine {
  SyncEngine(this._db, this._api);

  final AppDatabase _db;
  final SyncApi _api;

  Future<void>? _inFlight;

  /// Runs a sync cycle (currently pull-only). Concurrent callers share the same
  /// in-flight future instead of launching parallel syncs.
  Future<void> sync() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    // Phase 4 will flush the outbox here (push) before pulling.
    await pull();
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
    final companions = list.map((j) => BudgetsCompanion.insert(
          id: j['id'] as String,
          userId: Value(j['userId'] as String?),
          limitAmount: _num(j['limitAmount']),
          category: j['category'] as String,
          categoryId: Value(j['categoryId'] as String?),
          month: j['month'] as int,
          year: j['year'] as int,
          createdAt: Value(_date(j['createdAt'])!),
          updatedAt: Value(_date(j['updatedAt'])!),
          deletedAt: Value(_date(j['deletedAt'])),
          syncStatus: const Value(SyncStatus.synced),
        ));
    await _db.batch((b) => b.insertAllOnConflictUpdate(_db.budgets, companions.toList()));
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
