import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../models/transaction_models.dart';
import '../services/transaction_service.dart';

/// Provider for TransactionService
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionService(apiClient);
});

/// Provider for transactions list (with mock data fallback)
final transactionsProvider = FutureProvider.family<List<Transaction>, String?>((ref, status) async {
  try {
    final service = ref.watch(transactionServiceProvider);
    return await service.getTransactions(status: status);
  } catch (e) {
    // Return mock transactions if API fails
    return [
      Transaction(
        id: 'TXN001',
        storeName: 'Amazon',
        storeLogo: 'https://logo.clearbit.com/amazon.in',
        orderId: 'ORD123456',
        purchaseAmount: 2499.00,
        cashbackAmount: 124.95,
        status: TransactionStatus.confirmed,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        confirmedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 'TXN002',
        storeName: 'Flipkart',
        storeLogo: 'https://logo.clearbit.com/flipkart.com',
        orderId: 'ORD789012',
        purchaseAmount: 1599.00,
        cashbackAmount: 63.96,
        status: TransactionStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Transaction(
        id: 'TXN003',
        storeName: 'Myntra',
        storeLogo: 'https://logo.clearbit.com/myntra.com',
        orderId: 'ORD345678',
        purchaseAmount: 3200.00,
        cashbackAmount: 192.00,
        status: TransactionStatus.paid,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        confirmedAt: DateTime.now().subtract(const Duration(days: 10)),
        paidAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: 'TXN004',
        storeName: 'Swiggy',
        storeLogo: 'https://logo.clearbit.com/swiggy.com',
        orderId: 'ORD901234',
        purchaseAmount: 450.00,
        cashbackAmount: 13.50,
        status: TransactionStatus.cancelled,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
});

/// Provider for transaction detail (with mock data fallback)
final transactionDetailProvider = FutureProvider.family<TransactionDetail, String>((ref, id) async {
  try {
    final service = ref.watch(transactionServiceProvider);
    return await service.getTransactionDetail(id);
  } catch (e) {
    // Return mock detail if API fails
    return TransactionDetail(
      id: id,
      storeName: 'Amazon',
      storeLogo: 'https://logo.clearbit.com/amazon.in',
      orderId: 'ORD123456',
      purchaseAmount: 2499.00,
      cashbackAmount: 124.95,
      status: TransactionStatus.confirmed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      confirmedAt: DateTime.now().subtract(const Duration(days: 1)),
      clickId: 'CLK123456',
      cashbackRate: '5%',
      statusDescription: 'Your cashback is confirmed and will be paid soon',
    );
  }
});
