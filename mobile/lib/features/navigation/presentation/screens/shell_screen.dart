import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/expenses/presentation/sheets/add_expense_sheet.dart';
import '../../../../features/income/presentation/sheets/add_income_sheet.dart';
import '../../../../shared/utils/top_snack_bar.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _onFabTap(BuildContext context) async {
    final type = await showModalBottomSheet<_EntryType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _EntryTypePicker(),
    );
    if (type == null || !context.mounted) return;

    if (type == _EntryType.expense) {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddExpenseSheet(),
      );
      if (saved == true && context.mounted) {
        showSuccessTopBar(context, 'Expense added!');
      }
    } else {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddIncomeSheet(),
      );
      if (saved == true && context.mounted) {
        showSuccessTopBar(context, 'Income added!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onFabTap(context),
        backgroundColor: AppColors.primary500,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Entry type picker ────────────────────────────────────────────────────────

enum _EntryType { expense, income }

class _EntryTypePicker extends StatelessWidget {
  const _EntryTypePicker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to add?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _TypeTile(
            icon: PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
            label: 'Expense',
            subtitle: 'Record money spent',
            color: AppColors.danger,
            onTap: () => Navigator.pop(context, _EntryType.expense),
          ),
          const SizedBox(height: 10),
          _TypeTile(
            icon: PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
            label: 'Income',
            subtitle: 'Record money received',
            color: AppColors.success,
            onTap: () => Navigator.pop(context, _EntryType.income),
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 18, color: color),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightBorderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavTab(
                index: 0,
                current: currentIndex,
                label: 'Home',
                icon: PhosphorIcons.house(),
                activeIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                onTap: onTap,
              ),
              _NavTab(
                index: 1,
                current: currentIndex,
                label: 'Expenses',
                icon: PhosphorIcons.listBullets(),
                activeIcon: PhosphorIcons.listBullets(PhosphorIconsStyle.fill),
                onTap: onTap,
              ),
              const SizedBox(width: 72),
              _NavTab(
                index: 2,
                current: currentIndex,
                label: 'Budgets',
                icon: PhosphorIcons.piggyBank(),
                activeIcon: PhosphorIcons.piggyBank(PhosphorIconsStyle.fill),
                onTap: onTap,
              ),
              _NavTab(
                index: 3,
                current: currentIndex,
                label: 'Profile',
                icon: PhosphorIcons.user(),
                activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.index,
    required this.current,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
  });

  final int index;
  final int current;
  final String label;
  final PhosphorIconData icon;
  final PhosphorIconData activeIcon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    final color =
        isActive ? AppColors.primary500 : AppColors.lightTextTertiary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
