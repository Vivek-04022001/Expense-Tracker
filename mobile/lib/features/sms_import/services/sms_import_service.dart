import '../data/models/parsed_transaction.dart';
import '../data/parsers/bank_sms_parser.dart';
import 'sms_datasource.dart';
import 'sms_import_history.dart';
import 'sms_permission_handler.dart';

class SmsScanResult {
  SmsScanResult({
    required this.transactions,
    required this.totalScanned,
    required this.unparsedCount,
    required this.alreadyImportedCount,
  });

  final List<ParsedTransaction> transactions;
  final int totalScanned;
  final int unparsedCount;
  /// How many parsed transactions were hidden because already imported.
  final int alreadyImportedCount;
}

class SmsPermissionDenied implements Exception {
  SmsPermissionDenied(this.permanentlyDenied);
  final bool permanentlyDenied;

  @override
  String toString() => permanentlyDenied
      ? 'SMS permission permanently denied'
      : 'SMS permission denied';
}

class SmsImportService {
  SmsImportService({
    required SmsPermissionHandler permissions,
    required SmsDatasource datasource,
    required BankSmsParser parser,
    SmsImportHistory? history,
  })  : _permissions = permissions,
        _datasource = datasource,
        _parser = parser,
        _history = history ?? SmsImportHistory();

  final SmsPermissionHandler _permissions;
  final SmsDatasource _datasource;
  final BankSmsParser _parser;
  final SmsImportHistory _history;

  Future<SmsScanResult> scan({
    Duration lookback = const Duration(days: 30),
  }) async {
    final perm = await _permissions.request();
    if (perm != SmsPermissionResult.granted) {
      throw SmsPermissionDenied(
        perm == SmsPermissionResult.permanentlyDenied,
      );
    }

    final raws = await _datasource.fetchRecent(lookback: lookback);
    final alreadyImported = await _history.loadImported();

    final parsed = <ParsedTransaction>[];
    final seenThisScan = <String>{};
    var unparsed = 0;
    var alreadyImportedCount = 0;

    for (final raw in raws) {
      final txn = _parser.parse(
        body: raw.body,
        sender: raw.sender,
        date: raw.date,
      );
      if (txn == null) {
        unparsed++;
        continue;
      }
      // Skip exact duplicates within this scan
      if (!seenThisScan.add(txn.fingerprint)) continue;
      // Skip transactions the user has already imported in a previous scan
      if (alreadyImported.contains(txn.fingerprint)) {
        alreadyImportedCount++;
        continue;
      }
      parsed.add(txn);
    }

    return SmsScanResult(
      transactions: parsed,
      totalScanned: raws.length,
      unparsedCount: unparsed,
      alreadyImportedCount: alreadyImportedCount,
    );
  }

  /// Call after successful import to persist the fingerprints.
  Future<void> recordImported(Iterable<String> fingerprints) =>
      _history.markImported(fingerprints);
}
