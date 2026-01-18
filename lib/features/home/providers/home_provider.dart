import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/providers.dart';
import '../models/home_models.dart';
import '../services/home_service.dart';

/// Provider for HomeService
final homeServiceProvider = Provider<HomeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeService(apiClient);
});

/// Provider for home data (with mock data fallback)
final homeDataProvider = FutureProvider<HomeData>((ref) async {
  try {
    final homeService = ref.watch(homeServiceProvider);
    return await homeService.getHomeData();
  } catch (e) {
    // Return mock data if API fails
    return HomeData(
      wallet: WalletSummary(
        totalEarned: 5420.50,
        pending: 1250.00,
        available: 2500.00,
      ),
      topStores: [
        Store(
          id: '1',
          name: 'Amazon',
          logoUrl: 'https://logo.clearbit.com/amazon.in',
          cashbackRate: '5%',
          cashbackType: 'percentage',
          isActive: true,
          category: 'Shopping',
        ),
        Store(
          id: '2',
          name: 'Flipkart',
          logoUrl: 'https://logo.clearbit.com/flipkart.com',
          cashbackRate: '4%',
          cashbackType: 'percentage',
          isActive: true,
          category: 'Shopping',
        ),
        Store(
          id: '3',
          name: 'Myntra',
          logoUrl: 'https://logo.clearbit.com/myntra.com',
          cashbackRate: '6%',
          cashbackType: 'percentage',
          isActive: true,
          category: 'Fashion',
        ),
        Store(
          id: '4',
          name: 'Swiggy',
          logoUrl: 'https://logo.clearbit.com/swiggy.com',
          cashbackRate: '3%',
          cashbackType: 'percentage',
          isActive: true,
          category: 'Food',
        ),
      ],
    );
  }
});

/// Provider for all stores (with mock data fallback)
final storesProvider = FutureProvider.family<List<Store>, String?>((ref, category) async {
  try {
    final homeService = ref.watch(homeServiceProvider);
    return await homeService.getStores(category: category);
  } catch (e) {
    // Return mock stores if API fails
    return [
      Store(
        id: '1',
        name: 'Amazon',
        logoUrl: 'https://logo.clearbit.com/amazon.in',
        cashbackRate: '5%',
        cashbackType: 'percentage',
        isActive: true,
        category: 'Shopping',
      ),
      Store(
        id: '2',
        name: 'Flipkart',
        logoUrl: 'https://logo.clearbit.com/flipkart.com',
        cashbackRate: '4%',
        cashbackType: 'percentage',
        isActive: true,
        category: 'Shopping',
      ),
      Store(
        id: '3',
        name: 'Myntra',
        logoUrl: 'https://logo.clearbit.com/myntra.com',
        cashbackRate: '6%',
        cashbackType: 'percentage',
        isActive: true,
        category: 'Fashion',
      ),
      Store(
        id: '4',
        name: 'Swiggy',
        logoUrl: 'https://logo.clearbit.com/swiggy.com',
        cashbackRate: '3%',
        cashbackType: 'percentage',
        isActive: true,
        category: 'Food',
      ),
      Store(
        id: '5',
        name: 'Zomato',
        logoUrl: 'https://logo.clearbit.com/zomato.com',
        cashbackRate: '3.5%',
        cashbackType: 'percentage',
        isActive: true,
        category: 'Food',
      ),
      Store(
        id: '6',
        name: 'BookMyShow',
        logoUrl: 'https://logo.clearbit.com/bookmyshow.com',
        cashbackRate: '2%',
        cashbackType: 'percentage',
        isActive: true,
        category: 'Entertainment',
      ),
    ];
  }
});
