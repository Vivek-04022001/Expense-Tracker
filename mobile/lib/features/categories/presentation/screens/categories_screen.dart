import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/_inner_app_bar.dart';
import '../../data/models/category_model.dart';
import '../providers/category_provider.dart';
import '../sheets/add_category_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoryListNotifierProvider);

    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: const InnerAppBar(title: 'Categories'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary500,
        onPressed: () => _openSheet(context),
        child: PhosphorIcon(PhosphorIcons.plus(PhosphorIconsStyle.bold),
            color: Colors.white),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(categoryListNotifierProvider),
        ),
        data: (categories) {
          final expense = categories
              .where((c) => c.kind == CategoryKind.expense)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final income = categories
              .where((c) => c.kind == CategoryKind.income)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              _SectionLabel('Expense'),
              const SizedBox(height: 8),
              _CategoryCard(
                items: expense,
                onEdit: (c) => _openSheet(context, existing: c),
                onDelete: (c) => _confirmDelete(context, ref, c),
              ),
              const SizedBox(height: 22),
              _SectionLabel('Income'),
              const SizedBox(height: 8),
              _CategoryCard(
                items: income,
                onEdit: (c) => _openSheet(context, existing: c),
                onDelete: (c) => _confirmDelete(context, ref, c),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, {CategoryModel? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        title: Text('Delete ${category.name}?',
            style: TextStyle(color: context.textPrimary, fontSize: 18)),
        content: Text(
          'This category will be removed. Existing transactions keep their record.',
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref
            .read(categoryListNotifierProvider.notifier)
            .delete(category.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete category')),
          );
        }
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.textTertiary,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CategoryModel> items;
  final void Function(CategoryModel) onEdit;
  final void Function(CategoryModel) onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Text('No categories yet',
            style: TextStyle(color: context.textTertiary)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 64, color: context.borderSubtle),
            _CategoryRow(
              category: items[i],
              onEdit: () => onEdit(items[i]),
              onDelete: () => onDelete(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = category.displayColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: PhosphorIcon(category.phosphorIcon, size: 18, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
          if (category.isSystem)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'Built-in',
                style: TextStyle(fontSize: 11, color: context.textTertiary),
              ),
            ),
          PopupMenuButton<String>(
            icon: PhosphorIcon(
              PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.bold),
              color: context.textTertiary,
              size: 18,
            ),
            color: context.bgSurface,
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              // Built-in categories back the SMS classifier and reports, so they
              // can be edited but not deleted.
              if (!category.isSystem)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Couldn't load categories",
              style: TextStyle(color: context.textPrimary, fontSize: 16)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
