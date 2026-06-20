import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Recomputes an account's cached `balance` from its activity, mirroring the
/// server's recomputeBalance() so offline balances stay correct:
///
///   balance = openingBalance
///             + Σ income  − Σ expense
///             + Σ transfersIn  − Σ transfersOut   (non-deleted rows)
///
/// Idempotent: safe to call repeatedly after any local write.
class LocalBalanceService {
  LocalBalanceService(this._db);

  final AppDatabase _db;

  Future<void> recompute(String accountId) async {
    final account = await (_db.select(_db.accounts)
          ..where((t) => t.id.equals(accountId)))
        .getSingleOrNull();
    if (account == null) return;

    final incomeRows = await (_db.select(_db.incomes)
          ..where((t) => t.deletedAt.isNull() & t.accountId.equals(accountId)))
        .get();
    final expenseRows = await (_db.select(_db.expenses)
          ..where((t) => t.deletedAt.isNull() & t.accountId.equals(accountId)))
        .get();
    final transferRows = await (_db.select(_db.transfers)
          ..where((t) =>
              t.deletedAt.isNull() &
              (t.fromAccountId.equals(accountId) |
                  t.toAccountId.equals(accountId))))
        .get();

    final income = incomeRows.fold<double>(0, (s, r) => s + r.amount);
    final expense = expenseRows.fold<double>(0, (s, r) => s + r.amount);
    final transfersIn = transferRows
        .where((t) => t.toAccountId == accountId)
        .fold<double>(0, (s, r) => s + r.amount);
    final transfersOut = transferRows
        .where((t) => t.fromAccountId == accountId)
        .fold<double>(0, (s, r) => s + r.amount);

    final balance =
        account.openingBalance + income - expense + transfersIn - transfersOut;

    await (_db.update(_db.accounts)..where((t) => t.id.equals(accountId)))
        .write(AccountsCompanion(balance: Value(balance)));
  }

  /// Recomputes several accounts (e.g. both sides of a transfer). Null ids are
  /// skipped so callers can pass optional account links directly.
  Future<void> recomputeAll(Iterable<String?> accountIds) async {
    final seen = <String>{};
    for (final id in accountIds) {
      if (id != null && seen.add(id)) {
        await recompute(id);
      }
    }
  }
}
