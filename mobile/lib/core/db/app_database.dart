import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The on-device SQLite database — the single source of truth for the UI in the
/// offline-first architecture. Screens read/write here; the sync engine
/// reconciles it with the server in the background.
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Expenses,
    Incomes,
    Transfers,
    Budgets,
    Outbox,
    SyncMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  /// Clears all data. Called on logout so the next user never sees stale rows.
  Future<void> wipe() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  /// The pull cursor — timestamp of the last successful delta pull, or null on a
  /// fresh install (which triggers a full bootstrap pull).
  Future<DateTime?> getLastPulledAt() async {
    final row = await (select(syncMeta)
          ..where((t) => t.id.equals(0)))
        .getSingleOrNull();
    return row?.lastPulledAt;
  }

  /// Persists the server-provided cursor for the next delta pull.
  Future<void> setLastPulledAt(DateTime value) async {
    await into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(id: const Value(0), lastPulledAt: Value(value)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'paisa.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// App-wide singleton database provider (mirrors the dioClient provider style).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
