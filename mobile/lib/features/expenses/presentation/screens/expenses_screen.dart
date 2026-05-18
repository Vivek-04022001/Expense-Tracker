import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../../../../features/income/presentation/screens/income_detail_screen.dart';
import '../../../../features/income/presentation/providers/income_provider.dart';
import '../../../../features/income/data/models/income_model.dart';
import 'expense_detail_screen.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  bool _searchOpen = false;
  String _searchQuery = '';
  final Set<ExpenseCategory> _activeCategories = {};
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ExpenseModel> _filter(List<ExpenseModel> all) {
    return all.where((e) {
      if (_searchQuery.isNotEmpty &&
          !(e.description ?? '').toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) {
        return false;
      }
      if (_activeCategories.isNotEmpty &&
          !_activeCategories.contains(e.category)) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<ExpenseModel>> _group(List<ExpenseModel> expenses) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<ExpenseModel>>{};
    for (final e in expenses) {
      final d = e.createdAt;
      String label;
      if (_isSameDay(d, today)) {
        label = 'TODAY';
      } else if (_isSameDay(d, yesterday)) {
        label = 'YESTERDAY';
      } else {
        label = DateFormat('MMM d').format(d).toUpperCase();
      }
      map.putIfAbsent(label, () => []).add(e);
    }
    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _openMonthPicker(DateTime selected, List<DateTime> months) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MonthPickerSheet(
        selected: selected,
        months: months,
        onSelect: (m) {
          ref
              .read(selectedExpenseMonthProvider.notifier)
              .setMonth(m.year, m.month);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        activeCategories: Set.from(_activeCategories),
        onApply: (cats) => setState(() {
          _activeCategories
            ..clear()
            ..addAll(cats);
        }),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedExpenseMonthProvider);
    final expensesAsync = ref.watch(expenseListNotifierProvider);

    final months = List.generate(12, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - i);
    });

    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Tab bar
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.lightTextPrimary,
                unselectedLabelColor: AppColors.lightTextSecondary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [Tab(text: 'Expenses'), Tab(text: 'Income')],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Expenses tab ──────────────────────────────────────────
                  Column(
                    children: [
                      if (_searchOpen) _buildSearchBar(),
                      _buildMonthRow(selectedMonth, months),
                      expensesAsync.when(
                        loading: () => const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const Expanded(
                          child: Center(
                            child: Text(
                              'Failed to load expenses',
                              style: TextStyle(
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ),
                        data: (all) {
                          final filtered = _filter(all);
                          final grouped = _group(filtered);
                          final dateKeys = grouped.keys.toList();
                          final totalExpenses =
                              filtered.fold(0.0, (s, e) => s + e.amount);
                          return Expanded(
                            child: Column(
                              children: [
                                _buildSummaryRow(
                                  totalExpenses,
                                  filtered.length,
                                ),
                                Expanded(
                                  child: grouped.isEmpty
                                      ? _buildEmpty('No expenses found')
                                      : ListView.builder(
                                          padding: const EdgeInsets.only(
                                            bottom: 100,
                                          ),
                                          itemCount: dateKeys.length,
                                          itemBuilder: (_, i) {
                                            final key = dateKeys[i];
                                            final entries = grouped[key]!;
                                            final dayTotal = entries.fold(
                                              0.0,
                                              (s, e) => s + e.amount,
                                            );
                                            return _DaySection(
                                              label: key,
                                              total: dayTotal,
                                              entries: entries,
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // ── Income tab ────────────────────────────────────────────
                  _IncomeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text(
            'Transactions',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),
          _IconBtn(
            icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
            onTap: _toggleSearch,
            active: _searchOpen,
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              _IconBtn(
                icon: PhosphorIcons.funnelSimple(PhosphorIconsStyle.bold),
                onTap: _openFilterSheet,
                active: _activeCategories.isNotEmpty,
              ),
              if (_activeCategories.isNotEmpty)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderSubtle),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            PhosphorIcon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
              size: 18,
              color: AppColors.lightTextTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search expenses…',
                  hintStyle: TextStyle(
                    color: AppColors.lightTextTertiary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: PhosphorIcon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    size: 16,
                    color: AppColors.lightTextTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthRow(DateTime selected, List<DateTime> months) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openMonthPicker(selected, months),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightBorderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(selected),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PhosphorIcon(
                    PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                    size: 12,
                    color: AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(double total, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(
        children: [
          Text(
            '${_fmtRupee(total)} across $count expenses',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty([String label = 'No expenses found']) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIcons.receipt(PhosphorIconsStyle.light),
            size: 56,
            color: AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day section ───────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.label,
    required this.total,
    required this.entries,
  });

  final String label;
  final double total;
  final List<ExpenseModel> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextTertiary,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  _fmtRupee(total),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 62,
              color: AppColors.lightBorderSubtle,
            ),
            itemBuilder: (_, i) => _EntryTile(expense: entries[i]),
          ),
        ),
      ],
    );
  }
}

// ── Entry tile ────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.expense});
  final ExpenseModel expense;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(expense: expense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryMapper.color(expense.category);
    final label = CategoryMapper.label(expense.category);
    final timeStr = DateFormat('h:mm a').format(expense.createdAt);
    final paymentLabel = expense.paymentMethod.displayLabel;
    final name = expense.description ?? label;

    return GestureDetector(
      onTap: () => _openDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  CategoryMapper.icon(expense.category),
                  size: 18,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$label · $timeStr · $paymentLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '-${_fmtRupee(expense.amount)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon button ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });
  final PhosphorIconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? AppColors.primary100 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary500.withValues(alpha: 0.3)
                : AppColors.lightBorderSubtle,
          ),
        ),
        child: Center(
          child: PhosphorIcon(
            icon,
            size: 18,
            color:
                active ? AppColors.primary500 : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Month picker sheet ────────────────────────────────────────────────────────

class _MonthPickerSheet extends StatelessWidget {
  const _MonthPickerSheet({
    required this.selected,
    required this.months,
    required this.onSelect,
  });

  final DateTime selected;
  final List<DateTime> months;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...months.take(6).map((m) {
            final isSelected =
                m.month == selected.month && m.year == selected.year;
            return GestureDetector(
              onTap: () => onSelect(m),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary100 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary500.withValues(alpha: 0.4)
                        : AppColors.lightBorderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(m),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary500
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      PhosphorIcon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        size: 16,
                        color: AppColors.primary500,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.activeCategories, required this.onApply});
  final Set<ExpenseCategory> activeCategories;
  final void Function(Set<ExpenseCategory>) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<ExpenseCategory> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.activeCategories);
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
          Row(
            children: [
              const Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              if (_selected.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selected.clear()),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.values.map((cat) {
              final isActive = _selected.contains(cat);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isActive) {
                    _selected.remove(cat);
                  } else {
                    _selected.add(cat);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary500 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary500
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                  child: Text(
                    CategoryMapper.label(cat),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : AppColors.lightTextSecondary,
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
              onPressed: () {
                widget.onApply(_selected);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _selected.isEmpty ? 'Show All' : 'Apply Filter',
                style: const TextStyle(
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

// ── Income tab ────────────────────────────────────────────────────────────────

class _IncomeTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_IncomeTab> createState() => _IncomeTabState();
}

class _IncomeTabState extends ConsumerState<_IncomeTab> {
  void _openMonthPicker(DateTime selected, List<DateTime> months) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MonthPickerSheet(
        selected: selected,
        months: months,
        onSelect: (m) {
          ref
              .read(selectedIncomeMonthProvider.notifier)
              .setMonth(m.year, m.month);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedIncomeMonthProvider);
    final incomesAsync = ref.watch(incomeListNotifierProvider);
    final months = List.generate(12, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - i);
    });

    return Column(
      children: [
        // Month picker row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _openMonthPicker(selectedMonth, months),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightBorderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(selectedMonth),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      PhosphorIcon(
                        PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                        size: 12,
                        color: AppColors.lightTextSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        incomesAsync.when(
          loading: () => const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Expanded(
            child: Center(
              child: Text(
                'Failed to load income',
                style: TextStyle(color: AppColors.lightTextSecondary),
              ),
            ),
          ),
          data: (incomes) {
            if (incomes.isEmpty) {
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.trendUp(PhosphorIconsStyle.light),
                        size: 56,
                        color: AppColors.lightTextTertiary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No income this month',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final totalIncome =
                incomes.fold(0.0, (s, e) => s + e.amount);
            return Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          '${_fmtRupee(totalIncome)} across ${incomes.length} entries',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: incomes.length,
                      itemBuilder: (_, i) => _IncomeTile(income: incomes[i]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income});
  final IncomeModel income;

  static PhosphorIconData _icon(IncomeType t) => switch (t) {
        IncomeType.salary => PhosphorIcons.briefcase(),
        IncomeType.freelance => PhosphorIcons.laptop(),
        IncomeType.investment => PhosphorIcons.chartLineUp(),
        IncomeType.reward => PhosphorIcons.gift(),
        IncomeType.other => PhosphorIcons.dotsThree(),
      };

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncomeDetailScreen(income: income),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(income.createdAt);
    final name = income.description ?? income.incomeType.displayLabel;

    return GestureDetector(
      onTap: () => _openDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  _icon(income.incomeType),
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${income.incomeType.displayLabel} · $timeStr',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+${_fmtRupee(income.amount)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtRupee(double v) => '₹${_fmtNum(v.round())}';

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
