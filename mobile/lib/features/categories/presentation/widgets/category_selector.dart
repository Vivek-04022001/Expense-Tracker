import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/category_model.dart';
import '../providers/category_provider.dart';

/// Horizontal chip row of the user's categories for a given [kind].
///
/// Auto-selects the first category when nothing is selected yet so the
/// transaction sheets always have a category to submit.
class CategorySelector extends ConsumerWidget {
  const CategorySelector({
    super.key,
    required this.kind,
    required this.selectedId,
    required this.onChanged,
  });

  final CategoryKind kind;
  final String? selectedId;
  final ValueChanged<CategoryModel> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesByKindProvider(kind));

    if (categories.isEmpty) {
      return const SizedBox(height: 36);
    }

    // Default to the first category once the list is available.
    final hasSelection = categories.any((c) => c.id == selectedId);
    if (!hasSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(categories.first);
      });
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final color = cat.displayColor;
          final selected = cat.id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : context.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : context.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    cat.phosphorIcon,
                    size: 14,
                    color: selected ? color : context.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
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
        },
      ),
    );
  }
}
