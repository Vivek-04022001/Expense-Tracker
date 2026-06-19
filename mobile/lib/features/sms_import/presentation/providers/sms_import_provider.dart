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

part 'sms_import_provider.g.dart';

@riverpod
SmsImportService smsImportService(SmsImportServiceRef ref) {
  return SmsImportService(
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
    required this.importing,
    required this.rows,
    this.parseError,
    this.lastImportedCount,
  });

  final bool importing;
  final List<SmsImportRow> rows;
  final String? parseError;
  final int? lastImportedCount;

  factory SmsImportState.initial() => const SmsImportState(
        importing: false,
        rows: [],
      );

  int get selectedCount => rows.where((r) => r.selected).length;
  int get debitCount => rows.where((r) => r.txn.isDebit).length;
  int get creditCount => rows.where((r) => r.txn.isCredit).length;

  SmsImportState copyWith({
    bool? importing,
    List<SmsImportRow>? rows,
    String? parseError,
    bool clearParseError = false,
    int? lastImportedCount,
    bool clearLastImported = false,
  }) =>
      SmsImportState(
        importing: importing ?? this.importing,
        rows: rows ?? this.rows,
        parseError:
            clearParseError ? null : (parseError ?? this.parseError),
        lastImportedCount: clearLastImported
            ? null
            : (lastImportedCount ?? this.lastImportedCount),
      );
}

@riverpod
class SmsImportController extends _$SmsImportController {
  @override
  SmsImportState build() => SmsImportState.initial();

  /// Parses a pasted bank SMS and, if successful, adds it to the pending list.
  /// Returns true if a transaction was found, false if the text could not be
  /// parsed.
  Future<bool> parsePasted(String text) async {
    if (text.trim().isEmpty) return false;

    state = state.copyWith(clearParseError: true);

    final txn = ref.read(smsImportServiceProvider).parsePasted(text);
    if (txn == null) {
      state = state.copyWith(
        parseError:
            'Could not parse this SMS. Make sure it is a bank transaction message.',
      );
      return false;
    }

    // Skip if the fingerprint is already in the list this session.
    if (state.rows.any((r) => r.txn.fingerprint == txn.fingerprint)) {
      state = state.copyWith(
        parseError: 'This transaction is already in the list.',
      );
      return false;
    }

    // Skip if previously imported.
    final imported =
        await ref.read(smsImportServiceProvider).loadImportedFingerprints();
    if (imported.contains(txn.fingerprint)) {
      state = state.copyWith(
        parseError: 'This transaction was already imported previously.',
      );
      return false;
    }

    state = state.copyWith(
      rows: [...state.rows, SmsImportRow(txn: txn, selected: true)],
    );
    return true;
  }

  void clearRows() {
    state = SmsImportState.initial();
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

    state = state.copyWith(importing: true, clearParseError: true);

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

    if (importedFingerprints.isNotEmpty) {
      await ref
          .read(smsImportServiceProvider)
          .recordImported(importedFingerprints);
    }

    final remaining = state.rows
        .where((r) => !r.selected || failed.contains(r))
        .map((r) => failed.contains(r) ? r.copyWith(selected: false) : r)
        .toList();

    state = state.copyWith(
      importing: false,
      rows: remaining,
      lastImportedCount: ok,
      parseError: failed.isEmpty ? null : '${failed.length} could not be imported.',
    );
  }
}
