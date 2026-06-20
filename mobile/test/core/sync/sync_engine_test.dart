import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/core/db/app_database.dart';
import 'package:paisa/core/network/dio_client.dart';
import 'package:paisa/core/sync/outbox_service.dart';
import 'package:paisa/core/sync/sync_api.dart';
import 'package:paisa/core/sync/sync_engine.dart';

class MockDioClient extends Mock implements DioClient {}

Response<dynamic> _resp(Map<String, dynamic> data) => Response(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(path: ''),
    );

void main() {
  late MockDioClient dio;
  late AppDatabase db;
  late OutboxService outbox;
  late SyncEngine engine;

  setUp(() {
    dio = MockDioClient();
    db = AppDatabase(NativeDatabase.memory());
    outbox = OutboxService(db);
    engine = SyncEngine(db, SyncApi(dio));
  });

  tearDown(() => db.close());

  group('push', () {
    test('sends ops parent-first and clears applied entries', () async {
      // Enqueue a child before a parent to prove ordering is corrected.
      await outbox.enqueue(
          entity: 'expense', op: 'upsert', entityId: 'e1',
          payload: {'amount': 10}, updatedAt: DateTime(2026, 6, 1));
      await outbox.enqueue(
          entity: 'account', op: 'upsert', entityId: 'a1',
          payload: {'name': 'Wallet'}, updatedAt: DateTime(2026, 6, 1));

      when(() => dio.post('/sync/push', data: any(named: 'data')))
          .thenAnswer((invocation) async {
        final ops = (invocation.namedArguments[#data]['operations']) as List;
        // account must be pushed before expense
        expect(ops.first['entity'], 'account');
        expect(ops[1]['entity'], 'expense');
        return _resp({
          'results': [
            {'index': 0, 'id': 'a1', 'status': 'applied'},
            {'index': 1, 'id': 'e1', 'status': 'applied'},
          ],
        });
      });

      await engine.push();

      expect(await outbox.pendingCount, 0);
    });

    test('keeps failed entries and records the failure', () async {
      await outbox.enqueue(
          entity: 'expense', op: 'upsert', entityId: 'e1',
          payload: {'amount': 10}, updatedAt: DateTime(2026, 6, 1));

      when(() => dio.post('/sync/push', data: any(named: 'data')))
          .thenAnswer((_) async => _resp({
                'results': [
                  {'index': 0, 'id': 'e1', 'status': 'error'},
                ],
              }));

      await engine.push();

      final pending = await outbox.pending();
      expect(pending, hasLength(1));
      expect(pending.single.attempts, 1);
      expect(pending.single.lastError, 'error');
    });
  });

  group('pull', () {
    test('ingests changes and advances the cursor', () async {
      when(() => dio.get('/sync/pull',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _resp({
                'serverTime': '2026-06-21T10:00:00.000Z',
                'changes': {
                  'accounts': [
                    {
                      'id': 'a1',
                      'name': 'Bank',
                      'type': 'bank',
                      'openingBalance': '100',
                      'balance': '100',
                      'color': null,
                      'userId': 'u1',
                      'createdAt': '2026-06-20T10:00:00.000Z',
                      'updatedAt': '2026-06-20T10:00:00.000Z',
                      'deletedAt': null,
                    },
                  ],
                  'expenses': [
                    {
                      'id': 'e1',
                      'amount': '42',
                      'category': 'food_and_drink',
                      'paymentMethod': 'upi',
                      'description': null,
                      'accountId': 'a1',
                      'categoryId': null,
                      'userId': 'u1',
                      'createdAt': '2026-06-20T10:00:00.000Z',
                      'updatedAt': '2026-06-20T10:00:00.000Z',
                      'deletedAt': null,
                    },
                  ],
                },
              }));

      await engine.pull();

      final accounts = await db.select(db.accounts).get();
      expect(accounts.single.id, 'a1');
      expect(accounts.single.balance, 100);
      final expenses = await db.select(db.expenses).get();
      expect(expenses.single.id, 'e1');

      expect((await db.getLastPulledAt())!.toUtc(),
          DateTime.parse('2026-06-21T10:00:00.000Z'));
    });

    test('applies soft deletes from the server', () async {
      // Seed a synced row, then pull a delete for it.
      when(() => dio.get('/sync/pull',
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _resp({
                'serverTime': '2026-06-21T10:00:00.000Z',
                'changes': {
                  'expenses': [
                    {
                      'id': 'e1',
                      'amount': '42',
                      'category': 'food_and_drink',
                      'paymentMethod': 'upi',
                      'description': null,
                      'accountId': null,
                      'categoryId': null,
                      'userId': 'u1',
                      'createdAt': '2026-06-20T10:00:00.000Z',
                      'updatedAt': '2026-06-21T09:00:00.000Z',
                      'deletedAt': '2026-06-21T09:00:00.000Z',
                    },
                  ],
                },
              }));

      await engine.pull();

      final rows = await db.select(db.expenses).get();
      expect(rows.single.deletedAt, isNotNull);
    });
  });
}
