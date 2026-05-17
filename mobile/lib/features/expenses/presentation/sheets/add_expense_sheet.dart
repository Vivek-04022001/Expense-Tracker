import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String _amount = '';
  String _category = 'Food';
  final _merchantCtrl = TextEditingController();
  String _payment = 'UPI';
  DateTime _date = DateTime.now();

  static const _categories = [
    _Cat('Food', AppColors.categoryFood),
    _Cat('Transport', AppColors.categoryTransport),
    _Cat('Shopping', AppColors.categoryShopping),
    _Cat('Bills', AppColors.categoryBills),
    _Cat('Health', AppColors.categoryHealth),
    _Cat('Others', AppColors.categoryOther),
  ];

  @override
  void dispose() {
    _merchantCtrl.dispose();
    super.dispose();
  }

  void _numpadTap(String key) {
    setState(() {
      switch (key) {
        case '⌫':
          if (_amount.isNotEmpty) {
            _amount = _amount.substring(0, _amount.length - 1);
          }
        case '.':
          if (!_amount.contains('.')) {
            _amount = _amount.isEmpty ? '0.' : '$_amount.';
          }
        default:
          if (_amount.length < 9) _amount += key;
      }
    });
  }

  void _save() {
    final value = double.tryParse(_amount);
    if (value == null || value <= 0) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.day == now.day &&
        _date.month == now.month &&
        _date.year == now.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE1EC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Add expense',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Amount display
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: _amount.isEmpty
                            ? AppColors.lightTextTertiary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      _amount.isEmpty ? '0' : _amount,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: _amount.isEmpty
                            ? AppColors.lightTextTertiary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter an amount',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Category chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final selected = _category == cat.name;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? cat.color
                              : AppColors.lightBorderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cat.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? cat.color
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Merchant + Date row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightBorderSubtle),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _merchantCtrl,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.lightTextPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Merchant',
                          hintStyle: TextStyle(
                            color: AppColors.lightTextTertiary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.lightBorderSubtle,
                    ),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.calendarBlank(),
                              size: 15,
                              color: AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isToday
                                  ? 'Today'
                                  : DateFormat('MMM d').format(_date),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Payment method toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: ['Cash', 'UPI', 'Card']
                      .map(
                        (p) => _PaymentTab(
                          label: p,
                          selected: _payment == p,
                          onTap: () => setState(() => _payment = p),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Custom numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _Numpad(onTap: _numpadTap),
            ),
            // Save button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _amount.isNotEmpty ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary500.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

// ─── Payment tab ─────────────────────────────────────────────────────────────

class _PaymentTab extends StatelessWidget {
  const _PaymentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary500 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? Colors.white
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Numpad ───────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  const _Numpad({required this.onTap});

  final void Function(String) onTap;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows
          .map(
            (row) => Row(
              children: row
                  .map(
                    (key) => Expanded(
                      child: _NumKey(label: key, onTap: () => onTap(key)),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 54,
        child: Center(
          child: label == '⌫'
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 22,
                  color: AppColors.lightTextPrimary,
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _Cat {
  const _Cat(this.name, this.color);
  final String name;
  final Color color;
}
