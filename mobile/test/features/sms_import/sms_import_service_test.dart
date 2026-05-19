import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/features/sms_import/data/models/parsed_transaction.dart';
import 'package:paisa/features/sms_import/data/parsers/bank_sms_parser.dart';
import 'package:paisa/features/sms_import/services/sms_datasource.dart';
import 'package:paisa/features/sms_import/services/sms_import_history.dart';
import 'package:paisa/features/sms_import/services/sms_import_service.dart';
import 'package:paisa/features/sms_import/services/sms_permission_handler.dart';

class MockPermissions extends Mock implements SmsPermissionHandler {}
class MockDatasource extends Mock implements SmsDatasource {}
class MockParser extends Mock implements BankSmsParser {}
class MockHistory extends Mock implements SmsImportHistory {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(days: 30));
    registerFallbackValue(DateTime(2026));
  });

  late MockPermissions permissions;
  late MockDatasource datasource;
  late MockParser parser;
  late MockHistory history;
  late SmsImportService service;

  final date = DateTime(2026, 5, 12);

  setUp(() {
    permissions = MockPermissions();
    datasource = MockDatasource();
    parser = MockParser();
    history = MockHistory();
    // Default: no previously imported fingerprints
    when(() => history.loadImported()).thenAnswer((_) async => {});
    service = SmsImportService(
      permissions: permissions,
      datasource: datasource,
      parser: parser,
      history: history,
    );
  });

  group('SmsImportService.scan()', () {
    test('throws SmsPermissionDenied(false) when permission is denied', () async {
      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.denied);

      expect(
        () => service.scan(),
        throwsA(
          predicate<SmsPermissionDenied>((e) => !e.permanentlyDenied),
        ),
      );
    });

    test('throws SmsPermissionDenied(true) when permanently denied', () async {
      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.permanentlyDenied);

      expect(
        () => service.scan(),
        throwsA(
          predicate<SmsPermissionDenied>((e) => e.permanentlyDenied),
        ),
      );
    });

    test('returns empty result when inbox is empty', () async {
      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => []);

      final result = await service.scan();

      expect(result.transactions, isEmpty);
      expect(result.totalScanned, 0);
      expect(result.unparsedCount, 0);
    });

    test('unparseable SMS increments unparsedCount', () async {
      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => [
            RawSms(body: 'Your OTP is 123456', sender: 'ICICIB', date: date),
          ]);
      when(
        () => parser.parse(
          body: any(named: 'body'),
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(null);

      final result = await service.scan();

      expect(result.transactions, isEmpty);
      expect(result.totalScanned, 1);
      expect(result.unparsedCount, 1);
    });

    test('successfully parsed SMS appears in result', () async {
      final txn = _makeDebit(amount: 500, date: date);

      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => [
            RawSms(body: 'Rs.500 debited', sender: 'HDFCBK', date: date),
          ]);
      when(
        () => parser.parse(
          body: any(named: 'body'),
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(txn);

      final result = await service.scan();

      expect(result.transactions, hasLength(1));
      expect(result.transactions.first.amount, 500);
      expect(result.totalScanned, 1);
      expect(result.unparsedCount, 0);
    });

    test('duplicate transactions (same fingerprint) are deduplicated', () async {
      final txn = _makeDebit(amount: 500, date: date);

      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      // Same transaction in inbox twice (e.g. delivery report duplicate)
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => [
            RawSms(body: 'Rs.500 debited', sender: 'HDFCBK', date: date),
            RawSms(body: 'Rs.500 debited', sender: 'HDFCBK', date: date),
          ]);
      when(
        () => parser.parse(
          body: any(named: 'body'),
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(txn);

      final result = await service.scan();

      // Even though inbox had 2 rows, fingerprint dedup keeps only 1
      expect(result.transactions, hasLength(1));
      expect(result.totalScanned, 2);
    });

    test('different fingerprints are NOT deduplicated', () async {
      final txn1 = _makeDebit(amount: 500, date: date);
      final txn2 = _makeDebit(amount: 750, date: date);

      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => [
            RawSms(body: 'msg1', sender: 'HDFCBK', date: date),
            RawSms(body: 'msg2', sender: 'HDFCBK', date: date),
          ]);
      when(
        () => parser.parse(
          body: 'msg1',
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(txn1);
      when(
        () => parser.parse(
          body: 'msg2',
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(txn2);

      final result = await service.scan();

      expect(result.transactions, hasLength(2));
    });

    test('mix of parseable and unparseable SMS is counted correctly', () async {
      final txn = _makeDebit(amount: 300, date: date);

      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => [
            RawSms(body: 'good', sender: 'HDFCBK', date: date),
            RawSms(body: 'bad', sender: 'UNKNOWN', date: date),
            RawSms(body: 'bad2', sender: 'UNKNOWN', date: date),
          ]);
      when(
        () => parser.parse(body: 'good', sender: any(named: 'sender'), date: any(named: 'date')),
      ).thenReturn(txn);
      when(
        () => parser.parse(body: 'bad', sender: any(named: 'sender'), date: any(named: 'date')),
      ).thenReturn(null);
      when(
        () => parser.parse(body: 'bad2', sender: any(named: 'sender'), date: any(named: 'date')),
      ).thenReturn(null);

      final result = await service.scan();

      expect(result.transactions, hasLength(1));
      expect(result.totalScanned, 3);
      expect(result.unparsedCount, 2);
    });

    test('already-imported fingerprints are filtered out and counted', () async {
      final txn = _makeDebit(amount: 500, date: date);

      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => [
            RawSms(body: 'msg', sender: 'HDFCBK', date: date),
          ]);
      when(
        () => parser.parse(
          body: any(named: 'body'),
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(txn);
      // Simulate that this fingerprint was already imported in a prior session
      when(() => history.loadImported())
          .thenAnswer((_) async => {txn.fingerprint});

      final result = await service.scan();

      expect(result.transactions, isEmpty);
      expect(result.alreadyImportedCount, 1);
    });

    test('new fingerprints pass through when history is empty', () async {
      final txn = _makeDebit(amount: 500, date: date);

      when(() => permissions.request())
          .thenAnswer((_) async => SmsPermissionResult.granted);
      when(() => datasource.fetchRecent(lookback: any(named: 'lookback')))
          .thenAnswer((_) async => [
            RawSms(body: 'msg', sender: 'HDFCBK', date: date),
          ]);
      when(
        () => parser.parse(
          body: any(named: 'body'),
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(txn);

      final result = await service.scan();

      expect(result.transactions, hasLength(1));
      expect(result.alreadyImportedCount, 0);
    });
  });
}

ParsedTransaction _makeDebit({required double amount, required DateTime date}) {
  return ParsedTransaction(
    amount: amount,
    direction: TxnDirection.debit,
    date: date,
    bank: 'HDFC',
    rawSms: 'Rs.$amount debited',
    sender: 'HDFCBK',
    merchant: 'Merchant$amount',
  );
}
