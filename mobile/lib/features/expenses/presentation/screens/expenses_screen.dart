import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/router/transitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_mapper.dart';
import '../../../../core/utils/expense_visual.dart';
import '../../../../shared/widgets/category_avatar.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../../../../features/income/presentation/screens/income_detail_screen.dart';
import '../../../../features/income/presentation/providers/income_provider.dart';
import '../../../../features/income/data/models/income_model.dart';
import '../widgets/month_summary_header.dart';
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
        label = 'Today · ${DateFormat('EEEE').format(d)}';
      } else if (_isSameDay(d, yesterday)) {
        label = 'Yesterday · ${DateFormat('EEEE').format(d)}';
      } else {
        label = DateFormat('MMM d, EEEE').format(d);
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
      useRootNavigator: true,
      backgroundColor: context.bgSurface,
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
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
  }

  void _shiftMonth(DateTime current, int delta) {
    final m = DateTime(current.year, current.month + delta);
    ref.read(selectedExpenseMonthProvider.notifier).setMonth(m.year, m.month);
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.bgSurface,
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
      backgroundColor: context.bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Tab bar
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.bgSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: context.bgSurface,
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
                labelColor: context.textPrimary,
                unselectedLabelColor: context.textSecondary,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Expenses'),
                  Tab(text: 'Income'),
                ],
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
                      MonthNavigator(
                        selected: selectedMonth,
                        onPrev: () => _shiftMonth(selectedMonth, -1),
                        onNext: () => _shiftMonth(selectedMonth, 1),
                        onTapLabel: () =>
                            _openMonthPicker(selectedMonth, months),
                      ),
                      expensesAsync.when(
                        loading: () => Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => Expanded(
                          child: Center(
                            child: Text(
                              'Failed to load expenses',
                              style: TextStyle(color: context.textSecondary),
                            ),
                          ),
                        ),
                        data: (all) {
                          final filtered = _filter(all);
                          final grouped = _group(filtered);
                          final dateKeys = grouped.keys.toList();
                          final totalExpenses = filtered.fold(
                            0.0,
                            (s, e) => s + e.amount,
                          );
                          // Income for the same month, for the summary strip.
                          final monthIncome = ref
                              .watch(incomesForMonthProvider(selectedMonth))
                              .valueOrNull;
                          final totalIncome = (monthIncome ?? []).fold(
                            0.0,
                            (s, e) => s + e.amount,
                          );
                          return Expanded(
                            child: Column(
                              children: [
                                MonthSummaryHeader(
                                  expense: totalExpenses,
                                  income: totalIncome,
                                ),
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
                      // SizedBox(height: 100),
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
          Text(
            'Transactions',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const Spacer(),
          _IconBtn(
            icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
            onTap: _toggleSearch,
            active: _searchOpen,
          ),
          SizedBox(width: 8),
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
                    decoration: BoxDecoration(
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
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
            PhosphorIcon(
              PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
              size: 18,
              color: context.textTertiary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search expenses…',
                  hintStyle: TextStyle(
                    color: context.textTertiary,
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
                    color: context.textTertiary,
                  ),
                ),
              ),
          ],
        ),
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
            style: TextStyle(fontSize: 13, color: context.textSecondary),
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
          Image.asset(
            'assets/illustrations/no_transaction.png',
            width: 380,
            height: 160,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(fontSize: 15, color: context.textSecondary),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  _fmtRupee(total),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, indent: 62, color: context.borderSubtle),
            itemBuilder: (_, i) => _EntryTile(expense: entries[i]),
          ),
        ),
      ],
    );
  }
}

// ── Entry tile ────────────────────────────────────────────────────────────────

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.expense});
  final ExpenseModel expense;

  void _openDetail(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      slideFadeRoute(ExpenseDetailScreen(expense: expense)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoryListNotifierProvider).valueOrNull ?? const [];
    final visual = ExpenseVisual.of(expense, categories);
    final color = visual.color;
    final label = visual.label;
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
            CategoryAvatar(
              icon: visual.icon,
              color: color,
              size: 38,
              iconSize: 18,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '$label · $timeStr · $paymentLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text(
              '-${_fmtRupee(expense.amount)}',
              style: TextStyle(
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
          color: active
              ? AppColors.primary500.withValues(alpha: 0.12)
              : context.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary500.withValues(alpha: 0.3)
                : context.borderSubtle,
          ),
        ),
        child: Center(
          child: PhosphorIcon(
            icon,
            size: 18,
            color: active ? AppColors.primary500 : context.textSecondary,
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
          Text(
            'Select Month',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 16),
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
                  color: isSelected
                      ? AppColors.primary500.withValues(alpha: 0.12)
                      : context.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary500.withValues(alpha: 0.4)
                        : context.borderSubtle,
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
                            : context.textPrimary,
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
              Text(
                'Filter by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              if (_selected.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selected.clear()),
                  child: Text(
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
          SizedBox(height: 16),
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
                    color: isActive ? AppColors.primary500 : context.bgSubtle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary500
                          : context.borderSubtle,
                    ),
                  ),
                  child: Text(
                    CategoryMapper.label(cat),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : context.textPrimary,
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
              onPressed: () {
                widget.onApply(_selected);
                Navigator.of(context, rootNavigator: true).pop();
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
  void _shiftMonth(DateTime current, int delta) {
    final m = DateTime(current.year, current.month + delta);
    ref.read(selectedIncomeMonthProvider.notifier).setMonth(m.year, m.month);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, List<IncomeModel>> _group(List<IncomeModel> incomes) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<IncomeModel>>{};
    for (final e in incomes) {
      final d = e.createdAt;
      String label;
      if (_isSameDay(d, today)) {
        label = 'Today · ${DateFormat('EEEE').format(d)}';
      } else if (_isSameDay(d, yesterday)) {
        label = 'Yesterday · ${DateFormat('EEEE').format(d)}';
      } else {
        label = DateFormat('MMM d, EEEE').format(d);
      }
      map.putIfAbsent(label, () => []).add(e);
    }
    return map;
  }

  void _openMonthPicker(DateTime selected, List<DateTime> months) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.bgSurface,
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
          Navigator.of(context, rootNavigator: true).pop();
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
        MonthNavigator(
          selected: selectedMonth,
          onPrev: () => _shiftMonth(selectedMonth, -1),
          onNext: () => _shiftMonth(selectedMonth, 1),
          onTapLabel: () => _openMonthPicker(selectedMonth, months),
        ),
        incomesAsync.when(
          loading: () =>
              Expanded(child: Center(child: CircularProgressIndicator())),
          error: (_, __) => Expanded(
            child: Center(
              child: Text(
                'Failed to load income',
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          ),
          data: (incomes) {
            final totalIncome = incomes.fold(0.0, (s, e) => s + e.amount);
            // Expense for the same month, for the summary strip.
            final monthExpense = ref
                .watch(expensesForMonthProvider(selectedMonth))
                .valueOrNull;
            final totalExpense = (monthExpense ?? []).fold(
              0.0,
              (s, e) => s + e.amount,
            );
            final grouped = _group(incomes);
            final dateKeys = grouped.keys.toList();
            return Expanded(
              child: Column(
                children: [
                  MonthSummaryHeader(
                    expense: totalExpense,
                    income: totalIncome,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          '${_fmtRupee(totalIncome)} across ${incomes.length} entries',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: incomes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/illustrations/no_transaction.png',
                                  width: 180,
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No income this month',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: dateKeys.length,
                            itemBuilder: (_, i) {
                              final key = dateKeys[i];
                              final entries = grouped[key]!;
                              final dayTotal = entries.fold(
                                0.0,
                                (s, e) => s + e.amount,
                              );
                              return _IncomeDaySection(
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
    );
  }
}

class _IncomeDaySection extends StatelessWidget {
  const _IncomeDaySection({
    required this.label,
    required this.total,
    required this.entries,
  });

  final String label;
  final double total;
  final List<IncomeModel> entries;

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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  '+${_fmtRupee(total)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [for (final e in entries) _IncomeTile(income: e)],
          ),
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
    Navigator.of(context, rootNavigator: true).push(
      slideFadeRoute(IncomeDetailScreen(income: income)),
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
          color: context.bgSurface,
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
            CategoryAvatar(
              icon: _icon(income.incomeType),
              color: AppColors.success,
              size: 38,
              iconSize: 18,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${income.incomeType.displayLabel} · $timeStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text(
              '+${_fmtRupee(income.amount)}',
              style: TextStyle(
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
