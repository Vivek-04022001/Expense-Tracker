import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import 'data_refresh.dart';
import 'sync_engine.dart';

/// Live count of locally-queued (not-yet-pushed) changes, driven by a Drift
/// stream so it updates the moment a write enqueues or a push clears the outbox.
final pendingCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.outbox).watch().map((rows) => rows.length);
});

/// Observable sync status for the UI: whether a sync is running, when the last
/// one succeeded, and the last error.
class SyncState {
  const SyncState({this.syncing = false, this.lastSyncedAt, this.error});

  final bool syncing;
  final DateTime? lastSyncedAt;
  final String? error;

  SyncState copyWith({
    bool? syncing,
    DateTime? lastSyncedAt,
    Object? error = _noChange,
  }) {
    return SyncState(
      syncing: syncing ?? this.syncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }

  static const _noChange = Object();
}

/// Drives sync runs and exposes their status. The UI calls [syncNow]; triggers
/// (launch, foreground, reconnect) call it too, so status stays accurate.
class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  /// Runs a full sync (push + pull) and refreshes the UI. Overlapping calls are
  /// ignored while one is in flight.
  Future<void> syncNow() async {
    if (state.syncing) return;
    state = state.copyWith(syncing: true, error: null);
    try {
      await ref.read(syncEngineProvider).sync();
      refreshAllData(ref);
      state = SyncState(syncing: false, lastSyncedAt: DateTime.now());
    } catch (e) {
      state = state.copyWith(syncing: false, error: e.toString());
    }
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);
