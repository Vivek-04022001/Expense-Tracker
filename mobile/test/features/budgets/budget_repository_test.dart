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
import 'package:paisa/features/budgets/data/models/budget_model.dart';
import 'package:paisa/features/budgets/data/repositories/budget_repository.dart';
import 'package:paisa/features/expenses/data/models/expense_model.dart';

class MockDioClient extends Mock implements DioClient {}

Response<dynamic> _response(Map<String, dynamic> data, {int statusCode = 200}) =>
    Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

Map<String, dynamic> _budgetJson({
  String id = 'b1',
  String category = 'food_and_drink',
  String limitAmount = '5000.00',
  int month = 5,
  int year = 2026,
}) => {
      'id': id,
      'category': category,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
    };

BudgetsCompanion _seedBudget({
  String id = 'b1',
  String category = 'food_and_drink',
  double limitAmount = 5000.0,
  int month = 5,
  int year = 2026,
}) =>
    BudgetsCompanion.insert(
      id: id,
      category: category,
      limitAmount: limitAmount,
      month: month,
      year: year,
    );

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
  late MockDioClient mockDio;
  late AppDatabase db;
  late BudgetRepository repo;

  setUp(() {
    mockDio = MockDioClient();
    db = AppDatabase(NativeDatabase.memory());
    repo = BudgetRepository(mockDio, db, SyncEngine(db, SyncApi(mockDio)));

    when(() => mockDio.get('/sync/pull',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _response({
              'serverTime': DateTime.now().toUtc().toIso8601String(),
              'changes': <String, dynamic>{},
            }));
  });

  tearDown(() => db.close());

  group('getBudgets (local)', () {
    test('returns budgets for the month/year', () async {
      await db.into(db.budgets).insert(_seedBudget(id: 'b1'));
      await db.into(db.budgets)
          .insert(_seedBudget(id: 'b2', category: 'transport'));
      await db.into(db.budgets).insert(_seedBudget(id: 'b3', month: 4));

      final result = await repo.getBudgets(month: 5, year: 2026);

      expect(result, hasLength(2));
      expect(result.map((b) => b.id), containsAll(['b1', 'b2']));
      verifyNever(() => mockDio.get(ApiConstants.budgets,
          queryParameters: any(named: 'queryParameters')));
    });
  });

  group('upsertBudget', () {
    test('PUTs to network and triggers sync', () async {
      when(() => mockDio.put(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _response({'budget': _budgetJson()}));

      final result = await repo.upsertBudget(
        category: ExpenseCategory.foodAndDrink,
        limitAmount: 5000.0,
        month: 5,
        year: 2026,
      );

      expect(result.id, 'b1');
      verify(() => mockDio.put(ApiConstants.budgets, data: {
            'category': 'food_and_drink',
            'limitAmount': 5000.0,
            'month': 5,
            'year': 2026,
          })).called(1);
      verify(() => mockDio.get('/sync/pull',
          queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('propagates AppException on server error', () {
      when(() => mockDio.put(any(), data: any(named: 'data')))
          .thenThrow(AppException.server());

      expect(
        () => repo.upsertBudget(
          category: ExpenseCategory.shopping,
          limitAmount: 2000.0,
          month: 5,
          year: 2026,
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('deleteBudget', () {
    test('calls DELETE and triggers sync', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _response({}));

      await repo.deleteBudget('b1');

      verify(() => mockDio.delete(ApiConstants.budgetById('b1'))).called(1);
    });
  });

  group('getBudgetStatus (local)', () {
    test('computes spent/remaining from local expenses', () async {
      await db.into(db.budgets).insert(_seedBudget(id: 'b1', limitAmount: 5000));
      await db.into(db.expenses).insert(_seedExpense(id: 'e1', amount: 800));
      await db.into(db.expenses).insert(_seedExpense(id: 'e2', amount: 400));
      // Different category — ignored.
      await db.into(db.expenses).insert(
          _seedExpense(id: 'e3', amount: 999, category: 'shopping'));

      final result = await repo.getBudgetStatus('b1');

      expect(result.budget.id, 'b1');
      expect(result.spent, 1200.0);
      expect(result.remaining, 3800.0);
      expect(result.isOverBudget, isFalse);
    });

    test('flags over-budget correctly', () async {
      await db.into(db.budgets).insert(_seedBudget(id: 'b1', limitAmount: 1000));
      await db.into(db.expenses).insert(_seedExpense(id: 'e1', amount: 1500));

      final result = await repo.getBudgetStatus('b1');

      expect(result.isOverBudget, isTrue);
      expect(result.spent, 1500.0);
      expect(result.remaining, -500.0);
    });
  });

  group('BudgetModel.fromJson', () {
    test('parses categories and limitAmount', () {
      final model = BudgetModel.fromJson(
          _budgetJson(category: 'transport', limitAmount: '12345.67'));
      expect(model.category, ExpenseCategory.transport);
      expect(model.limitAmount, 12345.67);
    });
  });
}
