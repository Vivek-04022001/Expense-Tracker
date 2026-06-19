import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/constants/api_constants.dart';
import 'package:paisa/core/errors/app_exceptions.dart';
import 'package:paisa/core/network/dio_client.dart';
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
      'deletedAt': null,
    };

Map<String, dynamic> _summaryJson() => {
      'allTimeTotal': '1234.56',
      'byCategory': [
        {
          'category': 'food_and_drink',
          '_sum': {'amount': '500.00'},
        },
      ],
      'byMonth': [
        {'month': '2026-05', 'total': '500.00'},
      ],
      'byCategoryPerMonth': [
        {
          'month': '2026-05',
          'categories': [
            {'category': 'food_and_drink', 'total': '300.00'},
          ],
        },
      ],
    };

void main() {
  late MockDioClient mockDio;
  late ExpenseRepository repo;

  setUp(() {
    mockDio = MockDioClient();
    repo = ExpenseRepository(mockDio);
  });

  group('getExpenses', () {
    test('returns list of ExpenseModel on success', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _response({
          'expenses': [_expenseJson(), _expenseJson(id: 'e2', amount: '100.00')],
        }),
      );

      final from = DateTime(2026, 5, 1);
      final to = DateTime(2026, 5, 31);
      final result = await repo.getExpenses(from: from, to: to);

      expect(result, hasLength(2));
      expect(result.first.id, 'e1');
      expect(result.first.amount, 342.50);
      expect(result.first.category, ExpenseCategory.foodAndDrink);
      expect(result.first.paymentMethod, ExpensePaymentMethod.upi);
      expect(result.first.description, 'Swiggy');
      verify(
        () => mockDio.get(
          ApiConstants.expenses,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });

    test('passes category query param when provided', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => _response({'expenses': []}));

      await repo.getExpenses(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31),
        category: 'food_and_drink',
      );

      final captured = verify(
        () => mockDio.get(
          any(),
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.first as Map<String, String>;
      expect(captured['category'], 'food_and_drink');
    });

    test('propagates AppException on auth failure', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(AppException.unauthorized());

      expect(
        () => repo.getExpenses(
          from: DateTime(2026, 5, 1),
          to: DateTime(2026, 5, 31),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('createExpense', () {
    test('returns ExpenseModel on success', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({'expense': _expenseJson()}),
      );

      final result = await repo.createExpense(
        amount: 342.50,
        description: 'Swiggy',
        category: ExpenseCategory.foodAndDrink,
        paymentMethod: ExpensePaymentMethod.upi,
      );

      expect(result.id, 'e1');
      expect(result.amount, 342.50);
      expect(result.category, ExpenseCategory.foodAndDrink);
      verify(
        () => mockDio.post(
          ApiConstants.expenses,
          data: {
            'amount': 342.50,
            'description': 'Swiggy',
            'category': 'food_and_drink',
            'paymentMethod': 'upi',
          },
        ),
      ).called(1);
    });

    test('omits optional fields when null', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({'expense': _expenseJson(description: null)}),
      );

      await repo.createExpense(amount: 100.0);

      final captured = verify(
        () => mockDio.post(any(), data: captureAny(named: 'data')),
      ).captured.first as Map<String, dynamic>;
      expect(captured.containsKey('description'), isFalse);
      expect(captured.containsKey('category'), isFalse);
      expect(captured.containsKey('paymentMethod'), isFalse);
    });

    test('propagates AppException on server error', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenThrow(AppException.server());

      expect(
        () => repo.createExpense(amount: 100.0),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('updateExpense', () {
    test('returns updated ExpenseModel', () async {
      when(
        () => mockDio.put(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({
          'expense': _expenseJson(amount: '999.00', category: 'shopping'),
        }),
      );

      final result = await repo.updateExpense(
        'e1',
        amount: 999.0,
        category: ExpenseCategory.shopping,
      );

      expect(result.amount, 999.0);
      expect(result.category, ExpenseCategory.shopping);
      verify(
        () => mockDio.put(
          ApiConstants.expenseById('e1'),
          data: {'amount': 999.0, 'category': 'shopping'},
        ),
      ).called(1);
    });

    test('only sends provided fields', () async {
      when(
        () => mockDio.put(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({'expense': _expenseJson()}),
      );

      await repo.updateExpense('e1', description: 'Zomato');

      final captured = verify(
        () => mockDio.put(any(), data: captureAny(named: 'data')),
      ).captured.first as Map<String, dynamic>;
      expect(captured, {'description': 'Zomato'});
    });
  });

  group('deleteExpense', () {
    test('calls delete endpoint and returns void', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => _response({}),
      );

      await repo.deleteExpense('e1');

      verify(() => mockDio.delete(ApiConstants.expenseById('e1'))).called(1);
    });

    test('propagates AppException on not found', () async {
      when(() => mockDio.delete(any())).thenThrow(AppException.unknown());

      expect(() => repo.deleteExpense('nonexistent'), throwsA(isA<AppException>()));
    });
  });

  group('getExpenseSummary', () {
    test('returns ExpenseSummaryModel with parsed fields', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => _response(_summaryJson()),
      );

      final result = await repo.getExpenseSummary();

      expect(result.allTimeTotal, 1234.56);
      expect(result.byMonth, hasLength(1));
      expect(result.byMonth.first.month, '2026-05');
      expect(result.byMonth.first.total, 500.0);
      expect(result.byCategoryPerMonth, hasLength(1));
      expect(result.byCategoryPerMonth.first.categories.first.category, 'food_and_drink');
      verify(() => mockDio.get(ApiConstants.expenseSummary)).called(1);
    });

    test('propagates AppException on network failure', () async {
      when(() => mockDio.get(any())).thenThrow(AppException.network());

      expect(() => repo.getExpenseSummary(), throwsA(isA<AppException>()));
    });
  });

  group('ExpenseCategory', () {
    test('fromServer maps all known values', () {
      expect(ExpenseCategory.fromServer('food_and_drink'), ExpenseCategory.foodAndDrink);
      expect(ExpenseCategory.fromServer('transport'), ExpenseCategory.transport);
      expect(ExpenseCategory.fromServer('bills_and_utilities'), ExpenseCategory.billsAndUtilities);
      expect(ExpenseCategory.fromServer('shopping'), ExpenseCategory.shopping);
      expect(ExpenseCategory.fromServer('health'), ExpenseCategory.health);
      expect(ExpenseCategory.fromServer('entertainment'), ExpenseCategory.entertainment);
      expect(ExpenseCategory.fromServer('education'), ExpenseCategory.education);
      expect(ExpenseCategory.fromServer('other'), ExpenseCategory.other);
      expect(ExpenseCategory.fromServer('unknown_value'), ExpenseCategory.other);
    });

    test('toServer round-trips correctly', () {
      for (final cat in ExpenseCategory.values) {
        expect(ExpenseCategory.fromServer(cat.toServer()), cat);
      }
    });
  });

  group('ExpensePaymentMethod', () {
    test('fromServer maps all known values', () {
      expect(ExpensePaymentMethod.fromServer('upi'), ExpensePaymentMethod.upi);
      expect(ExpensePaymentMethod.fromServer('bank_transfer'), ExpensePaymentMethod.bankTransfer);
      expect(ExpensePaymentMethod.fromServer('cash'), ExpensePaymentMethod.cash);
      expect(ExpensePaymentMethod.fromServer('other'), ExpensePaymentMethod.other);
      expect(ExpensePaymentMethod.fromServer('unknown'), ExpensePaymentMethod.other);
    });

    test('toServer round-trips correctly', () {
      for (final pm in ExpensePaymentMethod.values) {
        expect(ExpensePaymentMethod.fromServer(pm.toServer()), pm);
      }
    });
  });
}
