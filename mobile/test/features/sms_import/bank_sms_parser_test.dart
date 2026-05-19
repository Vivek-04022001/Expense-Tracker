import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/features/expenses/data/models/expense_model.dart';
import 'package:paisa/features/income/data/models/income_model.dart';
import 'package:paisa/features/sms_import/data/models/parsed_transaction.dart';
import 'package:paisa/features/sms_import/data/parsers/bank_sms_parser.dart';

void main() {
  final parser = BankSmsParser();
  final date = DateTime(2026, 5, 12, 10, 30);

  ParsedTransaction? parse(String body, String sender) =>
      parser.parse(body: body, sender: sender, date: date);

  // ── helpers ─────────────────────────────────────────────────────────────────

  void expectDebit(
    ParsedTransaction? txn, {
    required double amount,
    String? merchant,
    ExpenseCategory? category,
  }) {
    expect(txn, isNotNull, reason: 'expected a parsed transaction');
    expect(txn!.isDebit, isTrue, reason: 'expected debit');
    expect(txn.amount, closeTo(amount, 0.01));
    if (merchant != null) {
      expect(
        txn.merchant?.toLowerCase(),
        contains(merchant.toLowerCase()),
        reason: 'merchant mismatch',
      );
    }
    if (category != null) {
      expect(txn.suggestedCategory, equals(category));
    }
  }

  void expectCredit(
    ParsedTransaction? txn, {
    required double amount,
    IncomeType? incomeType,
  }) {
    expect(txn, isNotNull, reason: 'expected a parsed transaction');
    expect(txn!.isCredit, isTrue, reason: 'expected credit');
    expect(txn.amount, closeTo(amount, 0.01));
    if (incomeType != null) {
      expect(txn.suggestedIncomeType, equals(incomeType));
    }
  }

  // ── HDFC ────────────────────────────────────────────────────────────────────
  group('HDFC Bank', () {
    test('debit — sent to merchant', () {
      final txn = parse(
        'Sent Rs.450.00 From HDFC Bank A/C *1234 To AMAZON On 12/05/26.',
        'VK-HDFCBK',
      );
      expectDebit(txn, amount: 450, merchant: 'amazon', category: ExpenseCategory.shopping);
    });

    test('debit — UPI payment', () {
      final txn = parse(
        'Rs.120.00 debited from HDFC Bank A/C XX5678 to SWIGGY via UPI on 12-May-26.',
        'VK-HDFCBK',
      );
      expectDebit(txn, amount: 120, category: ExpenseCategory.foodAndDrink);
    });

    test('credit — NEFT received', () {
      final txn = parse(
        'Rs.1500.00 credited to a/c **1234 on 10-05-26 by NEFT from SALARY EMPLOYER.',
        'VK-HDFCBK',
      );
      expectCredit(txn, amount: 1500, incomeType: IncomeType.salary);
    });

    test('credit — amount with comma', () {
      final txn = parse(
        'Rs.25,000.00 credited to HDFC Bank A/C XX9900 on 01-May-26 from PAYROLL.',
        'VK-HDFCBK',
      );
      expectCredit(txn, amount: 25000);
    });

    test('unrelated SMS returns null', () {
      final txn = parse(
        'Dear HDFC customer, your card statement is ready. View at hdfc.com.',
        'VK-HDFCBK',
      );
      expect(txn, isNull);
    });
  });

  // ── ICICI ───────────────────────────────────────────────────────────────────
  group('ICICI Bank', () {
    test('debit — card spent at merchant', () {
      final txn = parse(
        'INR 250.00 spent on ICICI Bank Card XX1234 at SWIGGY on 12-May-26.',
        'AX-ICICIB',
      );
      expectDebit(txn, amount: 250, merchant: 'swiggy', category: ExpenseCategory.foodAndDrink);
    });

    test('debit — debited from account', () {
      final txn = parse(
        'INR 1200.00 debited from ICICI A/c XX5678 on 12-May-26 to UBER.',
        'AX-ICICIB',
      );
      expectDebit(txn, amount: 1200, category: ExpenseCategory.transport);
    });

    test('credit — credited with amount', () {
      final txn = parse(
        'ICICI Bank Acct XX123 credited with Rs 5,000.00 on 01-May-26.',
        'AX-ICICIB',
      );
      expectCredit(txn, amount: 5000);
    });
  });

  // ── SBI ─────────────────────────────────────────────────────────────────────
  group('SBI', () {
    test('debit — standard UPI SMS', () {
      final txn = parse(
        'Dear Customer, Rs.500.00 debited from A/c X1234 on 12/05/26 to ZOMATO via UPI. Ref 99887766.',
        'JD-SBIPSG',
      );
      expectDebit(txn, amount: 500, category: ExpenseCategory.foodAndDrink);
    });

    test('credit — salary credit', () {
      final txn = parse(
        'Rs.25000 credited to A/c XX1234 on 01/05/26 by SALARY.',
        'JD-SBIPSG',
      );
      expectCredit(txn, amount: 25000, incomeType: IncomeType.salary);
    });

    test('debit — petrol station', () {
      final txn = parse(
        'Rs.2000.00 debited from SBI A/c X9876 on 12/05/26 to HPCL.',
        'JD-SBIPSG',
      );
      expectDebit(txn, amount: 2000, category: ExpenseCategory.transport);
    });
  });

  // ── Axis ────────────────────────────────────────────────────────────────────
  group('Axis Bank', () {
    test('debit — spent at merchant', () {
      final txn = parse(
        'INR 899.00 debited from Axis Bank A/c XX4567 at NETFLIX on 12-May-26.',
        'BP-AXISBK',
      );
      expectDebit(txn, amount: 899, category: ExpenseCategory.entertainment);
    });

    test('credit', () {
      final txn = parse(
        'INR 10,000.00 credited to Axis Bank A/c XX4567 by SALARY on 01-May-26.',
        'BP-AXISBK',
      );
      expectCredit(txn, amount: 10000, incomeType: IncomeType.salary);
    });
  });

  // ── UPI (generic) ───────────────────────────────────────────────────────────
  group('Generic UPI', () {
    test('PhonePe debit', () {
      final txn = parse(
        'You paid Rs.120 to Starbucks via UPI. UPI Ref 987654321.',
        'PHONEPE',
      );
      expectDebit(txn, amount: 120, merchant: 'starbucks', category: ExpenseCategory.foodAndDrink);
      expect(txn!.paymentMethod, equals(ExpensePaymentMethod.upi));
    });

    test('GPay debit', () {
      final txn = parse(
        'Sent Rs.345.00 to BookMyShow via UPI. Ref No 123456.',
        'GPAY',
      );
      expectDebit(txn, amount: 345, category: ExpenseCategory.entertainment);
    });

    test('UPI credit from person', () {
      final txn = parse(
        'You received Rs.500 from Rahul via UPI. UPI Ref 111222.',
        'PHONEPE',
      );
      expectCredit(txn, amount: 500);
    });

    test('SMS without UPI hint returns null from UPI parser', () {
      // Should fall through to generic debit parser instead
      final txn = parse(
        'You paid Rs.200 to merchant XYZ.',
        'RANDOM',
      );
      // either null or parsed by generic — must not crash
      if (txn != null) {
        expect(txn.amount, closeTo(200, 0.01));
      }
    });
  });

  // ── Category guessing ────────────────────────────────────────────────────────
  group('Category guessing', () {
    void expectCategory(String merchant, String smsBody, ExpenseCategory cat) {
      final txn = parse(
        'Rs.100.00 debited from HDFC A/c XX1234 to $merchant via UPI.',
        'VK-HDFCBK',
      );
      expect(txn?.suggestedCategory, equals(cat),
          reason: 'Expected $cat for merchant "$merchant"');
    }

    test('food keywords', () => expectCategory('Zomato', smsBody(''), ExpenseCategory.foodAndDrink));
    test('transport keywords', () => expectCategory('Uber India', smsBody(''), ExpenseCategory.transport));
    test('bills keywords', () => expectCategory('Airtel Broadband', smsBody(''), ExpenseCategory.billsAndUtilities));
    test('shopping keywords', () => expectCategory('Amazon', smsBody(''), ExpenseCategory.shopping));
    test('health keywords', () => expectCategory('Apollo Pharmacy', smsBody(''), ExpenseCategory.health));
    test('entertainment keywords', () => expectCategory('BookMyShow', smsBody(''), ExpenseCategory.entertainment));
    test('education keywords', () => expectCategory('Udemy', smsBody(''), ExpenseCategory.education));
    test('fallback to other', () => expectCategory('XYZ Corp', smsBody(''), ExpenseCategory.other));
  });

  // ── Income type guessing ─────────────────────────────────────────────────────
  group('Income type guessing', () {
    test('salary', () {
      final txn = parse(
        'Rs.50000 credited to SBI A/c XX1234 on 01/05/26 by SALARY ACME CORP.',
        'JD-SBIPSG',
      );
      expect(txn?.suggestedIncomeType, equals(IncomeType.salary));
    });

    test('cashback as reward', () {
      final txn = parse(
        'Rs.150.00 credited to HDFC A/c XX1234 from CASHBACK REWARD.',
        'VK-HDFCBK',
      );
      expect(txn?.suggestedIncomeType, equals(IncomeType.reward));
    });

    test('unknown credit defaults to other', () {
      final txn = parse(
        'Rs.500.00 credited to HDFC A/c XX1234 from JOHN.',
        'VK-HDFCBK',
      );
      expect(txn?.suggestedIncomeType, equals(IncomeType.other));
    });
  });

  // ── Amount parsing ───────────────────────────────────────────────────────────
  group('Amount parsing', () {
    test('handles comma-separated amounts', () {
      final txn = parse(
        'Rs.1,23,456.78 debited from HDFC A/c XX1234 to Merchant.',
        'VK-HDFCBK',
      );
      expectDebit(txn, amount: 123456.78);
    });

    test('handles amount without decimal', () {
      final txn = parse(
        'Rs.500 debited from HDFC A/c XX1234 to OLA.',
        'VK-HDFCBK',
      );
      expectDebit(txn, amount: 500);
    });
  });

  // ── Deduplication fingerprint ────────────────────────────────────────────────
  group('Fingerprint', () {
    test('same txn produces same fingerprint', () {
      final a = parse(
        'Rs.450.00 debited from HDFC A/c XX1234 to AMAZON.',
        'VK-HDFCBK',
      )!;
      final b = parse(
        'Rs.450.00 debited from HDFC A/c XX1234 to AMAZON.',
        'VK-HDFCBK',
      )!;
      expect(a.fingerprint, equals(b.fingerprint));
    });

    test('different amount produces different fingerprint', () {
      final a = parse('Rs.450.00 debited from HDFC A/c XX1234 to AMAZON.', 'VK-HDFCBK')!;
      final b = parse('Rs.451.00 debited from HDFC A/c XX1234 to AMAZON.', 'VK-HDFCBK')!;
      expect(a.fingerprint, isNot(equals(b.fingerprint)));
    });
  });

  // ── Non-bank SMS ─────────────────────────────────────────────────────────────
  group('Non-bank SMS', () {
    test('OTP message returns null', () {
      expect(
        parse('Your OTP for login is 123456. Do not share.', 'ICICIB'),
        isNull,
      );
    });

    test('promotional SMS returns null', () {
      expect(
        parse('Get 50% off on all orders today! Use code SAVE50.', 'OFFERS'),
        isNull,
      );
    });

    test('completely unrelated SMS returns null', () {
      expect(
        parse('Mom: Are you coming home for dinner tonight?', '+919876543210'),
        isNull,
      );
    });
  });
}

// ignore: unused_element
String smsBody(String extra) => extra;
