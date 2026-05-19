import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/income_model.dart';
import '../providers/income_provider.dart';

class IncomeDetailScreen extends ConsumerWidget {
  const IncomeDetailScreen({super.key, required this.income});

  final IncomeModel income;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    SizedBox(height: 24),
                    _HeroSection(income: income),
                    SizedBox(height: 28),
                    _DetailsCard(income: income),
                    SizedBox(height: 28),
                    _ActionRow(income: income),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _NavBtn(
            icon: PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
            onTap: onBack,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final PhosphorIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Center(
          child: PhosphorIcon(icon, size: 18, color: context.textSecondary),
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.income});
  final IncomeModel income;

  static PhosphorIconData _icon(IncomeType t) => switch (t) {
        IncomeType.salary => PhosphorIcons.briefcase(PhosphorIconsStyle.regular),
        IncomeType.freelance => PhosphorIcons.laptop(PhosphorIconsStyle.regular),
        IncomeType.investment =>
          PhosphorIcons.chartLineUp(PhosphorIconsStyle.regular),
        IncomeType.reward => PhosphorIcons.gift(PhosphorIconsStyle.regular),
        IncomeType.other => PhosphorIcons.dotsThree(PhosphorIconsStyle.regular),
      };

  @override
  Widget build(BuildContext context) {
    final name = income.description ?? income.incomeType.displayLabel;
    final timeStr = DateFormat('h:mm a').format(income.createdAt);
    final dateLabel = _formatDate(income.createdAt);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: PhosphorIcon(
              _icon(income.incomeType),
              size: 32,
              color: AppColors.success,
            ),
          ),
        ),
        SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            income.incomeType.displayLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '+₹${_fmtNum(income.amount.round())}',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '$dateLabel · $timeStr',
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'Today';
    }
    if (d.year == yesterday.year &&
        d.month == yesterday.month &&
        d.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(d);
  }
}

// ── Details card ──────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.income});
  final IncomeModel income;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _DetailRow(
        label: 'Income type',
        value: income.incomeType.displayLabel,
      ),
      _DetailRow(
        label: 'Date',
        value: DateFormat('MMM d, yyyy').format(income.createdAt),
      ),
      if (income.description != null && income.description!.isNotEmpty)
        _DetailRow(label: 'Note', value: income.description!),
      const _DetailRow(label: 'Source', value: 'Manually added'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: context.borderSubtle),
        itemBuilder: (_, i) => _DetailRowTile(row: rows[i]),
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
}

class _DetailRowTile extends StatelessWidget {
  const _DetailRowTile({required this.row});
  final _DetailRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            row.label,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.income});
  final IncomeModel income;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
            label: 'Change type',
            onTap: () => _showChangeType(context, ref),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ActionBtn(
            icon: PhosphorIcons.trash(PhosphorIconsStyle.regular),
            label: 'Delete',
            isDestructive: true,
            onTap: () => _confirmDelete(context, ref),
          ),
        ),
      ],
    );
  }

  void _showChangeType(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChangeTypeSheet(
        current: income.incomeType,
        onSave: (newType) async {
          await ref
              .read(incomeListNotifierProvider.notifier)
              .edit(income.id, incomeType: newType);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete income?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'This will permanently remove "${income.description ?? income.incomeType.displayLabel}".',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(incomeListNotifierProvider.notifier)
                  .delete(income.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? AppColors.danger.withValues(alpha: 0.25)
                : context.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              icon,
              size: 16,
              color: isDestructive
                  ? AppColors.danger
                  : context.textSecondary,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive
                    ? AppColors.danger
                    : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Change type sheet ─────────────────────────────────────────────────────────

class _ChangeTypeSheet extends StatefulWidget {
  const _ChangeTypeSheet({required this.current, required this.onSave});
  final IncomeType current;
  final Future<void> Function(IncomeType) onSave;

  @override
  State<_ChangeTypeSheet> createState() => _ChangeTypeSheetState();
}

class _ChangeTypeSheetState extends State<_ChangeTypeSheet> {
  late IncomeType _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change income type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IncomeType.values.map((type) {
              final isActive = type == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.success
                          : context.borderSubtle,
                    ),
                  ),
                  child: Text(
                    type.displayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : context.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      await widget.onSave(_selected);
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtNum(int v) {
  if (v < 1000) return v.toString();
  final s = v.toString();
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (var i = 0; i < rest.length; i++) {
    if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '$buf,$last3';
}
