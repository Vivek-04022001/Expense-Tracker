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
