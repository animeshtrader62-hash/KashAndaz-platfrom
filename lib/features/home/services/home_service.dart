import '../../../core/api/api_client.dart';
import '../../../core/utils/constants.dart';
import '../models/home_models.dart';

/// Home service for fetching home screen data
class HomeService {
  final ApiClient _apiClient;

  HomeService(this._apiClient);

  /// Get home screen data (wallet + top stores)
  Future<HomeData> getHomeData() async {
    final response = await _apiClient.get(ApiConstants.home);
    return HomeData.fromJson(response.data);
  }

  /// Get all stores
  Future<List<Store>> getStores({String? category, String? search}) async {
    final response = await _apiClient.get(
      ApiConstants.stores,
      queryParameters: {
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      },
    );
    
    final stores = (response.data['stores'] as List)
        .map((store) => Store.fromJson(store as Map<String, dynamic>))
        .toList();
    
    return stores;
  }
}
