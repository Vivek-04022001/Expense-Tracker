import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/balance/local_balance_service.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables.dart';
import '../../../../core/sync/outbox_service.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/income_local_datasource.dart';
import '../models/income_model.dart';

/// Offline-first income repository. Local-first writes via Drift + outbox, with
/// background sync and local balance recompute.
class IncomeRepository {
  IncomeRepository(AppDatabase db, this._sync)
      : _db = db,
        _local = IncomeLocalDataSource(db),
        _outbox = OutboxService(db),
        _balance = LocalBalanceService(db);

  final AppDatabase _db;
  final IncomeLocalDataSource _local;
  final OutboxService _outbox;
  final LocalBalanceService _balance;
  final SyncEngine _sync;
  final _uuid = const Uuid();

  Future<List<IncomeModel>> getIncomes({
    required DateTime from,
    required DateTime to,
    IncomeType? incomeType,
  }) {
    return _local.getIncomes(
      from: from,
      to: to,
      incomeType: incomeType?.toServer(),
    );
  }

  Future<String?> _accountIdOf(String id) async {
    final row = await (_db.select(_db.incomes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.accountId;
  }

  Future<IncomeModel> createIncome({
    required double amount,
    IncomeType? incomeType,
    String? description,
    String? accountId,
    String? categoryId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final type = (incomeType ?? IncomeType.other).toServer();

    await _db.transaction(() async {
      await _local.upsert(IncomesCompanion.insert(
        id: id,
        amount: amount,
        incomeType: Value(type),
        description: Value(description),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        createdAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await _outbox.enqueue(
        entity: 'income',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          'amount': amount,
          'incomeType': type,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (accountId != null) 'accountId': accountId,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
      if (accountId != null) await _balance.recompute(accountId);
    });

    _sync.syncQuietly();
    return IncomeModel(
      id: id,
      amount: amount,
      incomeType: incomeType ?? IncomeType.other,
      userId: '',
      createdAt: now,
      description: description,
      accountId: accountId,
    );
  }

  Future<IncomeModel> updateIncome(
    String id, {
    double? amount,
    IncomeType? incomeType,
    String? description,
  }) async {
    final now = DateTime.now();
    final accountId = await _accountIdOf(id);

    await _db.transaction(() async {
      await (_db.update(_db.incomes)..where((t) => t.id.equals(id))).write(
        IncomesCompanion(
          amount: amount == null ? const Value.absent() : Value(amount),
          incomeType: incomeType == null
              ? const Value.absent()
              : Value(incomeType.toServer()),
          description:
              description == null ? const Value.absent() : Value(description),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
      await _outbox.enqueue(
        entity: 'income',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          if (amount != null) 'amount': amount,
          if (incomeType != null) 'incomeType': incomeType.toServer(),
          if (description != null) 'description': description,
        },
      );
      if (accountId != null) await _balance.recompute(accountId);
    });

    _sync.syncQuietly();
    final rows = await _local.getIncomes(
      from: DateTime(2000),
      to: DateTime(2100),
    );
    return rows.firstWhere((e) => e.id == id);
  }

  Future<void> deleteIncome(String id) async {
    final now = DateTime.now();
    final accountId = await _accountIdOf(id);

    await _db.transaction(() async {
      await _local.softDelete(id, now, syncStatus: SyncStatus.pending);
      await _outbox.enqueue(
        entity: 'income',
        op: 'delete',
        entityId: id,
        updatedAt: now,
      );
      if (accountId != null) await _balance.recompute(accountId);
    });

    _sync.syncQuietly();
  }
}
