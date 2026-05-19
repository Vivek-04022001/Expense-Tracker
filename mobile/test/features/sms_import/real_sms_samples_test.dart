import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/features/sms_import/data/models/parsed_transaction.dart';
import 'package:paisa/features/sms_import/data/parsers/bank_sms_parser.dart';

void main() {
  final parser = BankSmsParser();
  final date = DateTime(2026, 5, 20);

  ParsedTransaction? parse(String body, String sender) =>
      parser.parse(body: body, sender: sender, date: date);

  group('HDFC real samples', () {
    test('HDFC debit — Swiggy with "Info:" pattern', () {
      final txn = parse(
        'Rs.450.00 debited from a/c **4321 on 20-05-26. Info: Swiggy. Available bal: Rs.12,340.50',
        'VK-HDFCBK',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(450, 0.01));
      print('HDFC Swiggy → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });

    test('HDFC debit — Amazon with "Info:" pattern', () {
      final txn = parse(
        'Rs.1,200.00 debited from a/c **4321 on 19-05-26. Info: Amazon. Available bal: Rs.13,540.50',
        'VK-HDFCBK',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(1200, 0.01));
      print('HDFC Amazon → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });
  });

  group('ICICI real samples', () {
    test('ICICI debit — Zomato with "debited for Rs X" pattern', () {
      final txn = parse(
        'ICICI Bank Acct XX9876 debited for Rs 899.00 on 20-May-26. Info: Zomato. Avl Bal: Rs 8,450.00',
        'AX-ICICIB',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(899, 0.01));
      print('ICICI Zomato → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });

    test('ICICI debit — Myntra', () {
      final txn = parse(
        'ICICI Bank Acct XX9876 debited for Rs 2,500.00 on 18-May-26. Info: Myntra. Avl Bal: Rs 9,349.00',
        'AX-ICICIB',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(2500, 0.01));
      print('ICICI Myntra → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });
  });

  group('SBI real samples', () {
    test('SBI debit — OMETRO UPI with "trf to" pattern', () {
      final txn = parse(
        'Your a/c no. XX1234 is debited by Rs.150.00 on 20/05/26 trf to OMETRO UPI. Avl bal Rs.5,210.00',
        'JD-SBIPSG',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(150, 0.01));
      print('SBI OMETRO → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });

    test('SBI debit — Flipkart with "trf to" pattern', () {
      final txn = parse(
        'Your a/c no. XX1234 is debited by Rs.3,499.00 on 17/05/26 trf to FLIPKART. Avl bal Rs.5,360.00',
        'JD-SBIPSG',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(3499, 0.01));
      print('SBI Flipkart → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });
  });

  group('Generic UPI real samples', () {
    test('UPI debit — Netflix via "Paid Rs X to Y via UPI"', () {
      final txn = parse(
        'Paid Rs 199 to netflix@icici via UPI on 20-05-26. UPI Ref: 834729104756',
        'PHONEPE',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(199, 0.01));
      print('UPI Netflix → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });

    test('UPI debit — chai wala via "Sent Rs X to Y using UPI"', () {
      final txn = parse(
        'Sent Rs 50 to chai_wala@paytm using UPI. Transaction ID: 9182736450',
        'PYTM',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isDebit, isTrue);
      expect(txn.amount, closeTo(50, 0.01));
      print('UPI chai_wala → merchant: ${txn.merchant}, category: ${txn.suggestedCategory}');
    });
  });

  group('Credit samples (should parse as credit, not debit)', () {
    test('HDFC credit — salary', () {
      final txn = parse(
        'Rs.25,000.00 credited to a/c XX4321 on 20-05-26. Info: SALARY ACME CORP',
        'VK-HDFCBK',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isCredit, isTrue);
      expect(txn.amount, closeTo(25000, 0.01));
      print('Credit salary → type: ${txn.suggestedIncomeType}');
    });

    test('Generic credit — refund', () {
      final txn = parse(
        'Amount of Rs 500.00 received in your account from REFUND AMAZON',
        'VK-HDFCBK',
      );
      expect(txn, isNotNull, reason: 'should parse');
      expect(txn!.isCredit, isTrue);
      expect(txn.amount, closeTo(500, 0.01));
      print('Credit refund → type: ${txn.suggestedIncomeType}');
    });
  });
}
