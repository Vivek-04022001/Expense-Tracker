import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency.dart';
import '../../../accounts/data/models/account_model.dart';
import '../../../accounts/presentation/providers/account_provider.dart';
import '../../../profile/presentation/screens/_inner_app_bar.dart';
import '../../data/models/transfer_model.dart';
import '../providers/transfer_provider.dart';
import '../sheets/add_transfer_sheet.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transferListNotifierProvider);
    final accounts = ref.watch(accountListNotifierProvider).valueOrNull?.accounts;
    final accountsById = {for (final a in accounts ?? <AccountModel>[]) a.id: a};

    return Scaffold(
      backgroundColor: context.bgBase,
      appBar: InnerAppBar(
        title: 'Transfers',
        actions: [
          GestureDetector(
            onTap: () => _openAddSheet(context),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: transfersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(transferListNotifierProvider),
        ),
        data: (transfers) {
          if (transfers.isEmpty) {
            return _EmptyState(onAdd: () => _openAddSheet(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: transfers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final t = transfers[i];
              return _TransferCard(
                transfer: t,
                from: accountsById[t.fromAccountId],
                to: accountsById[t.toAccountId],
                onDelete: () => _confirmDelete(context, ref, t),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransferSheet(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TransferModel transfer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete transfer?',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will reverse the transferred amount across the two accounts.',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(transferListNotifierProvider.notifier).delete(transfer.id);
    }
  }
}

// ─── Transfer card ────────────────────────────────────────────────────────────

class _TransferCard extends StatelessWidget {
  const _TransferCard({
    required this.transfer,
    required this.from,
    required this.to,
    required this.onDelete,
  });

  final TransferModel transfer;
  final AccountModel? from;
  final AccountModel? to;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fromName = from?.name ?? 'Unknown account';
    final toName = to?.name ?? 'Unknown account';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: PhosphorIcon(
                PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold),
                size: 20,
                color: AppColors.info,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fromName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: PhosphorIcon(
                        PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                        size: 13,
                        color: context.textTertiary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        toName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  transfer.description?.isNotEmpty == true
                      ? '${DateFormat('d MMM yyyy').format(transfer.createdAt)} · ${transfer.description}'
                      : DateFormat('d MMM yyyy').format(transfer.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: context.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRupee(transfer.amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          PopupMenuButton<String>(
            icon: PhosphorIcon(
              PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.bold),
              color: context.textTertiary,
            ),
            color: context.bgSurface,
            onSelected: (_) => onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty & error states ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold),
                  size: 32,
                  color: AppColors.info,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No transfers yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Move money between your accounts and\nit will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Add a transfer'),
            ),
          ],
        ),
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
          Text(
            "Couldn't load transfers",
            style: TextStyle(color: context.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
