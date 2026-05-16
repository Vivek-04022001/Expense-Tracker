import 'package:flutter/material.dart';

const _categoryColors = <String, Color>{
  'food_and_drink': Color(0xFFFF6B6B),
  'transport': Color(0xFF4ECDC4),
  'bills_and_utilities': Color(0xFFFFE66D),
  'shopping': Color(0xFFA855F7),
  'health': Color(0xFF06D6A0),
  'entertainment': Color(0xFFFF9F1C),
  'education': Color(0xFF118AB2),
  'other': Color(0xFF8D99AE),
};

const _categoryIcons = <String, IconData>{
  'food_and_drink': Icons.restaurant,
  'transport': Icons.directions_car,
  'bills_and_utilities': Icons.receipt_long,
  'shopping': Icons.shopping_bag,
  'health': Icons.favorite,
  'entertainment': Icons.movie,
  'education': Icons.school,
  'other': Icons.more_horiz,
};

String formatCategory(String category) => switch (category) {
      'food_and_drink' => 'Food & Drink',
      'transport' => 'Transport',
      'bills_and_utilities' => 'Bills & Utilities',
      'shopping' => 'Shopping',
      'health' => 'Health',
      'entertainment' => 'Entertainment',
      'education' => 'Education',
      _ => 'Other',
    };

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[category] ?? const Color(0xFF8D99AE);
    final icon = _categoryIcons[category] ?? Icons.more_horiz;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            formatCategory(category),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
