import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/utils/constants.dart';
import '../models/home_models.dart';

/// Home service for fetching home screen data
class HomeService {
  final ApiClient _apiClient;

  HomeService(this._apiClient);

  /// Get home screen data (wallet + top stores)
  Future<HomeData> getHomeData({CancelToken? cancelToken}) async {
    try {
      final response = await _apiClient.get(ApiConstants.home, cancelToken: cancelToken);
      final data = (response.data is Map<String, dynamic>)
          ? (response.data as Map<String, dynamic>)
          : <String, dynamic>{};

      // Backend guarantee: always returns a safe shape; status may be present.
      // Treat empty but ok payload as success (wallet=0, stores=[]).
      return HomeData.fromJson(data);
    } on ApiUnauthenticatedException {
      // If a stale/invalid token is present, /api/home (optional auth) may return 401.
      // Guests must still be able to browse Home, so fall back to public stores.
      final stores = await getStores(cancelToken: cancelToken);
      final top = stores.length > 10 ? stores.sublist(0, 10) : stores;
      return HomeData(
        wallet: WalletSummary(totalEarned: 0, pending: 0, available: 0),
        topStores: top,
      );
    } on ApiServerException {
      // If /api/home fails (e.g., temporary backend issue), try to keep Home usable.
      try {
        final stores = await getStores(cancelToken: cancelToken);
        final top = stores.length > 10 ? stores.sublist(0, 10) : stores;
        return HomeData(
          wallet: WalletSummary(totalEarned: 0, pending: 0, available: 0),
          topStores: top,
        );
      } catch (_) {
        return HomeData(
          wallet: WalletSummary(totalEarned: 0, pending: 0, available: 0),
          topStores: const [],
        );
      }
    }
  }

  /// Get all stores
  Future<List<Store>> getStores({String? category, String? search, CancelToken? cancelToken}) async {
    final response = await _apiClient.get(
      ApiConstants.stores,
      queryParameters: {
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      },
      cancelToken: cancelToken,
    );
    
    final stores = (response.data['stores'] as List)
        .map((store) => Store.fromJson(store as Map<String, dynamic>))
        .toList();
    
    return stores;
  }
}
