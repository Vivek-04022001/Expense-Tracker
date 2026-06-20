import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/constants/api_constants.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/errors/app_exceptions.dart';
import 'package:paisa/core/network/dio_client.dart';
import 'package:paisa/core/sync/sync_api.dart';
import 'package:paisa/core/sync/sync_engine.dart';
import 'package:paisa/features/expenses/data/models/expense_model.dart';
import 'package:paisa/features/expenses/data/repositories/expense_repository.dart';

class MockDioClient extends Mock implements DioClient {}

Response<dynamic> _response(Map<String, dynamic> data, {int statusCode = 200}) =>
    Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

Map<String, dynamic> _expenseJson({
  String id = 'e1',
  String amount = '342.50',
  String category = 'food_and_drink',
  String paymentMethod = 'upi',
  String? description = 'Swiggy',
}) => {
      'id': id,
      'amount': amount,
      'category': category,
      'paymentMethod': paymentMethod,
      'description': description,
      'userId': 'u1',
      'createdAt': '2026-05-18T10:00:00.000Z',
      'updatedAt': '2026-05-18T10:00:00.000Z',
      'deletedAt': null,
    };

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
      paymentMethod: const Value('upi'),
      createdAt: Value(createdAt ?? DateTime(2026, 5, 18, 10)),
      updatedAt: Value(createdAt ?? DateTime(2026, 5, 18, 10)),
    );

void main() {
  late MockDioClient mockDio;
  late AppDatabase db;
  late ExpenseRepository repo;

  setUp(() {
    mockDio = MockDioClient();
    db = AppDatabase(NativeDatabase.memory());
    repo = ExpenseRepository(mockDio, db, SyncEngine(db, SyncApi(mockDio)));

    // The post-write pull hits /sync/pull; return an empty delta.
    when(() => mockDio.get('/sync/pull',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _response({
              'serverTime': DateTime.now().toUtc().toIso8601String(),
              'changes': <String, dynamic>{},
            }));
  });

  tearDown(() => db.close());

  group('getExpenses (local)', () {
    test('returns rows in the requested month, newest first', () async {
      await db.into(db.expenses).insert(_seed(id: 'e1', amount: 342.50,
          createdAt: DateTime(2026, 5, 10)));
      await db.into(db.expenses).insert(_seed(id: 'e2', amount: 100.0,
          createdAt: DateTime(2026, 5, 20)));
      // Out of range — should be excluded.
      await db.into(db.expenses).insert(_seed(id: 'e3', amount: 5,
          createdAt: DateTime(2026, 4, 1)));

      final result = await repo.getExpenses(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31, 23, 59, 59),
      );

      expect(result, hasLength(2));
      expect(result.first.id, 'e2'); // newest first
      expect(result.map((e) => e.id), isNot(contains('e3')));
      verifyNever(() => mockDio.get(ApiConstants.expenses,
          queryParameters: any(named: 'queryParameters')));
    });

    test('filters by category when provided', () async {
      await db.into(db.expenses).insert(_seed(id: 'e1', category: 'food_and_drink'));
      await db.into(db.expenses).insert(_seed(id: 'e2', category: 'shopping'));

      final result = await repo.getExpenses(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31),
        category: 'shopping',
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'e2');
    });
  });

  group('createExpense', () {
    test('posts to the network and triggers a sync', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _response({'expense': _expenseJson()}));

      final result = await repo.createExpense(
        amount: 342.50,
        description: 'Swiggy',
        category: ExpenseCategory.foodAndDrink,
        paymentMethod: ExpensePaymentMethod.upi,
      );

      expect(result.id, 'e1');
      expect(result.amount, 342.50);
      verify(() => mockDio.post(ApiConstants.expenses, data: {
            'amount': 342.50,
            'description': 'Swiggy',
            'category': 'food_and_drink',
            'paymentMethod': 'upi',
          })).called(1);
      verify(() => mockDio.get('/sync/pull',
          queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('propagates AppException on server error', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(AppException.server());

      expect(() => repo.createExpense(amount: 100.0),
          throwsA(isA<AppException>()));
    });
  });

  group('getExpenseSummary (local)', () {
    test('aggregates all-time total, by category and by month', () async {
      await db.into(db.expenses).insert(_seed(id: 'e1', amount: 300,
          category: 'food_and_drink', createdAt: DateTime(2026, 5, 2)));
      await db.into(db.expenses).insert(_seed(id: 'e2', amount: 200,
          category: 'shopping', createdAt: DateTime(2026, 5, 3)));
      await db.into(db.expenses).insert(_seed(id: 'e3', amount: 50,
          category: 'food_and_drink', createdAt: DateTime(2026, 6, 1)));

      final summary = await repo.getExpenseSummary();

      expect(summary.allTimeTotal, 550);
      final may = summary.byMonth.firstWhere((m) => m.month == '2026-05');
      expect(may.total, 500);
      final food = summary.byCategory
          .firstWhere((c) => c.category == 'food_and_drink');
      expect(food.total, 350);
    });
  });

  group('ExpenseCategory', () {
    test('fromServer/toServer round-trip', () {
      for (final cat in ExpenseCategory.values) {
        expect(ExpenseCategory.fromServer(cat.toServer()), cat);
      }
      expect(ExpenseCategory.fromServer('unknown'), ExpenseCategory.other);
    });
  });

  group('ExpensePaymentMethod', () {
    test('fromServer/toServer round-trip', () {
      for (final pm in ExpensePaymentMethod.values) {
        expect(ExpensePaymentMethod.fromServer(pm.toServer()), pm);
      }
      expect(ExpensePaymentMethod.fromServer('unknown'),
          ExpensePaymentMethod.other);
    });
  });
}
