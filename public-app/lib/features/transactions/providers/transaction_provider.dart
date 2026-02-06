import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../models/transaction_models.dart';
import '../services/transaction_service.dart';

/// Provider for TransactionService
final transactionServiceProvider = Provider<TransactionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionService(apiClient);
});

/// Provider for transactions list
final transactionsProvider = FutureProvider.autoDispose.family<List<Transaction>, String?>((ref, status) async {
  final service = ref.watch(transactionServiceProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return await service.getTransactions(status: status, cancelToken: cancelToken);
});

/// Provider for transaction detail
final transactionDetailProvider = FutureProvider.autoDispose.family<TransactionDetail, String>((ref, id) async {
  final service = ref.watch(transactionServiceProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return await service.getTransactionDetail(id, cancelToken: cancelToken);
});
