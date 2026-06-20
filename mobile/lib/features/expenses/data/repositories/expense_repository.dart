import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/balance/local_balance_service.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/db/tables.dart';
import '../../../../core/sync/outbox_service.dart';
import '../../../../core/sync/sync_engine.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';
import '../models/expense_summary_model.dart';

/// Offline-first expense repository.
///
/// Every operation is local-first: it writes to Drift, enqueues an outbox entry,
/// recomputes the affected account balance, and kicks a background sync. The UI
/// updates instantly and works with no connection.
class ExpenseRepository {
  ExpenseRepository(AppDatabase db, this._sync)
      : _db = db,
        _local = ExpenseLocalDataSource(db),
        _outbox = OutboxService(db),
        _balance = LocalBalanceService(db);

  final AppDatabase _db;
  final ExpenseLocalDataSource _local;
  final OutboxService _outbox;
  final LocalBalanceService _balance;
  final SyncEngine _sync;
  final _uuid = const Uuid();

  Future<List<ExpenseModel>> getExpenses({
    required DateTime from,
    required DateTime to,
    String? category,
  }) {
    return _local.getExpenses(from: from, to: to, category: category);
  }

  Future<ExpenseModel> createExpense({
    required double amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    String? accountId,
    String? categoryId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final cat = (category ?? ExpenseCategory.other).toServer();
    final pm = (paymentMethod ?? ExpensePaymentMethod.other).toServer();

    await _db.transaction(() async {
      await _local.upsert(ExpensesCompanion.insert(
        id: id,
        amount: amount,
        category: Value(cat),
        paymentMethod: Value(pm),
        description: Value(description),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        createdAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ));
      await _outbox.enqueue(
        entity: 'expense',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          'amount': amount,
          if (description != null && description.isNotEmpty)
            'description': description,
          'category': cat,
          'paymentMethod': pm,
          if (accountId != null) 'accountId': accountId,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
      if (accountId != null) await _balance.recompute(accountId);
    });

    _sync.syncQuietly();
    return ExpenseModel(
      id: id,
      amount: amount,
      category: category ?? ExpenseCategory.other,
      paymentMethod: paymentMethod ?? ExpensePaymentMethod.other,
      userId: '',
      createdAt: now,
      description: description,
      accountId: accountId,
    );
  }

  Future<ExpenseModel> updateExpense(
    String id, {
    double? amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
  }) async {
    final now = DateTime.now();
    final existing = await _local.getById(id);

    await _db.transaction(() async {
      await (_db.update(_db.expenses)..where((t) => t.id.equals(id))).write(
        ExpensesCompanion(
          amount: amount == null ? const Value.absent() : Value(amount),
          description:
              description == null ? const Value.absent() : Value(description),
          category: category == null
              ? const Value.absent()
              : Value(category.toServer()),
          paymentMethod: paymentMethod == null
              ? const Value.absent()
              : Value(paymentMethod.toServer()),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );
      await _outbox.enqueue(
        entity: 'expense',
        op: 'upsert',
        entityId: id,
        updatedAt: now,
        payload: {
          if (amount != null) 'amount': amount,
          if (description != null) 'description': description,
          if (category != null) 'category': category.toServer(),
          if (paymentMethod != null) 'paymentMethod': paymentMethod.toServer(),
        },
      );
      if (existing?.accountId != null) {
        await _balance.recompute(existing!.accountId!);
      }
    });

    _sync.syncQuietly();
    return (await _local.getById(id)) ?? existing!;
  }

  Future<void> deleteExpense(String id) async {
    final now = DateTime.now();
    final existing = await _local.getById(id);

    await _db.transaction(() async {
      await _local.softDelete(id, now, syncStatus: SyncStatus.pending);
      await _outbox.enqueue(
        entity: 'expense',
        op: 'delete',
        entityId: id,
        updatedAt: now,
      );
      if (existing?.accountId != null) {
        await _balance.recompute(existing!.accountId!);
      }
    });

    _sync.syncQuietly();
  }

  Future<ExpenseSummaryModel> getExpenseSummary() => _local.getSummary();
}
