import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/presentation/providers/expense_provider.dart';
import '../../../income/data/models/income_model.dart';
import '../../../income/presentation/providers/income_provider.dart';
import '../../data/models/parsed_transaction.dart';
import '../../data/parsers/bank_sms_parser.dart';
import '../../services/sms_datasource.dart';
import '../../services/sms_import_service.dart';
import '../../services/sms_permission_handler.dart';

part 'sms_import_provider.g.dart';

@riverpod
SmsImportService smsImportService(SmsImportServiceRef ref) {
  return SmsImportService(
    permissions: SmsPermissionHandler(),
    datasource: SmsDatasource(),
    parser: BankSmsParser(),
  );
}

/// One row in the preview list — wraps the parsed txn with editable selection
/// and (eventually) editable category/income-type.
@immutable
class SmsImportRow {
  const SmsImportRow({
    required this.txn,
    required this.selected,
  });

  final ParsedTransaction txn;
  final bool selected;

  SmsImportRow copyWith({ParsedTransaction? txn, bool? selected}) =>
      SmsImportRow(
        txn: txn ?? this.txn,
        selected: selected ?? this.selected,
      );
}

@immutable
class SmsImportState {
  const SmsImportState({
    required this.scanning,
    required this.importing,
    required this.rows,
    required this.totalScanned,
    required this.unparsedCount,
    required this.alreadyImportedCount,
    this.error,
    this.permanentlyDenied = false,
    this.lastImportedCount,
  });

  final bool scanning;
  final bool importing;
  final List<SmsImportRow> rows;
  final int totalScanned;
  final int unparsedCount;
  /// Transactions hidden because they were already imported in a prior scan.
  final int alreadyImportedCount;
  final String? error;
  final bool permanentlyDenied;
  final int? lastImportedCount;

  factory SmsImportState.initial() => const SmsImportState(
        scanning: false,
        importing: false,
        rows: [],
        totalScanned: 0,
        unparsedCount: 0,
        alreadyImportedCount: 0,
      );

  int get selectedCount => rows.where((r) => r.selected).length;
  int get debitCount => rows.where((r) => r.txn.isDebit).length;
  int get creditCount => rows.where((r) => r.txn.isCredit).length;

  SmsImportState copyWith({
    bool? scanning,
    bool? importing,
    List<SmsImportRow>? rows,
    int? totalScanned,
    int? unparsedCount,
    int? alreadyImportedCount,
    String? error,
    bool clearError = false,
    bool? permanentlyDenied,
    int? lastImportedCount,
    bool clearLastImported = false,
  }) =>
      SmsImportState(
        scanning: scanning ?? this.scanning,
        importing: importing ?? this.importing,
        rows: rows ?? this.rows,
        totalScanned: totalScanned ?? this.totalScanned,
        unparsedCount: unparsedCount ?? this.unparsedCount,
        alreadyImportedCount:
            alreadyImportedCount ?? this.alreadyImportedCount,
        error: clearError ? null : (error ?? this.error),
        permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
        lastImportedCount: clearLastImported
            ? null
            : (lastImportedCount ?? this.lastImportedCount),
      );
}

@riverpod
class SmsImportController extends _$SmsImportController {
  @override
  SmsImportState build() => SmsImportState.initial();

  Future<void> scan() async {
    state = state.copyWith(
      scanning: true,
      clearError: true,
      clearLastImported: true,
      permanentlyDenied: false,
    );
    try {
      final result = await ref.read(smsImportServiceProvider).scan();
      state = state.copyWith(
        scanning: false,
        rows: result.transactions
            .map((t) => SmsImportRow(txn: t, selected: true))
            .toList(),
        totalScanned: result.totalScanned,
        unparsedCount: result.unparsedCount,
        alreadyImportedCount: result.alreadyImportedCount,
      );
    } on SmsPermissionDenied catch (e) {
      state = state.copyWith(
        scanning: false,
        error: e.permanentlyDenied
            ? 'SMS access is blocked. Enable it from app settings.'
            : 'SMS access is required to scan transactions.',
        permanentlyDenied: e.permanentlyDenied,
      );
    } catch (e) {
      state = state.copyWith(
        scanning: false,
        error: 'Could not scan SMS: $e',
      );
    }
  }

  void toggleSelection(int index) {
    if (index < 0 || index >= state.rows.length) return;
    final next = [...state.rows];
    next[index] = next[index].copyWith(selected: !next[index].selected);
    state = state.copyWith(rows: next);
  }

  void selectAll(bool value) {
    state = state.copyWith(
      rows: state.rows.map((r) => r.copyWith(selected: value)).toList(),
    );
  }

  void updateCategory(int index, ExpenseCategory category) {
    if (index < 0 || index >= state.rows.length) return;
    final row = state.rows[index];
    if (!row.txn.isDebit) return;
    final next = [...state.rows];
    next[index] = row.copyWith(
      txn: row.txn.copyWith(suggestedCategory: category),
    );
    state = state.copyWith(rows: next);
  }

  void updateIncomeType(int index, IncomeType type) {
    if (index < 0 || index >= state.rows.length) return;
    final row = state.rows[index];
    if (!row.txn.isCredit) return;
    final next = [...state.rows];
    next[index] = row.copyWith(
      txn: row.txn.copyWith(suggestedIncomeType: type),
    );
    state = state.copyWith(rows: next);
  }

  Future<void> importSelected() async {
    final toImport = state.rows.where((r) => r.selected).toList();
    if (toImport.isEmpty) return;

    state = state.copyWith(importing: true, clearError: true);

    final expenses = ref.read(expenseListNotifierProvider.notifier);
    final incomes = ref.read(incomeListNotifierProvider.notifier);

    var ok = 0;
    final failed = <SmsImportRow>[];
    final importedFingerprints = <String>[];

    for (final row in toImport) {
      final txn = row.txn;
      try {
        if (txn.isDebit) {
          await expenses.create(
            amount: txn.amount,
            description: txn.merchant ?? '${txn.bank} debit',
            category: txn.suggestedCategory,
            paymentMethod: txn.paymentMethod,
          );
        } else {
          await incomes.create(
            amount: txn.amount,
            incomeType: txn.suggestedIncomeType,
            description: txn.merchant ?? '${txn.bank} credit',
          );
        }
        ok++;
        importedFingerprints.add(txn.fingerprint);
      } catch (_) {
        failed.add(row);
      }
    }

    // Persist fingerprints so they're filtered out on the next scan.
    if (importedFingerprints.isNotEmpty) {
      await ref
          .read(smsImportServiceProvider)
          .recordImported(importedFingerprints);
    }

    // Remove successfully-imported rows; keep failed ones with selection cleared.
    final remaining = state.rows
        .where((r) => !r.selected || failed.contains(r))
        .map((r) => failed.contains(r) ? r.copyWith(selected: false) : r)
        .toList();

    state = state.copyWith(
      importing: false,
      rows: remaining,
      lastImportedCount: ok,
      error: failed.isEmpty
          ? null
          : '${failed.length} could not be imported.',
    );
  }

  Future<void> openPermissionSettings() => SmsPermissionHandler().openSettings();
}
