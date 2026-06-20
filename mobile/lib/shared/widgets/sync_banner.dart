import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/sync/connectivity_provider.dart';
import '../../core/sync/sync_controller.dart';
import '../../core/theme/app_colors.dart';

/// A slim status strip shown at the top of the app shell. It surfaces the
/// offline state (and a syncing hint) without disrupting layout when idle and
/// online — it collapses to zero height.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    final sync = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingCountProvider).valueOrNull ?? 0;

    final Widget content;
    if (!online) {
      content = _Strip(
        key: const ValueKey('offline'),
        color: context.textSecondary,
        icon: PhosphorIcons.cloudSlash(PhosphorIconsStyle.fill),
        label: pending > 0
            ? 'Offline — $pending change${pending == 1 ? '' : 's'} will sync later'
            : 'Offline — changes will sync when you reconnect',
      );
    } else if (sync.syncing) {
      content = _Strip(
        key: const ValueKey('syncing'),
        color: AppColors.info,
        icon: PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
        label: 'Syncing…',
      );
    } else {
      content = const SizedBox.shrink(key: ValueKey('idle'));
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: content,
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({super.key, required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
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
