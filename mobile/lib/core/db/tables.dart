import 'package:drift/drift.dart';

/// Sync state for a locally-stored row.
/// - [synced]  : matches the server (or came from the server).
/// - [pending] : changed locally, waiting to be pushed.
/// - [failed]  : a push attempt failed; will be retried.
class SyncStatus {
  static const synced = 'synced';
  static const pending = 'pending';
  static const failed = 'failed';
}

/// Columns every syncable table shares. `updatedAt` drives Last-Write-Wins and
/// the delta pull; `deletedAt` is a local soft delete; `syncStatus` tells the UI
/// whether a row is still waiting to reach the server.
mixin _SyncColumns on Table {
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant(SyncStatus.synced))();
}

@DataClassName('AccountRow')
class Accounts extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('other'))();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // 'expense' | 'income'
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get key => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get paymentMethod => text().withDefault(const Constant('other'))();
  TextColumn get description => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('IncomeRow')
class Incomes extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get incomeType => text().withDefault(const Constant('other'))();
  TextColumn get description => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get categoryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransferRow')
class Transfers extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get fromAccountId => text()();
  TextColumn get toAccountId => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetRow')
class Budgets extends Table with _SyncColumns {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  RealColumn get limitAmount => real()();
  TextColumn get category => text()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Durable queue of local mutations awaiting a push to the server (the "outbox"
/// pattern). One row per change; the sync engine drains it in insertion order.
@DataClassName('OutboxRow')
class Outbox extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get entity => text()(); // account | category | expense | ...
  TextColumn get op => text()(); // 'upsert' | 'delete'
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON-encoded data for upserts
  DateTimeColumn get updatedAt => dateTime()(); // the change's logical timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Single-row table holding sync bookkeeping (the pull cursor).
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPulledAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
