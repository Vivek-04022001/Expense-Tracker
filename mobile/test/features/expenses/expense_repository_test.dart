import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/network/dio_client.dart';
import 'package:paisa/core/sync/sync_api.dart';
import 'package:paisa/core/sync/sync_engine.dart';
import 'package:paisa/features/expenses/data/repositories/expense_repository.dart';
import 'package:paisa/features/expenses/data/models/expense_model.dart';

class MockDioClient extends Mock implements DioClient {}

/// No-op sync so local-first writes stay deterministic in unit tests.
class FakeSyncEngine extends SyncEngine {
  FakeSyncEngine(AppDatabase db) : super(db, SyncApi(MockDioClient()));
  @override
  Future<void> sync() async {}
  @override
  Future<void> push() async {}
  @override
  Future<void> pull() async {}
}

ExpensesCompanion _seed({
  String id = 'e1',
  double amount = 342.50,
  String category = 'food_and_drink',
  DateTime? createdAt,
}) =>
    ExpensesCompanion.insert(
      id: id,
      amount: amount,
      category: Value(category),
      createdAt: Value(createdAt ?? DateTime(2026, 5, 18, 10)),
      updatedAt: Value(createdAt ?? DateTime(2026, 5, 18, 10)),
    );

void main() {
  late AppDatabase db;
  late ExpenseRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ExpenseRepository(db, FakeSyncEngine(db));
  });

  tearDown(() => db.close());

  group('getExpenses (local)', () {
    test('returns rows in range, newest first; excludes out-of-range', () async {
      await db.into(db.expenses)
          .insert(_seed(id: 'e1', createdAt: DateTime(2026, 5, 10)));
      await db.into(db.expenses)
          .insert(_seed(id: 'e2', amount: 100, createdAt: DateTime(2026, 5, 20)));
      await db.into(db.expenses)
          .insert(_seed(id: 'e3', amount: 5, createdAt: DateTime(2026, 4, 1)));

      final result = await repo.getExpenses(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31, 23, 59, 59),
      );

      expect(result.map((e) => e.id), ['e2', 'e1']);
    });

    test('filters by category', () async {
      await db.into(db.expenses).insert(_seed(id: 'e1', category: 'food_and_drink'));
      await db.into(db.expenses).insert(_seed(id: 'e2', category: 'shopping'));

      final result = await repo.getExpenses(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31),
        category: 'shopping',
      );
      expect(result.single.id, 'e2');
    });
  });

  group('createExpense (local-first)', () {
    test('writes a pending row, enqueues an outbox op, returns the model',
        () async {
      final result = await repo.createExpense(
        amount: 200,
        description: 'Lunch',
        category: ExpenseCategory.foodAndDrink,
        paymentMethod: ExpensePaymentMethod.upi,
      );

      expect(result.id, isNotEmpty);
      expect(result.amount, 200);

      final rows = await db.select(db.expenses).get();
      expect(rows, hasLength(1));
      expect(rows.single.syncStatus, 'pending');

      final outbox = await db.select(db.outbox).get();
      expect(outbox, hasLength(1));
      expect(outbox.single.entity, 'expense');
      expect(outbox.single.op, 'upsert');
      expect(outbox.single.entityId, result.id);
    });

    test('recomputes the linked account balance', () async {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'a1',
        name: 'Wallet',
        openingBalance: const Value(1000),
        balance: const Value(1000),
      ));

      await repo.createExpense(amount: 200, accountId: 'a1');

      final account = await (db.select(db.accounts)
            ..where((t) => t.id.equals('a1')))
          .getSingle();
      expect(account.balance, 800);
    });
  });

  group('deleteExpense (local-first)', () {
    test('soft-deletes, enqueues a delete op, and restores the balance',
        () async {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'a1',
        name: 'Wallet',
        openingBalance: const Value(1000),
        balance: const Value(800),
      ));
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: 'e1',
        amount: 200,
        accountId: const Value('a1'),
      ));

      await repo.deleteExpense('e1');

      final visible = await repo.getExpenses(
        from: DateTime(2000),
        to: DateTime(2100),
      );
      expect(visible, isEmpty);

      final outbox = await db.select(db.outbox).get();
      expect(outbox.single.op, 'delete');

      final account = await (db.select(db.accounts)
            ..where((t) => t.id.equals('a1')))
          .getSingle();
      expect(account.balance, 1000); // expense reversed
    });
  });

  group('getExpenseSummary (local)', () {
    test('aggregates total, by category, by month', () async {
      await db.into(db.expenses).insert(_seed(id: 'e1', amount: 300,
          category: 'food_and_drink', createdAt: DateTime(2026, 5, 2)));
      await db.into(db.expenses).insert(_seed(id: 'e2', amount: 200,
          category: 'shopping', createdAt: DateTime(2026, 5, 3)));
      await db.into(db.expenses).insert(_seed(id: 'e3', amount: 50,
          category: 'food_and_drink', createdAt: DateTime(2026, 6, 1)));

      final summary = await repo.getExpenseSummary();

      expect(summary.allTimeTotal, 550);
      expect(summary.byMonth.firstWhere((m) => m.month == '2026-05').total, 500);
      expect(
          summary.byCategory
              .firstWhere((c) => c.category == 'food_and_drink')
              .total,
          350);
    });
  });

  group('enum mapping', () {
    test('round-trips', () {
      for (final c in ExpenseCategory.values) {
        expect(ExpenseCategory.fromServer(c.toServer()), c);
      }
      for (final p in ExpensePaymentMethod.values) {
        expect(ExpensePaymentMethod.fromServer(p.toServer()), p);
      }
    });
  });
}
