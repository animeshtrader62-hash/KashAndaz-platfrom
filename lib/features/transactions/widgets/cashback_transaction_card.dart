import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../transactions/models/transaction_models.dart';

class CashbackTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const CashbackTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });
  
  String get storeName => transaction.storeName;
  double get cashbackAmount => transaction.cashbackAmount;
  TransactionStatus get status => transaction.status;
  DateTime get date => transaction.createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              children: [
                // Store Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingMedium),
                
                // Transaction Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+₹${cashbackAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case TransactionStatus.pending:
        return AppTheme.warningAmber;
      case TransactionStatus.confirmed:
        return AppTheme.successGreen;
      case TransactionStatus.cancelled:
        return AppTheme.errorRed;
      case TransactionStatus.paid:
        return AppTheme.trustBlue;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case TransactionStatus.pending:
        return Icons.access_time_rounded;
      case TransactionStatus.confirmed:
        return Icons.check_circle_rounded;
      case TransactionStatus.cancelled:
        return Icons.cancel_rounded;
      case TransactionStatus.paid:
        return Icons.account_balance_wallet_rounded;
    }
  }

  String _getStatusText() {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.paid:
        return 'Paid';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}


