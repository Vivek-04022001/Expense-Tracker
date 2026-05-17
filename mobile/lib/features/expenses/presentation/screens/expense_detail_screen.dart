import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class ExpenseDetailArgs {
  const ExpenseDetailArgs({
    required this.name,
    required this.category,
    required this.amount,
    required this.time,
    required this.date,
    required this.payment,
    required this.isIncome,
    this.note,
    this.smsText,
  });

  final String name;
  final String category;
  final int amount;
  final String time;
  final DateTime date;
  final String payment;
  final bool isIncome;
  final String? note;
  final String? smsText;
}

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.args});

  final ExpenseDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(name: args.name, onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _HeroSection(args: args),
                    const SizedBox(height: 28),
                    _DetailsCard(args: args),
                    if (args.smsText != null) ...[
                      const SizedBox(height: 14),
                      _SmsCard(text: args.smsText!),
                    ],
                    const SizedBox(height: 28),
                    _ActionRow(args: args),
                    const SizedBox(height: 16),
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
  const _TopBar({required this.name, required this.onBack});

  final String name;
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
          const Spacer(),
          _NavBtn(
            icon: PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
            onTap: () => _showMoreMenu(context),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _MoreMenuSheet(),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lightBorderSubtle),
        ),
        child: Center(
          child: PhosphorIcon(icon, size: 18, color: AppColors.lightTextSecondary),
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.args});
  final ExpenseDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(args.category);

    return Column(
      children: [
        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: PhosphorIcon(
              _categoryIcon(args.category),
              size: 32,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Category chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            args.category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Name
        Text(
          args.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        // Amount
        Text(
          args.isIncome
              ? '+₹${_fmtNum(args.amount)}'
              : '−₹${_fmtNum(args.amount)}',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: args.isIncome ? AppColors.success : AppColors.danger,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        // Date + time
        Text(
          '${_dateLabel(args.date)} · ${args.time}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  String _dateLabel(DateTime d) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'Today';
    }
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${_shortMonth(d.month)} ${d.day}, ${d.year}';
  }

  String _shortMonth(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  PhosphorIconData _categoryIcon(String cat) => switch (cat) {
    'Food' => PhosphorIcons.forkKnife(PhosphorIconsStyle.fill),
    'Transport' => PhosphorIcons.car(PhosphorIconsStyle.fill),
    'Groceries' => PhosphorIcons.shoppingCart(PhosphorIconsStyle.fill),
    'Bills' => PhosphorIcons.receipt(PhosphorIconsStyle.fill),
    'Shopping' => PhosphorIcons.bag(PhosphorIconsStyle.fill),
    'Entertainment' => PhosphorIcons.ticket(PhosphorIconsStyle.fill),
    'Health' => PhosphorIcons.heartbeat(PhosphorIconsStyle.fill),
    'Income' => PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
    _ => PhosphorIcons.creditCard(PhosphorIconsStyle.fill),
  };

  Color _categoryColor(String cat) => switch (cat) {
    'Food' => AppColors.categoryFood,
    'Transport' => AppColors.categoryTransport,
    'Groceries' => AppColors.categoryHealth,
    'Bills' => AppColors.categoryBills,
    'Shopping' => AppColors.categoryShopping,
    'Entertainment' => AppColors.categoryEntertainment,
    'Health' => AppColors.categoryHealth,
    'Income' => AppColors.success,
    _ => AppColors.categoryOther,
  };
}

// ── Details card ──────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.args});
  final ExpenseDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      _DetailRow(label: 'Payment method', value: args.payment),
      _DetailRow(
        label: 'Date',
        value: '${_shortMonth(args.date.month)} ${args.date.day}, ${args.date.year}',
      ),
      if (args.note != null) _DetailRow(label: 'Note', value: args.note!),
      _DetailRow(
        label: 'Source',
        value: args.smsText != null ? 'Auto-imported from SMS' : 'Manually added',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.lightBorderSubtle),
        itemBuilder: (_, i) => _DetailRowTile(row: rows[i]),
      ),
    );
  }

  String _shortMonth(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
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
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SMS card ──────────────────────────────────────────────────────────────────

class _SmsCard extends StatelessWidget {
  const _SmsCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.chatText(PhosphorIconsStyle.fill),
                size: 14,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 6),
              const Text(
                'PARSED FROM SMS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.args});
  final ExpenseDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            icon: PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
            label: 'Recategorize',
            onTap: () => _showRecategorize(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionBtn(
            icon: PhosphorIcons.trash(PhosphorIconsStyle.regular),
            label: 'Delete',
            isDestructive: true,
            onTap: () => _confirmDelete(context),
          ),
        ),
      ],
    );
  }

  void _showRecategorize(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RecategorizeSheet(current: args.category),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete expense?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'This will permanently remove the "${args.name}" expense.',
          style: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? AppColors.danger.withValues(alpha: 0.25)
                : AppColors.lightBorderSubtle,
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
              color: isDestructive ? AppColors.danger : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? AppColors.danger : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── More menu sheet ───────────────────────────────────────────────────────────

class _MoreMenuSheet extends StatelessWidget {
  const _MoreMenuSheet();

  @override
  Widget build(BuildContext context) {
    final items = [
      (PhosphorIcons.pencil(PhosphorIconsStyle.regular), 'Edit expense', false),
      (PhosphorIcons.share(PhosphorIconsStyle.regular), 'Share', false),
      (PhosphorIcons.flag(PhosphorIconsStyle.regular), 'Report issue', false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...items.map((item) => GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  PhosphorIcon(item.$1, size: 20, color: AppColors.lightTextSecondary),
                  const SizedBox(width: 14),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: item.$3 ? AppColors.danger : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Recategorize sheet ────────────────────────────────────────────────────────

const _allCategories = [
  'Food', 'Transport', 'Groceries', 'Bills', 'Shopping',
  'Entertainment', 'Health', 'Income',
];

class _RecategorizeSheet extends StatefulWidget {
  const _RecategorizeSheet({required this.current});
  final String current;

  @override
  State<_RecategorizeSheet> createState() => _RecategorizeSheetState();
}

class _RecategorizeSheetState extends State<_RecategorizeSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recategorize',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCategories.map((cat) {
              final isActive = cat == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary500 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary500 : AppColors.lightBorderSubtle,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
