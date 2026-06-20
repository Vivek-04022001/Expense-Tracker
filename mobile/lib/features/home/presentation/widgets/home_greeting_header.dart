import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({super.key, this.name = 'Vivek'});

  final String name;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Only show the name when it's an actual name — never a phone number.
  bool get _hasRealName =>
      name.trim().isNotEmpty && !RegExp(r'^[\d\s+()-]+$').hasMatch(name);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _hasRealName ? '$_greeting, $name' : _greeting,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.bgSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.bell(),
                size: 20,
                color: context.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
