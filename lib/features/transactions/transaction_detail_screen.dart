import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import 'providers/transaction_provider.dart';
import 'models/transaction_models.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionDetail = ref.watch(transactionDetailProvider(transactionId));

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: transactionDetail.when(
        data: (detail) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(detail),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildDetailsCard(detail),
              const SizedBox(height: AppTheme.spacingLarge),
              _buildTimelineCard(detail),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.screenPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorRed,
                ),
                SizedBox(height: AppTheme.spacingMedium),
                Text(
                  'Failed to load details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(TransactionDetail detail) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    Color statusColor;
    IconData statusIcon;
    
    switch (detail.status) {
      case TransactionStatus.pending:
        statusColor = AppTheme.warningAmber;
        statusIcon = Icons.schedule;
        break;
      case TransactionStatus.confirmed:
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case TransactionStatus.paid:
        statusColor = AppTheme.trustBlue;
        statusIcon = Icons.account_balance_wallet;
        break;
      case TransactionStatus.cancelled:
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              size: 48,
              color: statusColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            detail.status.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            detail.statusDescription,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Cashback: ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                currencyFormat.format(detail.cashbackAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
          if (detail.status == TransactionStatus.cancelled && detail.cancelledReason != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reason: ${detail.cancelledReason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorRed,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(TransactionDetail detail) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          _buildDetailRow('Store', detail.storeName),
          _buildDetailRow('Order ID', detail.orderId),
          _buildDetailRow('Click ID', detail.clickId),
          _buildDetailRow(
            'Purchase Amount',
            currencyFormat.format(detail.purchaseAmount),
          ),
          _buildDetailRow('Cashback Rate', detail.cashbackRate),
          _buildDetailRow(
            'Cashback Amount',
            currencyFormat.format(detail.cashbackAmount),
            valueColor: AppTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(TransactionDetail detail) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          _buildTimelineItem(
            'Order Placed',
            dateFormat.format(detail.createdAt),
            true,
          ),
          if (detail.confirmedAt != null)
            _buildTimelineItem(
              'Cashback Confirmed',
              dateFormat.format(detail.confirmedAt!),
              true,
            ),
          if (detail.paidAt != null)
            _buildTimelineItem(
              'Payment Completed',
              dateFormat.format(detail.paidAt!),
              true,
            ),
          if (detail.status == TransactionStatus.pending)
            _buildTimelineItem(
              'Awaiting Confirmation',
              'Usually takes 7-14 days',
              false,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.successGreen : AppTheme.textLight,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
