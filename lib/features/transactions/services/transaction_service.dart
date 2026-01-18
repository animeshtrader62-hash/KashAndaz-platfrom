import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import '../models/transaction_models.dart';

/// Transaction service
class TransactionService {
  final ApiClient _apiClient;

  TransactionService(this._apiClient);

  /// Get transactions list
  Future<List<Transaction>> getTransactions({
    String? status,
    int? page,
    int? limit,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.transactions,
      queryParameters: {
        if (status != null) 'status': status,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );

    final transactions = (response.data['transactions'] as List)
        .map((tx) => Transaction.fromJson(tx as Map<String, dynamic>))
        .toList();

    return transactions;
  }

  /// Get transaction detail
  Future<TransactionDetail> getTransactionDetail(String transactionId) async {
    final response = await _apiClient.get(
      '${ApiConstants.transactions}/$transactionId',
    );

    return TransactionDetail.fromJson(response.data);
  }
}
