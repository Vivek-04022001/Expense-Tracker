import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/balance/local_balance_service.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables.dart';
import '../../../../core/sync/outbox_service.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/transfer_local_datasource.dart';
import '../models/transfer_model.dart';

/// Offline-first transfer repository. Local-first writes via outbox; both
/// affected account balances are recomputed locally.
class TransferRepository {
  TransferRepository(AppDatabase db, this._sync)
      : _db = db,
        _local = TransferLocalDataSource(db),
        _outbox = OutboxService(db),
        _balance = LocalBalanceService(db);

  final AppDatabase _db;
  final TransferLocalDataSource _local;
  final OutboxService _outbox;
  final LocalBalanceService _balance;
  final SyncEngine _sync;
  final _uuid = const Uuid();

  Future<List<TransferModel>> getTransfers() => _local.getTransfers();

  Future<TransferModel> createTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    String? description,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _local.upsert(TransfersCompanion.insert(
        id: id,
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        description: Value(description),
        createdAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await _outbox.enqueue(
        entity: 'transfer',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          'amount': amount,
          'fromAccountId': fromAccountId,
          'toAccountId': toAccountId,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      await _balance.recomputeAll([fromAccountId, toAccountId]);
    });

    _sync.syncQuietly();
    return TransferModel(
      id: id,
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      createdAt: now,
      description: description,
    );
  }

  Future<void> deleteTransfer(String id) async {
    final now = DateTime.now();
    final row = await (_db.select(_db.transfers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    await _db.transaction(() async {
      await _local.softDelete(id, now, syncStatus: SyncStatus.pending);
      await _outbox.enqueue(
        entity: 'transfer',
        op: 'delete',
        entityId: id,
        updatedAt: now,
      );
      if (row != null) {
        await _balance.recomputeAll([row.fromAccountId, row.toAccountId]);
      }
    });

    _sync.syncQuietly();
  }
}
