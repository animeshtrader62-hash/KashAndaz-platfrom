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
  final String logoUrl;
  final String cashbackRate;
  final String cashbackType; // 'percentage' or 'flat'
  final bool isActive;
  final String? category;

  Store({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.cashbackRate,
    required this.cashbackType,
    required this.isActive,
    this.category,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String,
      cashbackRate: json['cashback_rate'] as String,
      cashbackType: json['cashback_type'] as String,
      isActive: json['is_active'] as bool? ?? true,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'cashback_rate': cashbackRate,
      'cashback_type': cashbackType,
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
