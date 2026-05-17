import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/expenses/presentation/sheets/add_expense_sheet.dart';
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

  Future<void> _openAddExpense(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
    if (saved == true && context.mounted) {
      showSuccessTopBar(context, 'Expense added!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddExpense(context),
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
              // Left two tabs
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
              // Centre spacer for FAB
              const SizedBox(width: 72),
              // Right two tabs
              _NavTab(
                index: 2,
                current: currentIndex,
                label: 'Insights',
                icon: PhosphorIcons.chartDonut(),
                activeIcon: PhosphorIcons.chartDonut(PhosphorIconsStyle.fill),
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
    final color = isActive ? AppColors.primary500 : AppColors.lightTextTertiary;

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
