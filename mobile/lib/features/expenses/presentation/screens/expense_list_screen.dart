import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../sheets/add_expense_sheet.dart';
import '../widgets/expense_tile.dart';

final _indiaFormat = NumberFormat('##,##,##0.00', 'en_IN');

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(groupedExpensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: const AddExpenseSheet(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: grouped.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(expenseListNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (groupMap) {
          if (groupMap.isEmpty) {
            return const Center(
              child: Text(
                'No expenses yet.\nTap + to add one.',
                textAlign: TextAlign.center,
              ),
            );
          }
          final keys = groupMap.keys.toList();
          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final dateKey = keys[index];
              final items = groupMap[dateKey]!;
              final dayTotal =
                  items.fold<double>(0, (sum, e) => sum + e.amount);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '₹${_indiaFormat.format(dayTotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...items.map((expense) => ExpenseTile(expense: expense)),
                  if (index < keys.length - 1) const Divider(height: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
