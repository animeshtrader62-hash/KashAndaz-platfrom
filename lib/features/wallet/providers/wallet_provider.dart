import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';

/// Provider for WalletService
final walletServiceProvider = Provider<WalletService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletService(apiClient);
});

/// Provider for wallet data
final walletDataProvider = FutureProvider<WalletData>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return service.getWallet();
});