import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/category_icons.dart';
import '../../data/models/category_model.dart';
import '../providers/category_provider.dart';

class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({super.key, this.existing, this.initialKind});

  final CategoryModel? existing;
  final CategoryKind? initialKind;

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  late final TextEditingController _nameCtrl;
  late CategoryKind _kind;
  late String _icon;
  late String _color;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _kind = e?.kind ?? widget.initialKind ?? CategoryKind.expense;
    _icon = e?.icon ?? CategoryIcons.pickerKeys.first;
    _color = e?.color ?? CategoryIcons.palette.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Color get _accent {
    final hex = _color.replaceFirst('#', '');
    final value = int.tryParse('FF$hex', radix: 16);
    return value != null ? Color(value) : AppColors.primary500;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your category a name')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final notifier = ref.read(categoryListNotifierProvider.notifier);
      if (_isEdit) {
        await notifier.edit(
          id: widget.existing!.id,
          name: name,
          icon: _icon,
          color: _color,
        );
      } else {
        await notifier.create(
          name: name,
          kind: _kind,
          icon: _icon,
          color: _color,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save category')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE1EC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      _isEdit ? 'Edit category' : 'New category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.bgSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: context.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Preview + name
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: PhosphorIcon(CategoryIcons.resolve(_icon),
                            size: 24, color: _accent),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Category name',
                          hintStyle: TextStyle(color: context.textTertiary),
                          filled: true,
                          fillColor: context.bgSubtle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Kind toggle (only when creating — kind is immutable on edit)
                if (!_isEdit) ...[
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.bgSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _KindTab(
                          label: 'Expense',
                          selected: _kind == CategoryKind.expense,
                          onTap: () =>
                              setState(() => _kind = CategoryKind.expense),
                        ),
                        _KindTab(
                          label: 'Income',
                          selected: _kind == CategoryKind.income,
                          onTap: () =>
                              setState(() => _kind = CategoryKind.income),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                // Icon picker
                Text('Icon',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: CategoryIcons.pickerKeys.map((key) {
                    final selected = key == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = key),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? _accent.withValues(alpha: 0.15)
                              : context.bgSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                selected ? _accent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            CategoryIcons.resolve(key),
                            size: 20,
                            color: selected ? _accent : context.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                // Color picker
                Text('Color',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: CategoryIcons.palette.map((hex) {
                    final value =
                        int.tryParse('FF${hex.replaceFirst('#', '')}', radix: 16);
                    final color = value != null
                        ? Color(value)
                        : AppColors.primary500;
                    final selected = hex == _color;
                    return GestureDetector(
                      onTap: () => setState(() => _color = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? context.textPrimary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
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
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            _isEdit ? 'Save changes' : 'Add category',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindTab extends StatelessWidget {
  const _KindTab({
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : context.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
