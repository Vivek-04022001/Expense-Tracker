import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of fingerprints that have already been imported,
/// so repeated scans skip transactions the user already acted on.
class SmsImportHistory {
  static const _key = 'sms_import_fingerprints';

  Future<Set<String>> loadImported() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  Future<void> markImported(Iterable<String> fingerprints) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key)?.toSet() ?? {};
    existing.addAll(fingerprints);
    await prefs.setStringList(_key, existing.toList());
  }
}
