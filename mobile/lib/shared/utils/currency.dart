/// Formats a number with the Indian digit-grouping system (lakh/crore),
/// e.g. 1234567.5 -> "₹12,34,567.50".
///
/// Keeps two decimals by default. Set [decimals] to 0 for whole rupees.
String formatRupee(num value, {int decimals = 2}) {
  final negative = value < 0;
  final abs = value.abs();
  final fixed = abs.toStringAsFixed(decimals);

  final parts = fixed.split('.');
  final grouped = _groupIndian(parts[0]);
  final body = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;

  return '${negative ? '-' : ''}₹$body';
}

String _groupIndian(String intStr) {
  if (intStr.length <= 3) return intStr;
  final last3 = intStr.substring(intStr.length - 3);
  final rest = intStr.substring(0, intStr.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '$buf,$last3';
}

/// Adds Indian digit grouping to a raw calculator expression while it is being
/// typed, e.g. "1234+50000" -> "1,234+50,000" and "12345.6" -> "12,345.6".
/// Operators, the decimal point and trailing decimals are left untouched.
String groupIndianExpression(String expr) {
  final buf = StringBuffer();
  final numberRe = RegExp(r'\d+(\.\d*)?');
  var last = 0;
  for (final m in numberRe.allMatches(expr)) {
    buf.write(expr.substring(last, m.start));
    final token = m.group(0)!;
    final dot = token.indexOf('.');
    if (dot == -1) {
      buf.write(_groupIndian(token));
    } else {
      buf
        ..write(_groupIndian(token.substring(0, dot)))
        ..write(token.substring(dot));
    }
    last = m.end;
  }
  buf.write(expr.substring(last));
  return buf.toString();
}
