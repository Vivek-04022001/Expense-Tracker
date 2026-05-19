import '../../../expenses/data/models/expense_model.dart';
import '../../../income/data/models/income_model.dart';
import '../models/parsed_transaction.dart';

/// Parser chain: each method tries to extract a transaction from a single SMS.
/// First non-null match wins. Order matters — most-specific first.
///
/// Real Indian bank formats observed:
///   HDFC:   "Rs.450.00 debited from a/c **4321 ... Info: Swiggy."
///   ICICI:  "ICICI Bank Acct XX9876 debited for Rs 899.00 ... Info: Zomato."
///   SBI:    "a/c XX1234 is debited by Rs.150.00 ... trf to OMETRO UPI."
///   UPI:    "Paid Rs 199 to netflix@icici via UPI"
///           "Sent Rs 50 to chai_wala@paytm using UPI"
class BankSmsParser {
  ParsedTransaction? parse({
    required String body,
    required String sender,
    required DateTime date,
  }) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final upperSender = sender.toUpperCase();

    return _parseHdfc(normalized, upperSender, date) ??
        _parseIcici(normalized, upperSender, date) ??
        _parseSbi(normalized, upperSender, date) ??
        _parseAxis(normalized, upperSender, date) ??
        _parseUpi(normalized, upperSender, date) ??
        _parseGenericDebit(normalized, upperSender, date) ??
        _parseGenericCredit(normalized, upperSender, date);
  }

  // ── HDFC ───────────────────────────────────────────────────────────────────
  // Real formats:
  //   "Rs.450.00 debited from a/c **4321 on 20-05-26. Info: Swiggy. Avl bal: Rs.12,340.50"
  //   "Rs.25,000.00 credited to a/c XX4321 on 20-05-26. Info: SALARY ACME CORP"
  //   "Sent Rs.450.00 From HDFC Bank A/C *1234 To AMAZON On 12/05/26."
  ParsedTransaction? _parseHdfc(String body, String sender, DateTime date) {
    if (!_isFromBank(sender, body, ['HDFC'])) return null;

    final amount = _findAmount(body);
    if (amount == null) return null;

    final direction = _findDirection(body);
    if (direction == null) return null;

    return _build(
      amount: amount,
      direction: direction,
      merchant: _findMerchant(body, direction),
      bank: 'HDFC',
      body: body,
      sender: sender,
      date: date,
    );
  }

  // ── ICICI ──────────────────────────────────────────────────────────────────
  // Real formats:
  //   "ICICI Bank Acct XX9876 debited for Rs 899.00 on 20-May-26. Info: Zomato. Avl Bal: Rs 8,450.00"
  //   "INR 250.00 spent on ICICI Bank Card XX1234 at SWIGGY on 12-May-26."
  //   "ICICI Bank Acct XX123 credited with Rs 5,000.00 on 01-May-26."
  ParsedTransaction? _parseIcici(String body, String sender, DateTime date) {
    if (!_isFromBank(sender, body, ['ICICI'])) return null;

    final amount = _findAmount(body);
    if (amount == null) return null;

    final direction = _findDirection(body);
    if (direction == null) return null;

    return _build(
      amount: amount,
      direction: direction,
      merchant: _findMerchant(body, direction),
      bank: 'ICICI',
      body: body,
      sender: sender,
      date: date,
    );
  }

  // ── SBI ────────────────────────────────────────────────────────────────────
  // Real formats:
  //   "Your a/c no. XX1234 is debited by Rs.150.00 on 20/05/26 trf to OMETRO UPI. Avl bal Rs.5,210.00"
  //   "Your a/c no. XX1234 is debited by Rs.3,499.00 on 17/05/26 trf to FLIPKART. Avl bal Rs.5,360.00"
  //   "Dear Customer, Rs.500.00 debited from A/c X1234 on 12/05/26 to ZOMATO via UPI."
  ParsedTransaction? _parseSbi(String body, String sender, DateTime date) {
    if (!_isFromBank(sender, body, ['SBI', 'SBIINB', 'SBIPSG'])) return null;

    final amount = _findAmount(body);
    if (amount == null) return null;

    final direction = _findDirection(body);
    if (direction == null) return null;

    return _build(
      amount: amount,
      direction: direction,
      merchant: _findMerchant(body, direction),
      bank: 'SBI',
      body: body,
      sender: sender,
      date: date,
    );
  }

  // ── Axis ───────────────────────────────────────────────────────────────────
  ParsedTransaction? _parseAxis(String body, String sender, DateTime date) {
    if (!_isFromBank(sender, body, ['AXIS', 'AXISBK'])) return null;

    final amount = _findAmount(body);
    if (amount == null) return null;

    final direction = _findDirection(body);
    if (direction == null) return null;

    return _build(
      amount: amount,
      direction: direction,
      merchant: _findMerchant(body, direction),
      bank: 'Axis',
      body: body,
      sender: sender,
      date: date,
    );
  }

  // ── Generic UPI (PhonePe / GPay / Paytm) ───────────────────────────────────
  // Real formats:
  //   "Paid Rs 199 to netflix@icici via UPI on 20-05-26. UPI Ref: 834729104756"
  //   "Sent Rs 50 to chai_wala@paytm using UPI. Transaction ID: 9182736450"
  //   "You received Rs.500 from Rahul via UPI. UPI Ref 111222."
  ParsedTransaction? _parseUpi(String body, String sender, DateTime date) {
    final upiHint =
        body.toLowerCase().contains('upi') ||
        sender.contains('PYTM') ||
        sender.contains('PHONEPE') ||
        sender.contains('GPAY');
    if (!upiHint) return null;

    final amount = _findAmount(body);
    if (amount == null) return null;

    final debitKeywords = RegExp(
      r'\b(?:paid|sent|you\s+paid|debited)\b',
      caseSensitive: false,
    );
    final creditKeywords = RegExp(
      r'\b(?:received|credited|you\s+received)\b',
      caseSensitive: false,
    );

    TxnDirection? direction;
    if (debitKeywords.hasMatch(body) && !creditKeywords.hasMatch(body)) {
      direction = TxnDirection.debit;
    } else if (creditKeywords.hasMatch(body) && !debitKeywords.hasMatch(body)) {
      direction = TxnDirection.credit;
    }
    if (direction == null) return null;

    // UPI-specific merchant: extract handle before "via/using/on"
    String? merchant = _findUpiMerchant(body, direction);

    return _build(
      amount: amount,
      direction: direction,
      merchant: merchant,
      bank: 'UPI',
      body: body,
      sender: sender,
      date: date,
      method: ExpensePaymentMethod.upi,
    );
  }

  // ── Generic debit fallback ─────────────────────────────────────────────────
  ParsedTransaction? _parseGenericDebit(
    String body,
    String sender,
    DateTime date,
  ) {
    if (!_looksLikeBankSender(sender) && !_hasBankKeyword(body)) return null;
    if (!RegExp(
      r'\b(?:debited|debit|withdrawn|spent|paid|sent)\b',
      caseSensitive: false,
    ).hasMatch(body)) {
      return null;
    }

    final amount = _findAmount(body);
    if (amount == null) return null;

    return _build(
      amount: amount,
      direction: TxnDirection.debit,
      merchant: _findMerchant(body, TxnDirection.debit),
      bank: _bankFromSender(sender),
      body: body,
      sender: sender,
      date: date,
    );
  }

  // ── Generic credit fallback ────────────────────────────────────────────────
  ParsedTransaction? _parseGenericCredit(
    String body,
    String sender,
    DateTime date,
  ) {
    if (!_looksLikeBankSender(sender) && !_hasBankKeyword(body)) return null;
    if (!RegExp(
      r'\b(?:credited|credit|received|deposited)\b',
      caseSensitive: false,
    ).hasMatch(body)) {
      return null;
    }

    final amount = _findAmount(body);
    if (amount == null) return null;

    return _build(
      amount: amount,
      direction: TxnDirection.credit,
      merchant: _findMerchant(body, TxnDirection.credit),
      bank: _bankFromSender(sender),
      body: body,
      sender: sender,
      date: date,
    );
  }

  // ── Shared extraction helpers ───────────────────────────────────────────────

  /// Finds the first `Rs./INR/₹ AMOUNT` in the body. Returns null if not found.
  double? _findAmount(String body) {
    final match = RegExp(
      r'(?:rs\.?|inr|₹)\s?([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    ).firstMatch(body);
    if (match == null) return null;
    return _toAmount(match.group(1)!);
  }

  /// Returns debit/credit direction based on keyword presence.
  /// Returns null when ambiguous or no direction keyword found.
  TxnDirection? _findDirection(String body) {
    final lower = body.toLowerCase();
    final hasDebit = RegExp(
      r'\b(?:debited|debit|withdrawn|spent|paid|sent)\b',
    ).hasMatch(lower);
    final hasCredit = RegExp(
      r'\b(?:credited|credit|received|deposited)\b',
    ).hasMatch(lower);
    if (hasDebit && !hasCredit) return TxnDirection.debit;
    if (hasCredit && !hasDebit) return TxnDirection.credit;
    return null;
  }

  /// Extracts merchant name using a priority chain:
  ///   1. `Info: MERCHANT` — common in HDFC, ICICI
  ///   2. `trf to MERCHANT` — common in SBI
  ///   3. `to/at/towards MERCHANT` — generic debit
  ///   4. `from/by MERCHANT` — generic credit
  String? _findMerchant(String body, TxnDirection direction) {
    // 1. "Info: Merchant"
    final info = RegExp(
      r'Info:\s*([A-Za-z0-9 &._\-/*@]{2,40}?)(?:\s*\.|$)',
      caseSensitive: false,
    ).firstMatch(body);
    if (info != null) return _cleanMerchant(info.group(1));

    // 2. "trf to Merchant"
    final trf = RegExp(
      r'trf\s+to\s+([A-Za-z0-9 &._\-/*@]{2,40}?)(?:\s+(?:avl|available|via|upi|ref)|\.|$)',
      caseSensitive: false,
    ).firstMatch(body);
    if (trf != null) return _cleanMerchant(trf.group(1));

    if (direction == TxnDirection.debit) {
      // 3. "to/at/towards Merchant" (skip account-number-like contexts)
      final to = RegExp(
        r'(?<!\w)(?:to|at|towards)\s+([A-Za-z][A-Za-z0-9 &._\-/*@]{1,39}?)(?:\s+(?:via|on|ref|using|avl|available)|\.|$)',
        caseSensitive: false,
      ).firstMatch(body);
      if (to != null) return _cleanMerchant(to.group(1));
    } else {
      // 4. "from/by Merchant"
      final from = RegExp(
        r'(?:from|by)\s+([A-Za-z][A-Za-z0-9 &._\-/*@]{1,39}?)(?:\s+(?:on|via|ref)|\.|$)',
        caseSensitive: false,
      ).firstMatch(body);
      if (from != null) return _cleanMerchant(from.group(1));
    }

    return null;
  }

  /// UPI-specific merchant extractor — handles VPA handles like `netflix@icici`.
  String? _findUpiMerchant(String body, TxnDirection direction) {
    if (direction == TxnDirection.debit) {
      // "paid/sent Rs X to MERCHANT via/using/on"
      final match = RegExp(
        r'(?:paid|sent)\s+(?:rs\.?|inr|₹)\s?[\d,]+(?:\.\d{1,2})?\s+to\s+([A-Za-z0-9@._\-]{2,50}?)(?:\s+(?:via|using|on|through|ref)|\.|$)',
        caseSensitive: false,
      ).firstMatch(body);
      if (match != null) return _cleanUpiHandle(match.group(1));
    } else {
      final match = RegExp(
        r'(?:received|from)\s+(?:rs\.?|inr|₹)?\s?[\d,]*\s*(?:from\s+)?([A-Za-z0-9@._\-]{2,50}?)(?:\s+(?:via|using|on|through|ref)|\.|$)',
        caseSensitive: false,
      ).firstMatch(body);
      if (match != null) return _cleanUpiHandle(match.group(1));
    }
    // Fallback to generic merchant
    return _findMerchant(body, direction);
  }

  // ── Other helpers ───────────────────────────────────────────────────────────

  ParsedTransaction _build({
    required double amount,
    required TxnDirection direction,
    required String? merchant,
    required String bank,
    required String body,
    required String sender,
    required DateTime date,
    ExpensePaymentMethod? method,
  }) {
    return ParsedTransaction(
      amount: amount,
      direction: direction,
      date: date,
      bank: bank,
      rawSms: body,
      sender: sender,
      merchant: merchant,
      paymentMethod: method,
      suggestedCategory: direction == TxnDirection.debit
          ? _guessCategory(merchant, body)
          : null,
      suggestedIncomeType: direction == TxnDirection.credit
          ? _guessIncomeType(merchant, body)
          : null,
    );
  }

  bool _isFromBank(String sender, String body, List<String> keys) {
    final s = sender.toUpperCase();
    final b = body.toUpperCase();
    return keys.any((k) => s.contains(k) || b.contains(k));
  }

  bool _looksLikeBankSender(String sender) {
    return RegExp(
      r'^[A-Z]{2}-?[A-Z0-9]{2,}$|^[A-Z]{6,}$',
    ).hasMatch(sender.toUpperCase());
  }

  bool _hasBankKeyword(String body) {
    final lower = body.toLowerCase();
    return lower.contains('a/c') ||
        lower.contains('account') ||
        lower.contains('upi') ||
        lower.contains('card');
  }

  String _bankFromSender(String sender) {
    final s = sender.toUpperCase();
    if (s.contains('HDFC')) return 'HDFC';
    if (s.contains('ICICI')) return 'ICICI';
    if (s.contains('SBI')) return 'SBI';
    if (s.contains('AXIS')) return 'Axis';
    if (s.contains('KOTAK')) return 'Kotak';
    if (s.contains('YES')) return 'Yes Bank';
    if (s.contains('INDUS')) return 'IndusInd';
    if (s.contains('PYTM')) return 'Paytm';
    if (s.contains('PHONEPE')) return 'PhonePe';
    if (s.contains('GPAY')) return 'GPay';
    return 'Bank';
  }

  double _toAmount(String raw) =>
      double.parse(raw.replaceAll(',', ''));

  String? _cleanMerchant(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'[.,;:]+$'), '').trim();
    // Strip UPI VPA domain (e.g. "netflix@icici" → "Netflix")
    if (s.contains('@')) s = s.split('@').first;
    // Collapse "UPI/merchant/submerchant" style paths
    if (s.contains('/')) {
      final parts = s.split('/').where((p) => p.trim().isNotEmpty).toList();
      if (parts.length >= 2) s = parts.last;
    }
    s = s.trim();
    if (s.length < 2) return null;
    // Title-case all-caps strings
    if (s == s.toUpperCase() && s.length > 3) {
      s = s
          .split(' ')
          .map((w) => w.isEmpty
              ? w
              : w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }
    return s;
  }

  /// Strips VPA domain and trailing UPI noise from UPI handles.
  String? _cleanUpiHandle(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    // "chai_wala@paytm" → "chai wala" (underscores → spaces, drop domain)
    if (s.contains('@')) s = s.split('@').first;
    s = s.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (s.length < 2) return null;
    // Title-case
    s = s
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
    return s;
  }

  // ── Category / income-type guessing ─────────────────────────────────────────

  static const _categoryKeywords = <ExpenseCategory, List<String>>{
    ExpenseCategory.foodAndDrink: [
      'swiggy', 'zomato', 'dominos', 'mcdonald', 'starbucks', 'cafe',
      'restaurant', 'food', 'eat', 'kfc', 'pizza', 'burger', 'chai',
    ],
    ExpenseCategory.transport: [
      'uber', 'ola', 'rapido', 'metro', 'ometro', 'irctc', 'redbus',
      'fuel', 'petrol', 'hpcl', 'iocl', 'bpcl', 'parking', 'toll',
    ],
    ExpenseCategory.billsAndUtilities: [
      'electricity', 'water bill', 'gas', 'broadband', 'airtel', 'jio',
      'vi ', 'vodafone', 'recharge', 'postpaid', 'dth', 'bill payment',
      'tatapower',
    ],
    ExpenseCategory.shopping: [
      'amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'nykaa',
      'snapdeal', 'shop', 'mall', 'store',
    ],
    ExpenseCategory.health: [
      'pharma', 'apollo', 'medplus', 'hospital', 'clinic', 'doctor',
      'practo', 'medicine', 'pharmacy',
    ],
    ExpenseCategory.entertainment: [
      'bookmyshow', 'pvr', 'inox', 'netflix', 'spotify', 'prime video',
      'hotstar', 'movie', 'game',
    ],
    ExpenseCategory.education: [
      'udemy', 'coursera', 'byju', 'unacademy', 'school', 'college',
      'tuition', 'course', 'edu',
    ],
  };

  static const _incomeKeywords = <IncomeType, List<String>>{
    IncomeType.salary: ['salary', 'payroll'],
    IncomeType.freelance: ['freelance', 'invoice', 'upwork', 'fiverr'],
    IncomeType.investment: [
      'dividend', 'interest', 'mutual fund', 'mf ', 'zerodha', 'groww',
    ],
    IncomeType.reward: ['cashback', 'refund', 'reward'],
  };

  ExpenseCategory _guessCategory(String? merchant, String body) {
    final hay = '${merchant ?? ''} $body'.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any(hay.contains)) {
        return entry.key;
      }
    }
    return ExpenseCategory.other;
  }

  IncomeType _guessIncomeType(String? merchant, String body) {
    final hay = '${merchant ?? ''} $body'.toLowerCase();
    for (final entry in _incomeKeywords.entries) {
      if (entry.value.any(hay.contains)) {
        return entry.key;
      }
    }
    return IncomeType.other;
  }
}
