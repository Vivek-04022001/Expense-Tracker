import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/network/dio_client.dart';
import 'package:paisa/core/sync/sync_api.dart';
import 'package:paisa/core/sync/sync_engine.dart';
import 'package:paisa/features/budgets/data/repositories/budget_repository.dart';
import 'package:paisa/features/expenses/data/models/expense_model.dart';

class MockDioClient extends Mock implements DioClient {}

class FakeSyncEngine extends SyncEngine {
  FakeSyncEngine(AppDatabase db) : super(db, SyncApi(MockDioClient()));
  @override
  Future<void> sync() async {}
  @override
  Future<void> push() async {}
  @override
  Future<void> pull() async {}
}

ExpensesCompanion _seedExpense({
  required String id,
  required double amount,
  String category = 'food_and_drink',
  DateTime? createdAt,
}) =>
    ExpensesCompanion.insert(
      id: id,
      amount: amount,
      category: Value(category),
      createdAt: Value(createdAt ?? DateTime(2026, 5, 10)),
      updatedAt: Value(createdAt ?? DateTime(2026, 5, 10)),
    );

void main() {
  late AppDatabase db;
  late BudgetRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BudgetRepository(db, FakeSyncEngine(db));
  });

  tearDown(() => db.close());

  group('upsertBudget (local-first)', () {
    test('creates a budget with a deterministic id and enqueues an op',
        () async {
      final result = await repo.upsertBudget(
        category: ExpenseCategory.foodAndDrink,
        limitAmount: 5000,
        month: 5,
        year: 2026,
      );

      expect(result.id, 'bgt-2026-5-food_and_drink');
      final rows = await db.select(db.budgets).get();
      expect(rows.single.syncStatus, 'pending');

      final outbox = await db.select(db.outbox).get();
      expect(outbox.single.entity, 'budget');
      expect(outbox.single.op, 'upsert');
    });

    test('re-upserting the same slot updates the existing row (no duplicate)',
        () async {
      await repo.upsertBudget(
        category: ExpenseCategory.foodAndDrink,
        limitAmount: 5000,
        month: 5,
        year: 2026,
      );
      await repo.upsertBudget(
        category: ExpenseCategory.foodAndDrink,
        limitAmount: 8000,
        month: 5,
        year: 2026,
      );

      final budgets = await repo.getBudgets(month: 5, year: 2026);
      expect(budgets, hasLength(1));
      expect(budgets.single.limitAmount, 8000);
    });
  });

  group('getBudgets (local)', () {
    test('returns budgets for the requested month/year', () async {
      await repo.upsertBudget(
          category: ExpenseCategory.foodAndDrink,
          limitAmount: 5000,
          month: 5,
          year: 2026);
      await repo.upsertBudget(
          category: ExpenseCategory.transport,
          limitAmount: 2000,
          month: 5,
          year: 2026);
      await repo.upsertBudget(
          category: ExpenseCategory.shopping,
          limitAmount: 1000,
          month: 4,
          year: 2026);

      final result = await repo.getBudgets(month: 5, year: 2026);
      expect(result, hasLength(2));
    });
  });

  group('getBudgetStatus (local)', () {
    test('computes spent/remaining from local expenses', () async {
      await repo.upsertBudget(
          category: ExpenseCategory.foodAndDrink,
          limitAmount: 5000,
          month: 5,
          year: 2026);
      await db.into(db.expenses).insert(_seedExpense(id: 'e1', amount: 800));
      await db.into(db.expenses).insert(_seedExpense(id: 'e2', amount: 400));
      await db.into(db.expenses)
          .insert(_seedExpense(id: 'e3', amount: 999, category: 'shopping'));

      final status = await repo.getBudgetStatus('bgt-2026-5-food_and_drink');
      expect(status.spent, 1200);
      expect(status.remaining, 3800);
      expect(status.isOverBudget, isFalse);
    });

    test('flags over-budget', () async {
      await repo.upsertBudget(
          category: ExpenseCategory.foodAndDrink,
          limitAmount: 1000,
          month: 5,
          year: 2026);
      await db.into(db.expenses).insert(_seedExpense(id: 'e1', amount: 1500));

      final status = await repo.getBudgetStatus('bgt-2026-5-food_and_drink');
      expect(status.isOverBudget, isTrue);
      expect(status.remaining, -500);
    });
  });

  group('deleteBudget (local-first)', () {
    test('soft-deletes and enqueues a delete op', () async {
      await repo.upsertBudget(
          category: ExpenseCategory.foodAndDrink,
          limitAmount: 5000,
          month: 5,
          year: 2026);

      await repo.deleteBudget('bgt-2026-5-food_and_drink');

      final budgets = await repo.getBudgets(month: 5, year: 2026);
      expect(budgets, isEmpty);
      final ops = await db.select(db.outbox).get();
      expect(ops.last.op, 'delete');
    });
  });
}
