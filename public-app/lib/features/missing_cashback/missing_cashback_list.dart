import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/store_logo.dart';
import '../../theme/app_theme.dart';
import 'missing_cashback_models.dart';
import 'missing_cashback_provider.dart';

class MissingCashbackList extends ConsumerWidget {
  final String filter;

  const MissingCashbackList({
    super.key,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myMissingCashbackProvider);

    return async.when(
      data: (items) {
        final filtered = _applyFilter(items, filter);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textLight),
                const SizedBox(height: 16),
                Text(
                  'No missing cashback claims',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit a request to start tracking',
                  style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: () async {
            ref.invalidate(myMissingCashbackProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            cacheExtent: 300,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _RequestCard(item: item);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
      error: (err, stack) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppTheme.errorRed),
                const SizedBox(height: 10),
                const Text(
                  'Could not load requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(myMissingCashbackProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MissingCashbackRequest> _applyFilter(List<MissingCashbackRequest> items, String filter) {
    final f = filter.trim().toLowerCase();

    if (f == 'in review') {
      return items.where((e) => e.status == 'pending').toList();
    }
    if (f == 'successfully') {
      return items.where((e) => e.status == 'approved').toList();
    }
    if (f == 'closed') {
      return items.where((e) => e.status == 'rejected').toList();
    }

    return items;
  }
}

class _RequestCard extends StatelessWidget {
  final MissingCashbackRequest item;

  const _RequestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StoreLogo(url: null, storeName: item.storeName),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Order ID: ${item.orderId}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Order Amount: ${item.orderAmount.toStringAsFixed(2)}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Submitted: ${_formatDateTime(item.createdAt)}',
            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final (bg, fg, label) = switch (s) {
      'approved' => (AppTheme.successGreen.withAlpha(26), AppTheme.successGreen, 'APPROVED'),
      'rejected' => (AppTheme.errorRed.withAlpha(26), AppTheme.errorRed, 'REJECTED'),
      _ => (AppTheme.cashbackOrange.withAlpha(26), AppTheme.cashbackOrange, 'PENDING'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
