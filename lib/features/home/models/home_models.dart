/// Wallet summary model
class WalletSummary {
  final double totalEarned;
  final double pending;
  final double available;
  final String currency;

  WalletSummary({
    required this.totalEarned,
    required this.pending,
    required this.available,
    this.currency = 'INR',
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      totalEarned: (json['total_earned'] as num).toDouble(),
      pending: (json['pending'] as num).toDouble(),
      available: (json['available'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earned': totalEarned,
      'pending': pending,
      'available': available,
      'currency': currency,
    };
  }
}

/// Store model
class Store {
  final String id;
  final String name;
  final String? storeSlug;
  final String logoUrl;
  final String cashbackRate;
  final String cashbackType; // 'percentage' or 'flat'
  final int? popularityScore;
  final String? description;
  final bool isActive;
  final String? category;

  Store({
    required this.id,
    required this.name,
    this.storeSlug,
    required this.logoUrl,
    required this.cashbackRate,
    required this.cashbackType,
    this.popularityScore,
    this.description,
    required this.isActive,
    this.category,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      storeSlug: json['store_slug']?.toString(),
      logoUrl: (json['store_logo_url'] ?? json['logo_url'] ?? '').toString(),
      cashbackRate: json['cashback_rate'] as String,
      cashbackType: json['cashback_type'] as String,
      popularityScore: json['popularity_score'] is num
          ? (json['popularity_score'] as num).toInt()
          : int.tryParse((json['popularity_score'] ?? '').toString()),
      description: (json['store_description'] ?? json['description'])?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'store_slug': storeSlug,
      'logo_url': logoUrl,
      'store_logo_url': logoUrl,
      'cashback_rate': cashbackRate,
      'cashback_type': cashbackType,
      'popularity_score': popularityScore,
      'store_description': description,
      'is_active': isActive,
      'category': category,
    };
  }
}

/// Home data model (wallet + stores)
class HomeData {
  final WalletSummary wallet;
  final List<Store> topStores;

  HomeData({
    required this.wallet,
    required this.topStores,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      wallet: WalletSummary.fromJson(json['wallet'] as Map<String, dynamic>),
      topStores: (json['top_stores'] as List)
          .map((store) => Store.fromJson(store as Map<String, dynamic>))
          .toList(),
    );
  }
}
