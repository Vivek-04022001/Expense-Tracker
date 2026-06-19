import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/account_provider.dart';

/// Horizontal chip row for picking an account. Watches the accounts list.
///
/// - [selectedId] is the currently selected account id (null = none).
/// - [onChanged] fires with the new id (null when [includeNone] and "None" tapped).
/// - [includeNone] prepends a "None" chip (for optional links like expense/income).
/// - [excludeId] hides one account (e.g. the "from" account when picking "to").
class AccountSelector extends ConsumerWidget {
  const AccountSelector({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.includeNone = true,
    this.excludeId,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool includeNone;
  final String? excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(accountListNotifierProvider);

    return asyncAccounts.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (result) {
        final accounts =
            result.accounts.where((a) => a.id != excludeId).toList();
        if (accounts.isEmpty && !includeNone) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Add an account first to use transfers.',
              style: TextStyle(fontSize: 12.5, color: context.textTertiary),
            ),
          );
        }

        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (includeNone) ...[
                _Chip(
                  label: 'No account',
                  icon: PhosphorIcons.prohibit(PhosphorIconsStyle.bold),
                  color: AppColors.categoryOther,
                  selected: selectedId == null,
                  onTap: () => onChanged(null),
                ),
                const SizedBox(width: 8),
              ],
              for (final a in accounts) ...[
                _Chip(
                  label: a.name,
                  icon: a.type.icon,
                  color: a.displayColor,
                  selected: selectedId == a.id,
                  onTap: () => onChanged(a.id),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PhosphorIconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : context.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : context.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(icon,
                size: 13, color: selected ? color : context.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? color : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
