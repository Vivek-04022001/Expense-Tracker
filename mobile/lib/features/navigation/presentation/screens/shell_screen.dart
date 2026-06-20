import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/expenses/presentation/sheets/add_expense_sheet.dart';
import '../../../../features/income/presentation/sheets/add_income_sheet.dart';
import '../../../../features/transfers/presentation/sheets/add_transfer_sheet.dart';
import '../../../../shared/widgets/success_overlay.dart';
import '../../../../shared/widgets/sync_banner.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  Future<void> _onAddTap(BuildContext context) async {
    final type = await showModalBottomSheet<_EntryType>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _EntryTypePicker(),
    );
    if (type == null || !context.mounted) return;

    if (type == _EntryType.expense) {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddExpenseSheet(),
      );
      if (saved == true && context.mounted) {
        await showSuccessOverlay(context, isExpense: true);
      }
    } else if (type == _EntryType.income) {
      final saved = await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddIncomeSheet(),
      );
      if (saved == true && context.mounted) {
        await showSuccessOverlay(context, isExpense: false);
      }
    } else {
      await showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddTransferSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SyncBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      // Entire nav lives inside the FAB slot so the body fills the full screen
      // and content remains visible behind the floating pill.
      floatingActionButton: _FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        onAdd: () => _onAddTap(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ─── Floating pill nav bar ────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  static const _tabs = [
    (label: 'Home', branch: 0),
    (label: 'Expenses', branch: 1),
    (label: 'Stats', branch: 2),
    (label: 'Profile', branch: 3),
  ];

  PhosphorIconData _icon(int branch, bool filled) {
    final s = filled ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular;
    return switch (branch) {
      0 => PhosphorIcons.house(s),
      1 => PhosphorIcons.listBullets(s),
      2 => PhosphorIcons.chartDonut(s),
      _ => PhosphorIcons.user(s),
    };
  }

  @override
  Widget build(BuildContext context) {
    const pillHeight = 68.0;
    const centerButtonSize = 60.0;
    const centerGap = 12.0;

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SizedBox(
            height: pillHeight,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final sideTabsWidth =
                    constraints.maxWidth - centerButtonSize - centerGap;
                final tabWidth = sideTabsWidth / 4;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tabs row with a gap in the middle for the FAB
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        _NavTab(
                          width: tabWidth,
                          label: _tabs[0].label,
                          icon: _icon(0, false),
                          activeIcon: _icon(0, true),
                          isActive: currentIndex == 0,
                          onTap: () => onTap(0),
                        ),
                        _NavTab(
                          width: tabWidth,
                          label: _tabs[1].label,
                          icon: _icon(1, false),
                          activeIcon: _icon(1, true),
                          isActive: currentIndex == 1,
                          onTap: () => onTap(1),
                        ),
                        SizedBox(width: centerButtonSize + centerGap),
                        _NavTab(
                          width: tabWidth,
                          label: _tabs[2].label,
                          icon: _icon(2, false),
                          activeIcon: _icon(2, true),
                          isActive: currentIndex == 2,
                          onTap: () => onTap(2),
                        ),
                        _NavTab(
                          width: tabWidth,
                          label: _tabs[3].label,
                          icon: _icon(3, false),
                          activeIcon: _icon(3, true),
                          isActive: currentIndex == 3,
                          onTap: () => onTap(3),
                        ),
                      ],
                    ),
                    // Raised center "+" button poking above the pill
                    Positioned(
                      bottom: pillHeight - centerButtonSize * 0.65,
                      left: (constraints.maxWidth - centerButtonSize) / 2,
                      child: _RaisedFab(size: centerButtonSize, onTap: onAdd),
                    ),
                  ],
                );
              },
            ),
          ),
        )
        .animate()
        .scaleXY(
          begin: 0.85,
          end: 1.0,
          duration: 420.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.4,
          end: 0,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.width,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  final double width;
  final String label;
  final PhosphorIconData icon;
  final PhosphorIconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 68,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top notch indicator — appears on the active tab
              Positioned(
                top: 0,
                left: (width - 28) / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 28,
                  height: isActive ? 3 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.primary500,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                ),
              ),

              // Icon + label
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isActive ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: PhosphorIcon(
                            isActive ? activeIcon : icon,
                            key: ValueKey<bool>(isActive),
                            size: 22,
                            color: isActive
                                ? AppColors.primary500
                                : context.textTertiary,
                          ),
                        ),
                      ),
                      SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? AppColors.primary500
                              : context.textTertiary,
                        ),
                        child: Text(label),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Raised circular "+" FAB that pokes above the pill ────────────────────

class _RaisedFab extends StatefulWidget {
  const _RaisedFab({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  State<_RaisedFab> createState() => _RaisedFabState();
}

class _RaisedFabState extends State<_RaisedFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary500,
          ),
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

// ─── Entry type picker ────────────────────────────────────────────────────────

enum _EntryType { expense, income, transfer }

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
          Text(
            'What would you like to add?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _TypeTile(
            icon: PhosphorIcons.arrowDown(PhosphorIconsStyle.bold),
            label: 'Expense',
            subtitle: 'Record money spent',
            color: AppColors.danger,
            onTap: () => Navigator.pop(context, _EntryType.expense),
          ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.1, end: 0),
          SizedBox(height: 10),
          _TypeTile(
                icon: PhosphorIcons.arrowUp(PhosphorIconsStyle.bold),
                label: 'Income',
                subtitle: 'Record money received',
                color: AppColors.success,
                onTap: () => Navigator.pop(context, _EntryType.income),
              )
              .animate(delay: 60.ms)
              .fadeIn(duration: 220.ms)
              .slideY(begin: 0.1, end: 0),
          SizedBox(height: 10),
          _TypeTile(
                icon: PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold),
                label: 'Transfer',
                subtitle: 'Move money between accounts',
                color: AppColors.info,
                onTap: () => Navigator.pop(context, _EntryType.transfer),
              )
              .animate(delay: 120.ms)
              .fadeIn(duration: 220.ms)
              .slideY(begin: 0.1, end: 0),
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
              child: Center(child: Icon(icon, size: 18, color: color)),
            ),
            SizedBox(width: 14),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
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
