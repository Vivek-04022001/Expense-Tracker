import 'dart:io';
import 'package:another_telephony/telephony.dart';

/// Raw SMS row from Android inbox, normalized to our domain shape.
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
  SmsDatasource({Telephony? telephony})
      : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;

  /// Reads the SMS inbox and returns messages sent within [lookback] of now.
  /// Returns an empty list on non-Android platforms.
  Future<List<RawSms>> fetchRecent({
    Duration lookback = const Duration(days: 30),
  }) async {
    if (!Platform.isAndroid) return const [];

    final cutoffMs = DateTime.now()
        .subtract(lookback)
        .millisecondsSinceEpoch
        .toString();

    final messages = await _telephony.getInboxSms(
      columns: const [
        SmsColumn.ADDRESS,
        SmsColumn.BODY,
        SmsColumn.DATE,
      ],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThan(cutoffMs),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    final result = <RawSms>[];
    for (final m in messages) {
      final body = m.body;
      final sender = m.address;
      final dateMs = m.date;
      if (body == null || sender == null || dateMs == null) continue;
      result.add(
        RawSms(
          body: body,
          sender: sender,
          date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        ),
      );
    }
    return result;
  }
}
