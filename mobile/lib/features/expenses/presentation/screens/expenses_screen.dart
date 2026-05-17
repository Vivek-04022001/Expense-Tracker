import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import 'expense_detail_screen.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _Entry {
  const _Entry({
    required this.name,
    required this.category,
    required this.time,
    required this.date,
    required this.payment,
    required this.amount,
    this.isIncome = false,
  });

  final String name;
  final String category;
  final String time;
  final DateTime date;
  final String payment;
  final int amount;
  final bool isIncome;
}

// ── Demo data ─────────────────────────────────────────────────────────────────

final _allEntries = <_Entry>[
  // May 17 (today)
  _Entry(
    name: 'Swiggy',
    category: 'Food',
    time: '7:12 PM',
    date: DateTime(2026, 5, 17),
    payment: 'UPI',
    amount: 342,
  ),
  _Entry(
    name: 'Uber',
    category: 'Transport',
    time: '5:44 PM',
    date: DateTime(2026, 5, 17),
    payment: 'UPI',
    amount: 218,
  ),
  _Entry(
    name: 'Blue Tokai',
    category: 'Food',
    time: '11:20 AM',
    date: DateTime(2026, 5, 17),
    payment: 'Card',
    amount: 480,
  ),
  _Entry(
    name: 'Namma Metro',
    category: 'Transport',
    time: '9:08 AM',
    date: DateTime(2026, 5, 17),
    payment: 'UPI',
    amount: 90,
  ),
  // May 16
  _Entry(
    name: 'BigBasket',
    category: 'Groceries',
    time: '8:55 PM',
    date: DateTime(2026, 5, 16),
    payment: 'UPI',
    amount: 2840,
  ),
  _Entry(
    name: 'Zomato',
    category: 'Food',
    time: '2:10 PM',
    date: DateTime(2026, 5, 16),
    payment: 'UPI',
    amount: 612,
  ),
  _Entry(
    name: 'Airtel Postpaid',
    category: 'Bills',
    time: '11:00 AM',
    date: DateTime(2026, 5, 16),
    payment: 'UPI',
    amount: 999,
  ),
  // May 15
  _Entry(
    name: 'Amazon',
    category: 'Shopping',
    time: '9:22 PM',
    date: DateTime(2026, 5, 15),
    payment: 'Card',
    amount: 1899,
  ),
  _Entry(
    name: 'BookMyShow',
    category: 'Entertainment',
    time: '6:10 PM',
    date: DateTime(2026, 5, 15),
    payment: 'UPI',
    amount: 540,
  ),
  _Entry(
    name: 'Apollo Pharmacy',
    category: 'Health',
    time: '11:45 AM',
    date: DateTime(2026, 5, 15),
    payment: 'Cash',
    amount: 340,
  ),
  // May 14
  _Entry(
    name: 'Rent - K. Sharma',
    category: 'Bills',
    time: '9:00 AM',
    date: DateTime(2026, 5, 14),
    payment: 'UPI',
    amount: 22000,
  ),
  _Entry(
    name: 'Salary - Acct 4521',
    category: 'Income',
    time: '7:00 AM',
    date: DateTime(2026, 5, 14),
    payment: 'UPI',
    amount: 125000,
    isIncome: true,
  ),
  // May 13
  _Entry(
    name: 'Rapido',
    category: 'Transport',
    time: '10:20 PM',
    date: DateTime(2026, 5, 13),
    payment: 'UPI',
    amount: 58,
  ),
  _Entry(
    name: 'Starbucks',
    category: 'Food',
    time: '4:30 PM',
    date: DateTime(2026, 5, 13),
    payment: 'Card',
    amount: 485,
  ),
  _Entry(
    name: 'Netflix',
    category: 'Entertainment',
    time: '12:00 PM',
    date: DateTime(2026, 5, 13),
    payment: 'Card',
    amount: 649,
  ),
  // May 10
  _Entry(
    name: 'DMart',
    category: 'Groceries',
    time: '6:30 PM',
    date: DateTime(2026, 5, 10),
    payment: 'UPI',
    amount: 3120,
  ),
  _Entry(
    name: 'Ola',
    category: 'Transport',
    time: '9:15 AM',
    date: DateTime(2026, 5, 10),
    payment: 'UPI',
    amount: 143,
  ),
  // May 8
  _Entry(
    name: 'Myntra',
    category: 'Shopping',
    time: '3:45 PM',
    date: DateTime(2026, 5, 8),
    payment: 'Card',
    amount: 2199,
  ),
  _Entry(
    name: 'Cult Fit',
    category: 'Health',
    time: '7:00 AM',
    date: DateTime(2026, 5, 8),
    payment: 'UPI',
    amount: 999,
  ),
  // May 5
  _Entry(
    name: 'BESCOM',
    category: 'Bills',
    time: '10:00 AM',
    date: DateTime(2026, 5, 5),
    payment: 'UPI',
    amount: 1840,
  ),
  _Entry(
    name: 'Blinkit',
    category: 'Groceries',
    time: '8:20 PM',
    date: DateTime(2026, 5, 5),
    payment: 'UPI',
    amount: 760,
  ),

  // April 2026
  _Entry(
    name: 'Swiggy',
    category: 'Food',
    time: '8:30 PM',
    date: DateTime(2026, 4, 30),
    payment: 'UPI',
    amount: 289,
  ),
  _Entry(
    name: 'Uber',
    category: 'Transport',
    time: '6:15 PM',
    date: DateTime(2026, 4, 30),
    payment: 'UPI',
    amount: 175,
  ),
  _Entry(
    name: 'BigBasket',
    category: 'Groceries',
    time: '11:00 AM',
    date: DateTime(2026, 4, 28),
    payment: 'UPI',
    amount: 3240,
  ),
  _Entry(
    name: 'Amazon',
    category: 'Shopping',
    time: '3:00 PM',
    date: DateTime(2026, 4, 25),
    payment: 'Card',
    amount: 4599,
  ),
  _Entry(
    name: 'Salary - Acct 4521',
    category: 'Income',
    time: '7:00 AM',
    date: DateTime(2026, 4, 14),
    payment: 'UPI',
    amount: 125000,
    isIncome: true,
  ),
  _Entry(
    name: 'Rent - K. Sharma',
    category: 'Bills',
    time: '9:00 AM',
    date: DateTime(2026, 4, 14),
    payment: 'UPI',
    amount: 22000,
  ),
  _Entry(
    name: 'Zomato',
    category: 'Food',
    time: '1:20 PM',
    date: DateTime(2026, 4, 12),
    payment: 'UPI',
    amount: 410,
  ),
  _Entry(
    name: 'Netflix',
    category: 'Entertainment',
    time: '12:00 PM',
    date: DateTime(2026, 4, 10),
    payment: 'Card',
    amount: 649,
  ),
  _Entry(
    name: 'Apollo Pharmacy',
    category: 'Health',
    time: '10:30 AM',
    date: DateTime(2026, 4, 8),
    payment: 'Cash',
    amount: 560,
  ),
  _Entry(
    name: 'BookMyShow',
    category: 'Entertainment',
    time: '7:00 PM',
    date: DateTime(2026, 4, 5),
    payment: 'UPI',
    amount: 800,
  ),
  _Entry(
    name: 'BESCOM',
    category: 'Bills',
    time: '10:00 AM',
    date: DateTime(2026, 4, 3),
    payment: 'UPI',
    amount: 1620,
  ),

  // March 2026
  _Entry(
    name: 'Salary - Acct 4521',
    category: 'Income',
    time: '7:00 AM',
    date: DateTime(2026, 3, 14),
    payment: 'UPI',
    amount: 125000,
    isIncome: true,
  ),
  _Entry(
    name: 'Rent - K. Sharma',
    category: 'Bills',
    time: '9:00 AM',
    date: DateTime(2026, 3, 14),
    payment: 'UPI',
    amount: 22000,
  ),
  _Entry(
    name: 'Swiggy',
    category: 'Food',
    time: '8:00 PM',
    date: DateTime(2026, 3, 20),
    payment: 'UPI',
    amount: 312,
  ),
  _Entry(
    name: 'BigBasket',
    category: 'Groceries',
    time: '5:00 PM',
    date: DateTime(2026, 3, 18),
    payment: 'UPI',
    amount: 2890,
  ),
  _Entry(
    name: 'Myntra',
    category: 'Shopping',
    time: '2:30 PM',
    date: DateTime(2026, 3, 10),
    payment: 'Card',
    amount: 1799,
  ),
  _Entry(
    name: 'Cult Fit',
    category: 'Health',
    time: '7:00 AM',
    date: DateTime(2026, 3, 5),
    payment: 'UPI',
    amount: 999,
  ),
  _Entry(
    name: 'BESCOM',
    category: 'Bills',
    time: '10:00 AM',
    date: DateTime(2026, 3, 3),
    payment: 'UPI',
    amount: 1540,
  ),
];

const _allCategories = [
  'Food',
  'Transport',
  'Groceries',
  'Bills',
  'Shopping',
  'Entertainment',
  'Health',
  'Income',
];

const _months = [
  _Month(2026, 5, 'May 2026'),
  _Month(2026, 4, 'April 2026'),
  _Month(2026, 3, 'March 2026'),
];

class _Month {
  const _Month(this.year, this.month, this.label);
  final int year;
  final int month;
  final String label;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  _Month _selectedMonth = _months.first;
  bool _searchOpen = false;
  String _searchQuery = '';
  final Set<String> _activeCategories = {};
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Entry> get _filtered {
    return _allEntries.where((e) {
      if (e.date.year != _selectedMonth.year ||
          e.date.month != _selectedMonth.month) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !e.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_activeCategories.isNotEmpty &&
          !_activeCategories.contains(e.category)) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<_Entry>> get _grouped {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final map = <String, List<_Entry>>{};
    for (final e in _filtered) {
      String label;
      if (_isSameDay(e.date, today)) {
        label = 'TODAY';
      } else if (_isSameDay(e.date, yesterday)) {
        label = 'YESTERDAY';
      } else {
        label = '${_shortMonth(e.date.month).toUpperCase()} ${e.date.day}';
      }
      map.putIfAbsent(label, () => []).add(e);
    }
    return map;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _shortMonth(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  int get _totalExpenses {
    return _filtered.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);
  }

  int get _expenseCount => _filtered.where((e) => !e.isIncome).length;

  void _openMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MonthPickerSheet(
        selected: _selectedMonth,
        months: _months,
        onSelect: (m) {
          setState(() => _selectedMonth = m);
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
        onApply: (cats) {
          setState(() {
            _activeCategories
              ..clear()
              ..addAll(cats);
          });
        },
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
    final grouped = _grouped;
    final dateKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.lightBgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_searchOpen) _buildSearchBar(),
            _buildMonthRow(),
            _buildSummaryRow(),
            Expanded(
              child: grouped.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: dateKeys.length,
                      itemBuilder: (_, i) {
                        final key = dateKeys[i];
                        final entries = grouped[key]!;
                        final dayTotal = entries
                            .where((e) => !e.isIncome)
                            .fold(0, (s, e) => s + e.amount);
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text(
            'Expenses',
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

  Widget _buildMonthRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openMonthPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightBorderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedMonth.label,
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

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(
        children: [
          Text(
            '${_fmtRupee(_totalExpenses)} across $_expenseCount expenses',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
          const Text(
            'No expenses found',
            style: TextStyle(fontSize: 15, color: AppColors.lightTextSecondary),
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
  final int total;
  final List<_Entry> entries;

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
            itemBuilder: (_, i) => _EntryTile(entry: entries[i]),
          ),
        ),
      ],
    );
  }
}

// ── Entry tile ────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final _Entry entry;

  static const _smsTemplates = {
    'Food': 'Rs {amount}.00 debited from a/c via UPI on {date}. Ref: {ref}',
    'Transport':
        'Rs {amount}.00 debited from a/c via UPI on {date}. Ref: {ref}',
    'Groceries':
        'Rs {amount}.00 debited from a/c via UPI on {date}. Ref: {ref}',
    'Bills': 'Rs {amount}.00 debited from a/c via NEFT on {date}. Ref: {ref}',
  };

  void _openDetail(BuildContext context) {
    final hasSms = _smsTemplates.containsKey(entry.category);
    final smsText = hasSms
        ? 'Rs ${entry.amount}.00 debited from a/c via ${entry.payment} on '
              '${entry.date.day.toString().padLeft(2, '0')}-'
              '${entry.date.month.toString().padLeft(2, '0')}. '
              'Ref: ${entry.date.millisecondsSinceEpoch % 999999999}'
        : null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          args: ExpenseDetailArgs(
            name: entry.name,
            category: entry.category,
            amount: entry.amount,
            time: entry.time,
            date: entry.date,
            payment: entry.payment,
            isIncome: entry.isIncome,
            note: entry.category == 'Food' ? 'Biryani + Coke' : null,
            smsText: smsText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(entry.category);
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
                  _categoryIcon(entry.category),
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _AutoBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.category} · ${entry.time} · ${entry.payment}',
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
              entry.isIncome
                  ? '+${_fmtRupee(entry.amount)}'
                  : '-${_fmtRupee(entry.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: entry.isIncome ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

// ── AUTO badge ────────────────────────────────────────────────────────────────

class _AutoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'AUTO',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.primary500,
          letterSpacing: 0.4,
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
            color: active ? AppColors.primary500 : AppColors.lightTextSecondary,
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

  final _Month selected;
  final List<_Month> months;
  final void Function(_Month) onSelect;

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
          ...months.map((m) {
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
                      m.label,
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
  final Set<String> activeCategories;
  final void Function(Set<String>) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Set<String> _selected;

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
            children: _allCategories.map((cat) {
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
                    cat,
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

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtRupee(int v) => '₹${_fmtNum(v)}';

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
