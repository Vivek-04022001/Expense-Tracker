import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../providers/expense_notifier.dart';
import '../widgets/category_chip.dart';

const _categories = [
  ('food_and_drink', 'Food & Drink'),
  ('transport', 'Transport'),
  ('bills_and_utilities', 'Bills'),
  ('shopping', 'Shopping'),
  ('health', 'Health'),
  ('entertainment', 'Fun'),
  ('education', 'Education'),
  ('other', 'Other'),
];

const _paymentMethods = [
  ('upi', 'UPI'),
  ('bank_transfer', 'Bank Transfer'),
  ('cash', 'Cash'),
  ('other', 'Other'),
];

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'other';
  String _selectedPaymentMethod = 'upi';
  bool _isLoading = false;
  String? _errorMessage;
  String? _amountError;
  String? _noteError;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // --- Validate ---
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    final noteText = _noteController.text.trim();

    String? amountErr;
    String? noteErr;

    if (amount == null || amount <= 0) {
      amountErr = 'Enter a valid positive amount';
    }
    // Backend: description min 5 chars if provided
    if (noteText.isNotEmpty && noteText.length < 5) {
      noteErr = 'Note must be at least 5 characters';
    }

    if (amountErr != null || noteErr != null) {
      setState(() {
        _amountError = amountErr;
        _noteError = noteErr;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _amountError = null;
      _noteError = null;
    });

    try {
      await ref.read(expenseNotifierProvider.notifier).addExpense(
            amount: amount!,
            category: _selectedCategory,
            paymentMethod: _selectedPaymentMethod,
            note: noteText.isEmpty ? null : noteText,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Center(
                child: Text(
                  'Add Expense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Amount field
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w600),
                  hintText: '0.00',
                  hintStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _amountError,
                ),
                onChanged: (_) {
                  if (_amountError != null) {
                    setState(() => _amountError = null);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Category label
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Category chips (horizontal scroll)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final key = cat.$1;
                    final label = cat.$2;
                    final color =
                        categoryColors[key] ?? const Color(0xFF8D99AE);
                    final icon = categoryIcons[key] ?? Icons.more_horiz;
                    final isSelected = _selectedCategory == key;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Payment method label
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),

              // Payment method chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paymentMethods.map((pm) {
                  final key = pm.$1;
                  final label = pm.$2;
                  final isSelected = _selectedPaymentMethod == key;
                  final primary = colorScheme.primary;

                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Note field
              TextField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'What was this for?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: _noteError,
                ),
                onChanged: (_) {
                  if (_noteError != null) {
                    setState(() => _noteError = null);
                  }
                },
              ),

              // Server error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                      color: colorScheme.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
