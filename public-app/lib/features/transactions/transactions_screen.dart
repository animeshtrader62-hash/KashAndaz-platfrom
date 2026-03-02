import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../core/widgets/login_required.dart';
import '../../core/utils/page_transitions.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'transaction_detail_screen.dart';
import 'widgets/cashback_transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: AppTheme.scaffoldBg,
            appBar: AppBar(
              title: const Text('My Cashback'),
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            body: const LoginRequiredView(
              message: 'Please login to view your cashback history.',
            ),
          );
        }

        final transactions = ref.watch(transactionsProvider(_selectedStatus));
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: AppBar(
            title: const Text('My Cashback'),
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(transactionsProvider(_selectedStatus));
                  },
                  child: transactions.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return _buildEmptyState();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.screenPadding),
                        cacheExtent: 300,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          return CashbackTransactionCard(
                            transaction: list[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                SlidePageRoute(
                                  page: TransactionDetailScreen(
                                    transactionId: list[index].id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => _buildErrorState(err),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('My Cashback'),
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('My Cashback'),
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
        ),
        body: const LoginRequiredView(
          message: 'Please login to view your cashback history.',
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const items = <({String label, String? status})>[
      (label: 'All', status: null),
      (label: 'Pending', status: 'pending'),
      (label: 'Confirmed', status: 'confirmed'),
      (label: 'Paid', status: 'paid'),
      (label: 'Cancelled', status: 'cancelled'),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        cacheExtent: 300,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppTheme.spacingSmall),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildFilterChip(item.label, item.status);
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryOrange.withAlpha(26),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryOrange : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryOrange : AppTheme.borderGrey,
        width: isSelected ? 1.5 : 1,
      ),
    );
  }



  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            SizedBox(height: AppTheme.spacingLarge),
            Text(
              'No Cashback Yet 🎁',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              'Start shopping through KashAndaz\nto earn amazing cashback rewards!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              error.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(transactionsProvider(_selectedStatus));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
