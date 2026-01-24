import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation/main_scaffold.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/widgets/coming_soon_screen.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/login_required.dart';
import '../auth/providers/auth_provider.dart';
import 'models/wallet_models.dart';
import 'providers/wallet_provider.dart';

/// Wallet Screen - EXACT STRUCTURE FROM HAND-DRAWN UI
/// 
/// Structure:
/// 1. AppBar: "My Earnings" (Flipkart Blue)
/// 2. Top Card: All time Earnings (Cashback + Referrals)
/// 3. My order Details button
/// 4. Get Help button
/// 5. Request Payment CTA (orange border)
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  void _openComingSoon(BuildContext context, String title) {
    Navigator.push(
      context,
      SlidePageRoute(
        page: ComingSoonScreen(
          title: title,
          message: "This feature is under development. We’re launching it soon.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: AppTheme.scaffoldBg,
            appBar: AppBar(
              title: const Text('My Earnings'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  final scope = MainScaffoldScope.maybeOf(context);
                  if (scope != null) {
                    scope.setIndex(0);
                    return;
                  }
                  Navigator.maybePop(context);
                },
              ),
            ),
            body: const LoginRequiredView(
              message: 'Please login to view your wallet.',
            ),
          );
        }

        final walletData = ref.watch(walletDataProvider);
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: AppBar(
            title: const Text('My Earnings'),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                final scope = MainScaffoldScope.maybeOf(context);
                if (scope != null) {
                  scope.setIndex(0);
                  return;
                }
                Navigator.maybePop(context);
              },
            ),
          ),
          body: walletData.when(
            data: (data) => _buildContent(context, ref, data),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
            error: (err, stack) => _buildErrorState(context, ref, err.toString()),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('My Earnings'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              final scope = MainScaffoldScope.maybeOf(context);
              if (scope != null) {
                scope.setIndex(0);
                return;
              }
              Navigator.maybePop(context);
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('My Earnings'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              final scope = MainScaffoldScope.maybeOf(context);
              if (scope != null) {
                scope.setIndex(0);
                return;
              }
              Navigator.maybePop(context);
            },
          ),
        ),
        body: const LoginRequiredView(
          message: 'Please login to view your wallet.',
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WalletData data) {
    final withdrawals = data.recentWithdrawals;
    final hasWithdrawals = withdrawals.isNotEmpty;
    final preCount = hasWithdrawals ? 9 : 6;
    final tailStart = preCount + withdrawals.length;
    final totalCount = tailStart + 3;

    return RefreshIndicator(
      color: AppTheme.cashbackOrange,
      onRefresh: () async => ref.invalidate(walletDataProvider),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        cacheExtent: 300,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index == 0) return const SizedBox(height: 16);

          // Top Card - WALLET SUMMARY
          if (index == 1) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Wallet Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.favorite, color: Colors.red.shade400, size: 18),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Available row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatAmount(data.balance.available),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Pending row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatAmount(data.balance.pending),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textLight),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total earned: ${_formatAmount(data.balance.totalEarned)}  •  Withdrawn: ${_formatAmount(data.balance.withdrawn)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (index == 2) return const SizedBox(height: 24);

          if (index == 3) {
            return _ActionButton(
              title: 'My order Details',
              onTap: () => _openComingSoon(context, 'My order Details'),
            );
          }

          if (index == 4) return const SizedBox(height: 12);

          if (index == 5) {
            return _ActionButton(
              title: 'Get Help',
              onTap: () => _openComingSoon(context, 'Get Help'),
            );
          }

          if (hasWithdrawals) {
            if (index == 6) return const SizedBox(height: 24);
            if (index == 7) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Recent Withdrawals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            }
            if (index == 8) return const SizedBox(height: 8);

            final firstWithdrawalIndex = 9;
            if (index >= firstWithdrawalIndex && index < firstWithdrawalIndex + withdrawals.length) {
              return _WithdrawalTile(item: withdrawals[index - firstWithdrawalIndex]);
            }
          }

          if (index == tailStart) return const SizedBox(height: 24);

          if (index == tailStart + 1) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showRequestPaymentDialog(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.cashbackOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppTheme.cashbackOrange, width: 2),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Request Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }

          if (index == tailStart + 2) return const SizedBox(height: 32);

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppTheme.errorRed),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(walletDataProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  void _showRequestPaymentDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final upiController = TextEditingController();
    final accountController = TextEditingController();
    final ifscController = TextEditingController();
    final holderController = TextEditingController();
    String method = 'upi';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(method),
                  initialValue: method,
                  items: const [
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (value) => setState(() => method = value ?? 'upi'),
                  decoration: const InputDecoration(
                    labelText: 'Withdrawal Method',
                  ),
                ),
                const SizedBox(height: 12),
                if (method == 'upi')
                  TextField(
                    controller: upiController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID',
                    ),
                  )
                else ...[
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ifscController,
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: holderController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        _showSnack(context, 'Enter a valid amount');
                        return;
                      }

                      if (method == 'upi' && upiController.text.trim().isEmpty) {
                        _showSnack(context, 'Enter a valid UPI ID');
                        return;
                      }

                      if (method == 'bank' &&
                          (accountController.text.trim().isEmpty ||
                              ifscController.text.trim().isEmpty ||
                              holderController.text.trim().isEmpty)) {
                        _showSnack(context, 'Enter complete bank details');
                        return;
                      }

                      setState(() => isSubmitting = true);
                      try {
                        final service = ref.read(walletServiceProvider);
                        final request = WithdrawalRequest(
                          amount: amount,
                          method: method,
                          upiId: method == 'upi' ? upiController.text.trim() : null,
                          bankDetails: method == 'bank'
                              ? BankDetails(
                                  accountNumber: accountController.text.trim(),
                                  ifsc: ifscController.text.trim(),
                                  accountHolderName: holderController.text.trim(),
                                )
                              : null,
                        );

                        final response = await service.requestWithdrawal(request);
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showSnack(context, response.message.isNotEmpty
                              ? response.message
                              : 'Withdrawal requested');
                          ref.invalidate(walletDataProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showSnack(context, e.toString().replaceAll('Exception: ', ''));
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION BUTTON WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  
  const _ActionButton({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  final WithdrawalItem item;

  const _WithdrawalTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${item.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (item.upiId != null)
              Text(
                item.upiId!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}



