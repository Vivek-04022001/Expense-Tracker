import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/db/tables.dart';
import 'package:paisa/features/expenses/data/datasources/expense_local_datasource.dart';

void main() {
  late AppDatabase db;
  late ExpenseLocalDataSource expenses;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    expenses = ExpenseLocalDataSource(db);
  });

  tearDown(() => db.close());

  test('insert, query by date range, and soft delete an expense', () async {
    final now = DateTime(2026, 6, 21, 12);
    await expenses.upsert(
      ExpensesCompanion.insert(
        id: 'exp-1',
        amount: 50,
        category: const Value('food_and_drink'),
        createdAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );

    final inRange = await expenses.getExpenses(
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 30),
    );
    expect(inRange, hasLength(1));
    expect(inRange.single.id, 'exp-1');
    expect(inRange.single.amount, 50);

    // Outside the window → excluded.
    final outOfRange = await expenses.getExpenses(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 7, 31),
    );
    expect(outOfRange, isEmpty);

    // Soft delete hides it from reads.
    await expenses.softDelete('exp-1', now, syncStatus: SyncStatus.pending);
    final afterDelete = await expenses.getExpenses(
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 30),
    );
    expect(afterDelete, isEmpty);
  });

  test('lastPulledAt round-trips and wipe clears it', () async {
    expect(await db.getLastPulledAt(), isNull);

    final ts = DateTime(2026, 6, 20, 9, 30);
    await db.setLastPulledAt(ts);
    expect(await db.getLastPulledAt(), ts);

    await db.wipe();
    expect(await db.getLastPulledAt(), isNull);
  });
}
