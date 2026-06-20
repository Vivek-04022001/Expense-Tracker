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
import 'package:paisa/features/income/data/models/income_model.dart';
import 'package:paisa/features/income/data/repositories/income_repository.dart';

class MockDioClient extends Mock implements DioClient {}

Response<dynamic> _response(dynamic data, {int statusCode = 200}) => Response(
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
  late MockDioClient mockDio;
  late AppDatabase db;
  late IncomeRepository repo;

  setUp(() {
    mockDio = MockDioClient();
    db = AppDatabase(NativeDatabase.memory());
    repo = IncomeRepository(mockDio, db, SyncEngine(db, SyncApi(mockDio)));

    when(() => mockDio.get('/sync/pull',
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _response({
              'serverTime': DateTime.now().toUtc().toIso8601String(),
              'changes': <String, dynamic>{},
            }));
  });

  tearDown(() => db.close());

  group('getIncomes (local)', () {
    test('returns rows in range, newest first', () async {
      await db.into(db.incomes).insert(_seed(id: 'i1',
          createdAt: DateTime(2026, 5, 10)));
      await db.into(db.incomes).insert(_seed(id: 'i2', amount: 10000,
          createdAt: DateTime(2026, 5, 20)));
      await db.into(db.incomes).insert(_seed(id: 'i3', amount: 5,
          createdAt: DateTime(2026, 4, 1)));

      final result = await repo.getIncomes(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 31, 23, 59, 59),
      );

      expect(result, hasLength(2));
      expect(result.first.id, 'i2');
      verifyNever(() => mockDio.get(ApiConstants.income,
          queryParameters: any(named: 'queryParameters')));
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

  group('createIncome', () {
    test('posts to network and triggers sync', () async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => _response({'income': _incomeJson()}));

      final result = await repo.createIncome(
        amount: 50000.0,
        incomeType: IncomeType.salary,
        description: 'May salary',
      );

      expect(result.id, 'i1');
      verify(() => mockDio.post(ApiConstants.income, data: {
            'amount': 50000.0,
            'incomeType': 'salary',
            'description': 'May salary',
          })).called(1);
      verify(() => mockDio.get('/sync/pull',
          queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('propagates AppException on server error', () {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(AppException.server());

      expect(() => repo.createIncome(amount: 100.0),
          throwsA(isA<AppException>()));
    });
  });

  group('updateIncome', () {
    test('uses PATCH and triggers sync', () async {
      when(() => mockDio.patch(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => _response({
                'income': _incomeJson(amount: '75000.00', incomeType: 'freelance')
              }));

      final result = await repo.updateIncome('i1',
          amount: 75000.0, incomeType: IncomeType.freelance);

      expect(result.amount, 75000.0);
      verify(() => mockDio.patch(ApiConstants.incomeById('i1'),
          data: {'amount': 75000.0, 'incomeType': 'freelance'})).called(1);
    });
  });

  group('deleteIncome', () {
    test('calls DELETE and triggers sync', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => _response({}));

      await repo.deleteIncome('i1');

      verify(() => mockDio.delete(ApiConstants.incomeById('i1'))).called(1);
    });
  });

  group('IncomeType', () {
    test('fromServer/toServer round-trip', () {
      for (final type in IncomeType.values) {
        expect(IncomeType.fromServer(type.toServer()), type);
      }
      expect(IncomeType.fromServer('unknown'), IncomeType.other);
    });
  });
}
