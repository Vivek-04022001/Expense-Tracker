import '../data/models/parsed_transaction.dart';
import '../data/parsers/bank_sms_parser.dart';
import 'sms_datasource.dart';
import 'sms_import_history.dart';

class SmsImportService {
  SmsImportService({
    required SmsDatasource datasource,
    required BankSmsParser parser,
    SmsImportHistory? history,
  })  : _datasource = datasource,
        _parser = parser,
        _history = history ?? SmsImportHistory();

  final SmsDatasource _datasource;
  final BankSmsParser _parser;
  final SmsImportHistory _history;

  /// Parses a single SMS pasted by the user. Returns null if the text
  /// does not look like a bank transaction.
  ParsedTransaction? parsePasted(String smsText) {
    final raw = _datasource.fromPasted(smsText);
    return _parser.parse(body: raw.body, sender: raw.sender, date: raw.date);
  }

  Future<Set<String>> loadImportedFingerprints() => _history.loadImported();

  Future<void> recordImported(Iterable<String> fingerprints) =>
      _history.markImported(fingerprints);
}
