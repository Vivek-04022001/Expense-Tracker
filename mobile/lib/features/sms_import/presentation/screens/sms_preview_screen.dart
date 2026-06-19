import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../../shared/utils/top_snack_bar.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../income/data/models/income_model.dart';
import '../../../profile/presentation/screens/_inner_app_bar.dart';
import '../providers/sms_import_provider.dart';

class SmsPreviewScreen extends ConsumerStatefulWidget {
  const SmsPreviewScreen({super.key});

  @override
  ConsumerState<SmsPreviewScreen> createState() => _SmsPreviewScreenState();
}

class _SmsPreviewScreenState extends ConsumerState<SmsPreviewScreen> {
  Future<void> _onImport() async {
    final notifier = ref.read(smsImportControllerProvider.notifier);
    await notifier.importSelected();
    if (!mounted) return;
    final imported = ref.read(smsImportControllerProvider).lastImportedCount;
    if (imported != null && imported > 0) {
      showSuccessTopBar(
        context,
        'Imported $imported transaction${imported == 1 ? '' : 's'}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsImportControllerProvider);
    final notifier = ref.read(smsImportControllerProvider.notifier);

    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: InnerAppBar(
        title: 'Review SMS',
        actions: [
          if (state.rows.isNotEmpty)
            TextButton(
              onPressed: () =>
                  notifier.selectAll(state.selectedCount != state.rows.length),
              child: Text(
                state.selectedCount == state.rows.length
                    ? 'Clear'
                    : 'Select all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary500,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, notifier),
      bottomNavigationBar: _buildImportBar(state, notifier),
    );
  }

  Widget _buildBody(SmsImportState state, SmsImportController notifier) {
    if (state.rows.isEmpty) {
      return _EmptyState(onAddMore: () => Navigator.of(context).pop());
    }

    final debits = <int>[];
    final credits = <int>[];
    for (var i = 0; i < state.rows.length; i++) {
      (state.rows[i].txn.isDebit ? debits : credits).add(i);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        if (state.parseError != null) ...[
          _InlineWarning(message: state.parseError!),
          const SizedBox(height: 12),
        ],
        if (debits.isNotEmpty) ...[
          _SectionHeader(label: 'EXPENSES', count: debits.length),
          const SizedBox(height: 8),
          ...debits.map(
            (i) => _DebitRow(
              index: i,
              row: state.rows[i],
              onToggle: () => notifier.toggleSelection(i),
              onChangeCategory: (cat) => notifier.updateCategory(i, cat),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (credits.isNotEmpty) ...[
          _SectionHeader(label: 'INCOME', count: credits.length),
          const SizedBox(height: 8),
          ...credits.map(
            (i) => _CreditRow(
              index: i,
              row: state.rows[i],
              onToggle: () => notifier.toggleSelection(i),
              onChangeType: (t) => notifier.updateIncomeType(i, t),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildImportBar(SmsImportState state, SmsImportController notifier) {
    if (state.rows.isEmpty) return null;
    final disabled = state.selectedCount == 0 || state.importing;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: disabled ? null : _onImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: state.importing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    state.selectedCount == 0
                        ? 'Select transactions to import'
                        : 'Import ${state.selectedCount} '
                              'transaction${state.selectedCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  const _Summary({
    required this.totalScanned,
    required this.parsed,
    required this.unparsed,
    required this.alreadyImported,
  });

  final int totalScanned;
  final int parsed;
  final int unparsed;
  final int alreadyImported;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SummaryCell(label: 'Scanned', value: '$totalScanned'),
              _Divider(),
              _SummaryCell(
                label: 'New',
                value: '$parsed',
                color: AppColors.success,
              ),
              _Divider(),
              _SummaryCell(
                label: 'Unknown',
                value: '$unparsed',
                color: context.textSecondary,
              ),
            ],
          ),
          if (alreadyImported > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$alreadyImported transaction${alreadyImported == 1 ? '' : 's'} '
                'already imported — hidden from this list.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color ?? context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: context.borderSubtle);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: context.bgSubtle,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Debit (expense) row ───────────────────────────────────────────────────────

class _DebitRow extends StatelessWidget {
  const _DebitRow({
    required this.index,
    required this.row,
    required this.onToggle,
    required this.onChangeCategory,
  });

  final int index;
  final SmsImportRow row;
  final VoidCallback onToggle;
  final void Function(ExpenseCategory) onChangeCategory;

  static final _fmt = DateFormat('d MMM, h:mm a');
  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final txn = row.txn;
    final cat = txn.suggestedCategory ?? ExpenseCategory.other;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: row.selected
              ? AppColors.primary500.withValues(alpha: 0.45)
              : context.borderSubtle,
          width: row.selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Checkbox(value: row.selected, onChanged: onToggle),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CategoryMapper.color(cat).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: PhosphorIcon(
                CategoryMapper.icon(cat),
                size: 18,
                color: CategoryMapper.color(cat),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.displayTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      txn.bank,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: TextStyle(color: context.textTertiary),
                    ),
                    Text(
                      _fmt.format(txn.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _CategoryChip(
                  category: cat,
                  onTap: () => _pickCategory(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '-${_money.format(txn.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCategory(BuildContext context) async {
    final selected = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategoryPicker(current: row.txn.suggestedCategory),
    );
    if (selected != null) onChangeCategory(selected);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});
  final ExpenseCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: CategoryMapper.color(category).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CategoryMapper.label(category),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CategoryMapper.color(category),
              ),
            ),
            const SizedBox(width: 4),
            PhosphorIcon(
              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              size: 10,
              color: CategoryMapper.color(category),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({this.current});
  final ExpenseCategory? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...ExpenseCategory.values.map((c) {
              final selected = c == current;
              return InkWell(
                onTap: () => Navigator.of(context).pop(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: CategoryMapper.color(
                            c,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            CategoryMapper.icon(c),
                            size: 16,
                            color: CategoryMapper.color(c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          CategoryMapper.label(c),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      if (selected)
                        PhosphorIcon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          size: 18,
                          color: AppColors.primary500,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Credit (income) row ───────────────────────────────────────────────────────

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.index,
    required this.row,
    required this.onToggle,
    required this.onChangeType,
  });

  final int index;
  final SmsImportRow row;
  final VoidCallback onToggle;
  final void Function(IncomeType) onChangeType;

  static final _fmt = DateFormat('d MMM, h:mm a');
  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final txn = row.txn;
    final type = txn.suggestedIncomeType ?? IncomeType.other;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: row.selected
              ? AppColors.success.withValues(alpha: 0.5)
              : context.borderSubtle,
          width: row.selected ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          _Checkbox(
            value: row.selected,
            onChanged: onToggle,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
                size: 18,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.displayTitle,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      txn.bank,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: TextStyle(color: context.textTertiary),
                    ),
                    Text(
                      _fmt.format(txn.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _IncomeTypeChip(type: type, onTap: () => _pickType(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${_money.format(txn.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickType(BuildContext context) async {
    final selected = await showModalBottomSheet<IncomeType>(
      context: context,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _IncomeTypePicker(current: row.txn.suggestedIncomeType),
    );
    if (selected != null) onChangeType(selected);
  }
}

class _IncomeTypeChip extends StatelessWidget {
  const _IncomeTypeChip({required this.type, required this.onTap});
  final IncomeType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.displayLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 4),
            PhosphorIcon(
              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              size: 10,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeTypePicker extends StatelessWidget {
  const _IncomeTypePicker({this.current});
  final IncomeType? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...IncomeType.values.map(
              (t) => InkWell(
                onTap: () => Navigator.of(context).pop(t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.displayLabel,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      if (t == current)
                        PhosphorIcon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                          size: 18,
                          color: AppColors.primary500,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Checkbox ──────────────────────────────────────────────────────────────────

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.value, required this.onChanged, this.color});

  final bool value;
  final VoidCallback onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary500;
    return GestureDetector(
      onTap: onChanged,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: value ? c : Colors.transparent,
          border: Border.all(
            color: value ? c : context.borderSubtle,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: value
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

// ── Empty + error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddMore});

  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.chatText(PhosphorIconsStyle.fill),
              size: 48,
              color: context.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions to review',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Go back and paste a bank SMS to import a transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAddMore,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Add SMS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.warning(PhosphorIconsStyle.fill),
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: context.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
