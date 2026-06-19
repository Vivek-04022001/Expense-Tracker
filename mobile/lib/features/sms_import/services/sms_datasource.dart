/// Raw SMS row normalised to our domain shape.
class RawSms {
  RawSms({
    required this.body,
    required this.sender,
    required this.date,
  });

  final String body;
  final String sender;
  final DateTime date;
}

class SmsDatasource {
  /// Creates a [RawSms] from user-pasted text, inferring the sender
  /// from keywords in the body.
  RawSms fromPasted(String text) => RawSms(
        body: text,
        sender: _detectSender(text),
        date: DateTime.now(),
      );

  String _detectSender(String body) {
    final upper = body.toUpperCase();
    if (upper.contains('HDFC')) return 'HDFCBK';
    if (upper.contains('ICICI')) return 'ICICIB';
    if (upper.contains('SBI') || upper.contains('STATE BANK')) return 'SBISMS';
    if (upper.contains('AXIS')) return 'AXISBK';
    if (upper.contains('KOTAK')) return 'KOTAKB';
    if (upper.contains('YES BANK') || upper.contains('YESBANK')) return 'YESBK';
    if (upper.contains('INDUSIND')) return 'IINDUS';
    return 'BANKMS';
  }
}
