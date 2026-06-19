import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/constants/api_constants.dart';
import 'package:paisa/core/errors/app_exceptions.dart';
import 'package:paisa/core/network/dio_client.dart';
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

Map<String, dynamic> _statusJson({
  double spent = 1200.0,
  double remaining = 3800.0,
  double percentUsed = 24.0,
  bool isOverBudget = false,
}) => {
      'budget': _budgetJson(),
      'status': {
        'spent': spent,
        'remaining': remaining,
        'percentUsed': percentUsed,
        'isOverBudget': isOverBudget,
      },
    };

void main() {
  late MockDioClient mockDio;
  late BudgetRepository repo;

  setUp(() {
    mockDio = MockDioClient();
    repo = BudgetRepository(mockDio);
  });

  group('getBudgets', () {
    test('returns list of BudgetModel from budgets key', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _response({
          'budgets': [_budgetJson(), _budgetJson(id: 'b2', category: 'transport')],
        }),
      );

      final result = await repo.getBudgets(month: 5, year: 2026);

      expect(result, hasLength(2));
      expect(result.first.id, 'b1');
      expect(result.first.category, ExpenseCategory.foodAndDrink);
      expect(result.first.limitAmount, 5000.0);
      expect(result.last.category, ExpenseCategory.transport);
      verify(
        () => mockDio.get(
          ApiConstants.budgets,
          queryParameters: {'month': '5', 'year': '2026'},
        ),
      ).called(1);
    });

    test('returns empty list when no budgets', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => _response({'budgets': []}));

      final result = await repo.getBudgets(month: 5, year: 2026);
      expect(result, isEmpty);
    });

    test('propagates AppException on network failure', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(AppException.network());

      expect(
        () => repo.getBudgets(month: 5, year: 2026),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('upsertBudget', () {
    test('returns BudgetModel from budget key on success', () async {
      when(
        () => mockDio.put(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({'budget': _budgetJson()}),
      );

      final result = await repo.upsertBudget(
        category: ExpenseCategory.foodAndDrink,
        limitAmount: 5000.0,
        month: 5,
        year: 2026,
      );

      expect(result.id, 'b1');
      expect(result.category, ExpenseCategory.foodAndDrink);
      expect(result.limitAmount, 5000.0);
      verify(
        () => mockDio.put(
          ApiConstants.budgets,
          data: {
            'category': 'food_and_drink',
            'limitAmount': 5000.0,
            'month': 5,
            'year': 2026,
          },
        ),
      ).called(1);
    });

    test('propagates AppException on server error', () async {
      when(
        () => mockDio.put(any(), data: any(named: 'data')),
      ).thenThrow(AppException.server());

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
    test('calls delete endpoint', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => _response({}),
      );

      await repo.deleteBudget('b1');

      verify(() => mockDio.delete(ApiConstants.budgetById('b1'))).called(1);
    });

    test('propagates AppException on not found', () async {
      when(() => mockDio.delete(any())).thenThrow(AppException.unknown());

      expect(() => repo.deleteBudget('nonexistent'), throwsA(isA<AppException>()));
    });
  });

  group('getBudgetStatus', () {
    test('returns BudgetStatusModel with correct fields', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _response(_statusJson()),
      );

      final result = await repo.getBudgetStatus('b1');

      expect(result.budget.id, 'b1');
      expect(result.spent, 1200.0);
      expect(result.remaining, 3800.0);
      expect(result.percentUsed, 24.0);
      expect(result.isOverBudget, isFalse);
      verify(() => mockDio.get(ApiConstants.budgetStatus('b1'))).called(1);
    });

    test('correctly parses over-budget status', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _response(
          _statusJson(spent: 6000.0, remaining: -1000.0, percentUsed: 120.0, isOverBudget: true),
        ),
      );

      final result = await repo.getBudgetStatus('b1');

      expect(result.isOverBudget, isTrue);
      expect(result.spent, 6000.0);
      expect(result.remaining, -1000.0);
      expect(result.percentUsed, 120.0);
    });

    test('propagates AppException on network failure', () async {
      when(() => mockDio.get(any())).thenThrow(AppException.network());

      expect(() => repo.getBudgetStatus('b1'), throwsA(isA<AppException>()));
    });
  });

  group('BudgetModel.fromJson', () {
    test('parses all categories correctly', () {
      final categories = {
        'food_and_drink': ExpenseCategory.foodAndDrink,
        'transport': ExpenseCategory.transport,
        'bills_and_utilities': ExpenseCategory.billsAndUtilities,
        'shopping': ExpenseCategory.shopping,
        'health': ExpenseCategory.health,
        'entertainment': ExpenseCategory.entertainment,
        'education': ExpenseCategory.education,
        'other': ExpenseCategory.other,
      };

      for (final entry in categories.entries) {
        final model = BudgetModel.fromJson(_budgetJson(category: entry.key));
        expect(model.category, entry.value);
      }
    });

    test('parses limitAmount from string', () {
      final model = BudgetModel.fromJson(_budgetJson(limitAmount: '12345.67'));
      expect(model.limitAmount, 12345.67);
    });
  });
}
