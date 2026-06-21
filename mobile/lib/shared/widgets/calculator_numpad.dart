import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart'; // for AppThemeColors extension

class CalculatorNumpad extends StatelessWidget {
  const CalculatorNumpad({super.key, required this.onKeyTap});

  final void Function(String key) onKeyTap;

  static const _operators = ['+', '-', '×', '÷'];
  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: _operators
              .map((op) => Expanded(
                    child: _CalcKey(
                      label: op,
                      onTap: () => onKeyTap(op),
                      isOperator: true,
                    ),
                  ))
              .toList(),
        ),
        ..._rows.map(
          (row) => Row(
            children: row
                .map((key) => Expanded(
                      child: _CalcKey(
                        label: key,
                        onTap: () => onKeyTap(key),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({
    required this.label,
    required this.onTap,
    this.isOperator = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isOperator;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 52,
          child: Center(
            child: label == '⌫'
                ? Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: context.textPrimary,
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: isOperator ? 22 : 26,
                      fontWeight:
                          isOperator ? FontWeight.w300 : FontWeight.w500,
                      color: isOperator
                          ? context.textTertiary
                          : context.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
