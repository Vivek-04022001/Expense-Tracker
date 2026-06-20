import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Manages the durable outbox queue of local mutations awaiting a push.
///
/// Entities are pushed in dependency order (parents before children) so the
/// server never receives an expense that references an account it hasn't seen.
class OutboxService {
  OutboxService(this._db);

  final AppDatabase _db;

  /// Lower numbers push first. Accounts/categories are parents of the rest.
  static const _priority = {
    'account': 0,
    'category': 1,
    'expense': 2,
    'income': 2,
    'transfer': 2,
    'budget': 2,
  };

  Future<void> enqueue({
    required String entity,
    required String op,
    required String entityId,
    Map<String, dynamic>? payload,
    required DateTime updatedAt,
  }) {
    return _db.into(_db.outbox).insert(
          OutboxCompanion.insert(
            entity: entity,
            op: op,
            entityId: entityId,
            payload: jsonEncode(payload ?? const {}),
            updatedAt: updatedAt,
          ),
        );
  }

  /// All queued operations in push order: parents first, then insertion order.
  Future<List<OutboxRow>> pending() async {
    final rows = await _db.select(_db.outbox).get();
    rows.sort((a, b) {
      final pa = _priority[a.entity] ?? 9;
      final pb = _priority[b.entity] ?? 9;
      if (pa != pb) return pa.compareTo(pb);
      return a.localId.compareTo(b.localId);
    });
    return rows;
  }

  Future<bool> get hasPending async =>
      (await (_db.selectOnly(_db.outbox)..addColumns([_db.outbox.localId]))
              .get())
          .isNotEmpty;

  Future<int> get pendingCount async => (await pending()).length;

  Future<void> remove(int localId) =>
      (_db.delete(_db.outbox)..where((t) => t.localId.equals(localId))).go();

  Future<void> recordFailure(int localId, String error) {
    return (_db.update(_db.outbox)..where((t) => t.localId.equals(localId)))
        .write(
      OutboxCompanion.custom(
        attempts: _db.outbox.attempts + const Constant(1),
        lastError: Constant(error),
      ),
    );
  }
}
