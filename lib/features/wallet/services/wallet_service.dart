import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import '../models/wallet_models.dart';

/// Wallet service for balance + withdrawals
class WalletService {
  final ApiClient _apiClient;

  WalletService(this._apiClient);

  /// Get wallet data
  Future<WalletData> getWallet() async {
    final response = await _apiClient.get(ApiConstants.wallet);
    return WalletData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Request withdrawal
  Future<WithdrawalResponse> requestWithdrawal(WithdrawalRequest request) async {
    final response = await _apiClient.post(
      ApiConstants.withdraw,
      data: request.toJson(),
    );
    return WithdrawalResponse.fromJson(response.data as Map<String, dynamic>);
  }
}