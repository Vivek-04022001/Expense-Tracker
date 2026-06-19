import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paisa/features/sms_import/data/models/parsed_transaction.dart';
import 'package:paisa/features/sms_import/data/parsers/bank_sms_parser.dart';
import 'package:paisa/features/sms_import/services/sms_datasource.dart';
import 'package:paisa/features/sms_import/services/sms_import_history.dart';
import 'package:paisa/features/sms_import/services/sms_import_service.dart';

class MockDatasource extends Mock implements SmsDatasource {}
class MockParser extends Mock implements BankSmsParser {}
class MockHistory extends Mock implements SmsImportHistory {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  late MockDatasource datasource;
  late MockParser parser;
  late MockHistory history;
  late SmsImportService service;

  final date = DateTime(2026, 5, 12);

  setUp(() {
    datasource = MockDatasource();
    parser = MockParser();
    history = MockHistory();
    when(() => history.loadImported()).thenAnswer((_) async => {});
    service = SmsImportService(
      datasource: datasource,
      parser: parser,
      history: history,
    );
  });

  group('SmsImportService.parsePasted()', () {
    test('returns null when parser cannot recognise the SMS', () {
      when(() => datasource.fromPasted(any())).thenReturn(
        RawSms(body: 'Your OTP is 123456', sender: 'BANKMS', date: date),
      );
      when(
        () => parser.parse(
          body: any(named: 'body'),
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(null);

      final result = service.parsePasted('Your OTP is 123456');
      expect(result, isNull);
    });

    test('returns a ParsedTransaction for a valid bank SMS', () {
      final txn = _makeDebit(amount: 450, date: date);
      when(() => datasource.fromPasted(any())).thenReturn(
        RawSms(
          body: 'Rs.450 debited from a/c **4321. Info: Swiggy.',
          sender: 'HDFCBK',
          date: date,
        ),
      );
      when(
        () => parser.parse(
          body: any(named: 'body'),
          sender: any(named: 'sender'),
          date: any(named: 'date'),
        ),
      ).thenReturn(txn);

      final result = service.parsePasted('Rs.450 debited from a/c **4321. Info: Swiggy.');
      expect(result, isNotNull);
      expect(result!.amount, 450);
    });

    test('passes the body from datasource.fromPasted to the parser', () {
      const smsText = 'Rs.750 debited';
      final raw = RawSms(body: smsText, sender: 'HDFCBK', date: date);
      when(() => datasource.fromPasted(smsText)).thenReturn(raw);
      when(
        () => parser.parse(
          body: smsText,
          sender: 'HDFCBK',
          date: any(named: 'date'),
        ),
      ).thenReturn(_makeDebit(amount: 750, date: date));

      service.parsePasted(smsText);

      verify(
        () => parser.parse(
          body: smsText,
          sender: 'HDFCBK',
          date: any(named: 'date'),
        ),
      ).called(1);
    });

    test('detects HDFC sender from body', () {
      const body = 'HDFC Bank: Rs.200 debited';
      final datasourceReal = SmsDatasource();
      final raw = datasourceReal.fromPasted(body);
      expect(raw.sender, 'HDFCBK');
    });

    test('detects ICICI sender from body', () {
      const body = 'ICICI Bank Acct XX9876 debited Rs 899';
      final datasourceReal = SmsDatasource();
      final raw = datasourceReal.fromPasted(body);
      expect(raw.sender, 'ICICIB');
    });

    test('falls back to BANKMS for unknown bank', () {
      const body = 'You have won a prize!';
      final datasourceReal = SmsDatasource();
      final raw = datasourceReal.fromPasted(body);
      expect(raw.sender, 'BANKMS');
    });
  });

  group('SmsImportService.recordImported()', () {
    test('delegates to history', () async {
      when(() => history.markImported(any())).thenAnswer((_) async {});
      await service.recordImported(['fp1', 'fp2']);
      verify(() => history.markImported(['fp1', 'fp2'])).called(1);
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
