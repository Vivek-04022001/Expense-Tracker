import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

void showSuccessTopBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopSnackBar(
      message: message,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _TopSnackBar extends StatefulWidget {
  const _TopSnackBar({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.5),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) _ctrl.reverse().then((_) => widget.onDone());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;
    return Positioned(
      top: topPadding,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.accent500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 13, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
