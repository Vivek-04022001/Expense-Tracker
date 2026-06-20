import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/network/dio_client.dart';
import 'package:paisa/core/sync/sync_api.dart';
import 'package:paisa/core/sync/sync_engine.dart';
import 'package:paisa/features/income/data/repositories/income_repository.dart';
import 'package:paisa/features/income/data/models/income_model.dart';

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

IncomesCompanion _seed({
  String id = 'i1',
  double amount = 50000.0,
  String incomeType = 'salary',
  DateTime? createdAt,
}) =>
    IncomesCompanion.insert(
      id: id,
      amount: amount,
      incomeType: Value(incomeType),
      createdAt: Value(createdAt ?? DateTime(2026, 5, 18, 10)),
      updatedAt: Value(createdAt ?? DateTime(2026, 5, 18, 10)),
    );

void main() {
  late AppDatabase db;
  late IncomeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = IncomeRepository(db, FakeSyncEngine(db));
  });

  tearDown(() => db.close());

  group('getIncomes (local)', () {
    test('returns rows in range, newest first', () async {
      await db.into(db.incomes)
          .insert(_seed(id: 'i1', createdAt: DateTime(2026, 5, 10)));
      await db.into(db.incomes)
          .insert(_seed(id: 'i2', amount: 10000, createdAt: DateTime(2026, 5, 20)));
      await db.into(db.incomes)
          .insert(_seed(id: 'i3', amount: 5, createdAt: DateTime(2026, 4, 1)));

      final result = await repo.getIncomes(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31, 23, 59, 59),
      );
      expect(result.map((e) => e.id), ['i2', 'i1']);
    });

    test('filters by incomeType', () async {
      await db.into(db.incomes).insert(_seed(id: 'i1', incomeType: 'salary'));
      await db.into(db.incomes).insert(_seed(id: 'i2', incomeType: 'freelance'));

      final result = await repo.getIncomes(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31),
        incomeType: IncomeType.freelance,
      );
      expect(result.single.id, 'i2');
    });
  });

  group('createIncome (local-first)', () {
    test('writes a pending row and enqueues an outbox op', () async {
      final result = await repo.createIncome(
        amount: 50000,
        incomeType: IncomeType.salary,
        description: 'May salary',
      );

      expect(result.id, isNotEmpty);
      final rows = await db.select(db.incomes).get();
      expect(rows.single.syncStatus, 'pending');

      final outbox = await db.select(db.outbox).get();
      expect(outbox.single.entity, 'income');
      expect(outbox.single.op, 'upsert');
    });

    test('recomputes the linked account balance (income adds)', () async {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
        id: 'a1',
        name: 'Bank',
        openingBalance: const Value(1000),
        balance: const Value(1000),
      ));

      await repo.createIncome(amount: 500, accountId: 'a1');

      final account = await (db.select(db.accounts)
            ..where((t) => t.id.equals('a1')))
          .getSingle();
      expect(account.balance, 1500);
    });
  });

  group('deleteIncome (local-first)', () {
    test('soft-deletes and enqueues a delete op', () async {
      await db.into(db.incomes).insert(_seed(id: 'i1'));

      await repo.deleteIncome('i1');

      final visible = await repo.getIncomes(
        from: DateTime(2000),
        to: DateTime(2100),
      );
      expect(visible, isEmpty);
      final outbox = await db.select(db.outbox).get();
      expect(outbox.single.op, 'delete');
    });
  });

  group('enum mapping', () {
    test('round-trips', () {
      for (final t in IncomeType.values) {
        expect(IncomeType.fromServer(t.toServer()), t);
      }
    });
  });
}
