import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../models/home_models.dart';
import '../services/home_service.dart';

/// Provider for HomeService
final homeServiceProvider = Provider.autoDispose<HomeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeService(apiClient);
});

/// Provider for home data
final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final homeService = ref.watch(homeServiceProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return await homeService.getHomeData(cancelToken: cancelToken);
});

/// Provider for all stores
final storesProvider = FutureProvider.autoDispose.family<List<Store>, String?>((ref, category) async {
  final homeService = ref.watch(homeServiceProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return await homeService.getStores(category: category, cancelToken: cancelToken);
});
