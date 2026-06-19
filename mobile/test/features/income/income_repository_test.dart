import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/constants/api_constants.dart';
import 'package:paisa/core/errors/app_exceptions.dart';
import 'package:paisa/core/network/dio_client.dart';
import 'package:paisa/features/income/data/models/income_model.dart';
import 'package:paisa/features/income/data/repositories/income_repository.dart';

class MockDioClient extends Mock implements DioClient {}

Response<dynamic> _response(dynamic data, {int statusCode = 200}) =>
    Response(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(path: ''),
    );

Map<String, dynamic> _incomeJson({
  String id = 'i1',
  String amount = '50000.00',
  String incomeType = 'salary',
  String? description = 'May salary',
}) => {
      'id': id,
      'amount': amount,
      'incomeType': incomeType,
      'description': description,
      'userId': 'u1',
      'createdAt': '2026-05-18T10:00:00.000Z',
    };

void main() {
  late MockDioClient mockDio;
  late IncomeRepository repo;

  setUp(() {
    mockDio = MockDioClient();
    repo = IncomeRepository(mockDio);
  });

  group('getIncomes', () {
    test('returns list of IncomeModel on success', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => _response([_incomeJson(), _incomeJson(id: 'i2', amount: '10000.00')]),
      );

      final from = DateTime(2026, 5, 1);
      final to = DateTime(2026, 5, 31);
      final result = await repo.getIncomes(from: from, to: to);

      expect(result, hasLength(2));
      expect(result.first.id, 'i1');
      expect(result.first.amount, 50000.0);
      expect(result.first.incomeType, IncomeType.salary);
      expect(result.first.description, 'May salary');
    });

    test('sends YYYY-MM-DD date format', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => _response([]));

      await repo.getIncomes(from: DateTime(2026, 5, 1), to: DateTime(2026, 5, 31));

      final captured = verify(
        () => mockDio.get(any(), queryParameters: captureAny(named: 'queryParameters')),
      ).captured.first as Map<String, String>;
      expect(captured['from'], '2026-05-01');
      expect(captured['to'], '2026-05-31');
    });

    test('includes incomeType filter when provided', () async {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer((_) async => _response([]));

      await repo.getIncomes(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31),
        incomeType: IncomeType.salary,
      );

      final captured = verify(
        () => mockDio.get(any(), queryParameters: captureAny(named: 'queryParameters')),
      ).captured.first as Map<String, String>;
      expect(captured['incomeType'], 'salary');
    });

    test('propagates AppException on auth failure', () {
      when(
        () => mockDio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenThrow(AppException.unauthorized());

      expect(
        () => repo.getIncomes(from: DateTime(2026, 5, 1), to: DateTime(2026, 5, 31)),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('createIncome', () {
    test('returns IncomeModel on success', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _response({'income': _incomeJson()}));

      final result = await repo.createIncome(
        amount: 50000.0,
        incomeType: IncomeType.salary,
        description: 'May salary',
      );

      expect(result.id, 'i1');
      expect(result.amount, 50000.0);
      expect(result.incomeType, IncomeType.salary);
      verify(
        () => mockDio.post(
          ApiConstants.income,
          data: {
            'amount': 50000.0,
            'incomeType': 'salary',
            'description': 'May salary',
          },
        ),
      ).called(1);
    });

    test('omits optional fields when null', () async {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({'income': _incomeJson(description: null)}),
      );

      await repo.createIncome(amount: 100.0);

      final captured = verify(
        () => mockDio.post(any(), data: captureAny(named: 'data')),
      ).captured.first as Map<String, dynamic>;
      expect(captured.containsKey('incomeType'), isFalse);
      expect(captured.containsKey('description'), isFalse);
    });

    test('propagates AppException on server error', () {
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenThrow(AppException.server());

      expect(
        () => repo.createIncome(amount: 100.0),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('updateIncome', () {
    test('uses PATCH and returns updated IncomeModel', () async {
      when(
        () => mockDio.patch(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({
          'income': _incomeJson(amount: '75000.00', incomeType: 'freelance'),
        }),
      );

      final result = await repo.updateIncome(
        'i1',
        amount: 75000.0,
        incomeType: IncomeType.freelance,
      );

      expect(result.amount, 75000.0);
      expect(result.incomeType, IncomeType.freelance);
      verify(
        () => mockDio.patch(
          ApiConstants.incomeById('i1'),
          data: {'amount': 75000.0, 'incomeType': 'freelance'},
        ),
      ).called(1);
    });

    test('only sends provided fields', () async {
      when(
        () => mockDio.patch(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _response({'income': _incomeJson()}));

      await repo.updateIncome('i1', description: 'Bonus');

      final captured = verify(
        () => mockDio.patch(any(), data: captureAny(named: 'data')),
      ).captured.first as Map<String, dynamic>;
      expect(captured, {'description': 'Bonus'});
    });
  });

  group('deleteIncome', () {
    test('calls DELETE endpoint', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _response({}));

      await repo.deleteIncome('i1');

      verify(() => mockDio.delete(ApiConstants.incomeById('i1'))).called(1);
    });

    test('propagates AppException', () {
      when(() => mockDio.delete(any())).thenThrow(AppException.unknown());

      expect(() => repo.deleteIncome('i1'), throwsA(isA<AppException>()));
    });
  });

  group('IncomeType', () {
    test('fromServer maps all known values', () {
      expect(IncomeType.fromServer('salary'), IncomeType.salary);
      expect(IncomeType.fromServer('freelance'), IncomeType.freelance);
      expect(IncomeType.fromServer('investment'), IncomeType.investment);
      expect(IncomeType.fromServer('reward'), IncomeType.reward);
      expect(IncomeType.fromServer('other'), IncomeType.other);
      expect(IncomeType.fromServer('unknown'), IncomeType.other);
    });

    test('toServer round-trips correctly', () {
      for (final type in IncomeType.values) {
        expect(IncomeType.fromServer(type.toServer()), type);
      }
    });
  });
}
