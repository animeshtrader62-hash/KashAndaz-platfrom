import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/page_transitions.dart';
import 'providers/home_provider.dart';
import '../stores/store_detail_screen.dart';

/// Home Screen - EXACT STRUCTURE FROM HAND-DRAWN UI
/// 
/// Structure:
/// 1. AppBar (Flipkart Blue) - Hamburger + Logo + Daily Spin + Bell
/// 2. Search Bar
/// 3. Trending Stores (horizontal scroll)
/// 4. Top Categories (round circles)
/// 5. Deal Cards (expandable)
/// 6. Flash Deal (with timer)
/// 7. Top Rated Products / Products
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.scaffoldBg,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: homeData.when(
        data: (data) => RefreshIndicator(
          color: AppTheme.cashbackOrange,
          onRefresh: () async {
            ref.invalidate(homeDataProvider);
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                
                // SEARCH BAR
                _SearchBar(),
                
                const SizedBox(height: 20),
                
                // TRENDING STORES (like reference image 3) - RIGHT AFTER SEARCH
                _TrendingStores(stores: data.topStores),
                
                const SizedBox(height: 24),
                
                // TOP CATEGORIES (like reference image 2)
                _TopCategories(),
                
                const SizedBox(height: 24),
                
                // FLASH DEAL (like reference image 1)
                _FlashDealSection(),
                
                const SizedBox(height: 24),
                
                // TODAY'S TOP DEALS (like reference image 5)
                _TodaysTopDeals(),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
        error: (err, stack) => _buildErrorState(),
      ),
      bottomNavigationBar: _buildBottomNav(context, 0),
    );
  }

  /// AppBar - Flipkart Blue with Hamburger + Logo + Daily Spin + Bell
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryBlue,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(
        'KashAndaz',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        // Daily Spin (rainbow colored spin wheel)
        IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF00CED1), // Cyan
                  Color(0xFF0000FF), // Blue
                  Color(0xFF9370DB), // Purple
                  Color(0xFFFF1493), // Pink/Magenta
                  Color(0xFFFF6347), // Orange/Red
                  Color(0xFFFFA500), // Orange
                  Color(0xFFFFD700), // Yellow/Gold
                  Color(0xFF7CFC00), // Green
                  Color(0xFF00CED1), // Back to Cyan
                ],
                startAngle: 0,
                endAngle: 6.28,
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    'SPIN',
                    style: TextStyle(
                      fontSize: 6,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9370DB),
                    ),
                  ),
                ),
              ),
            ),
          ),
          onPressed: () {
            // TODO: Navigate to daily spin
          },
        ),
        // Bell icon
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// Drawer - 3 Dot Menu (with user profile header like reference image 4)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // User Profile Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3A5A6C), Color(0xFF4A6A7C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Profile avatar
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Name',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'user@email.com',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Pending',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹840.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white30),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Approved',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹9.90',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white30),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Redeemed',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹1030.48',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Menu items with new structure
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Category heading
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                
                // First Round Circle Grouping
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFE8E8E8), width: 1),
                  ),
                  child: Column(
                    children: [
                      _DrawerItem(
                        icon: Icons.local_fire_department,
                        title: 'High cashback Stores',
                        onTap: () {},
                        iconColor: Color(0xFFFF6B35),
                      ),
                      _DrawerItem(
                        icon: Icons.star,
                        title: 'Top Product',
                        onTap: () {},
                        iconColor: Color(0xFFFFD700),
                      ),
                    ],
                  ),
                ),
                
                // Second Round Circle Grouping
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFD6EAF8), width: 1),
                  ),
                  child: Column(
                    children: [
                      _DrawerItem(
                        icon: Icons.devices,
                        title: 'Electronics',
                        onTap: () {},
                        iconColor: AppTheme.primaryBlue,
                      ),
                      _DrawerItem(
                        icon: Icons.checkroom,
                        title: 'Fashion',
                        onTap: () {},
                        iconColor: Color(0xFFE91E63),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Third Round Circle Grouping (Share & Rate)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF9F0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFFFE4CC), width: 1),
                  ),
                  child: Column(
                    children: [
                      _DrawerItem(
                        icon: Icons.share,
                        title: 'Share & earn',
                        onTap: () {},
                        iconColor: Color(0xFF4CAF50),
                      ),
                      _DrawerItem(
                        icon: Icons.star_border,
                        title: 'Rate the app',
                        onTap: () {},
                        iconColor: Color(0xFFFF9800),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Browse all categories button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Browse all categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 16),
          const Text('Oops! Something went wrong'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(homeDataProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cashbackOrange,
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation - 5 ICONS (Home, Stores, WALLET, Missing, Profile)
  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textLight,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Stores',
          ),
          // WALLET - HIGHLIGHTED IN CIRCLE
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cashbackOrange.withOpacity(0.1),
                border: Border.all(color: AppTheme.cashbackOrange, width: 2),
              ),
              child: const Icon(Icons.account_balance_wallet, size: 24),
            ),
            label: 'Wallet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Missing',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              // TODO: Navigate to stores
              break;
            case 2:
              Navigator.pushNamed(context, '/wallet');
              break;
            case 3:
              // TODO: Navigate to missing cashback
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DRAWER ITEM
// ═══════════════════════════════════════════════════════════════════════════
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? textColor ?? AppTheme.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      dense: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Text(
              'Find your favourite Products',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  
  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'view all',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.cashbackOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRENDING STORES (like reference image 3)
// ═══════════════════════════════════════════════════════════════════════════
class _TrendingStores extends StatelessWidget {
  final List<dynamic> stores;
  
  const _TrendingStores({required this.stores});

  @override
  Widget build(BuildContext context) {
    final storeData = [
      {'name': 'Flipkart', 'offers': '57', 'rate': '7%', 'type': 'Reward'},
      {'name': 'Amazon', 'offers': '71', 'rate': '1.95%', 'type': 'Voucher Cash'},
      {'name': 'Ajio', 'offers': '51', 'rate': '13%', 'type': 'Cashback'},
      {'name': 'Myntra', 'offers': '42', 'rate': '6%', 'type': 'Cashback'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.store, color: AppTheme.cashbackOrange, size: 28),
              const SizedBox(width: 8),
              const Text(
                'Trending Stores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Store cards horizontal scroll
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: storeData.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < storeData.length - 1 ? 12 : 0),
                child: SizedBox(
                  width: 170,
                  child: _TrendingStoreCard(
                    storeName: storeData[index]['name']!,
                    offers: storeData[index]['offers']!,
                    rate: storeData[index]['rate']!,
                    type: storeData[index]['type']!,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingStoreCard extends StatelessWidget {
  final String storeName;
  final String offers;
  final String rate;
  final String type;
  
  const _TrendingStoreCard({
    required this.storeName,
    required this.offers,
    required this.rate,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFDCC4), Color(0xFFFFF0E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Offers count
          Text(
            '$offers Offers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Store logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              storeName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Rate
          Text(
            'Up to $rate',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            type,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Reward Rates link
          Text(
            'Reward Rates',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.cashbackOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP CATEGORIES (like reference image 2)
// ═══════════════════════════════════════════════════════════════════════════
class _TopCategories extends StatefulWidget {
  @override
  State<_TopCategories> createState() => _TopCategoriesState();
}

class _TopCategoriesState extends State<_TopCategories> {
  String selectedCategory = 'Most Popular';
  
  final Map<String, List<Map<String, String>>> categoryStores = {
    'Most Popular': [
      {'name': 'Amazon', 'badge': 'Upto 80% Off', 'cashback': 'Upto 1.50%\nCashback'},
      {'name': 'Flipkart', 'badge': 'Sale Live Now', 'cashback': 'Upto 7%\nCashback'},
      {'name': 'Myntra', 'badge': 'Sale Live Now', 'cashback': 'Upto 6%\nCashback'},
      {'name': 'Ajio', 'badge': 'Sale Live Now', 'cashback': 'Upto 10%\nCashback'},
    ],
    'Fashion': [
      {'name': 'Myntra', 'badge': 'Men Shirts', 'cashback': 'Upto 6%\nCashback'},
      {'name': 'Ajio', 'badge': 'Women Wear', 'cashback': 'Upto 10%\nCashback'},
      {'name': 'Zara', 'badge': 'New Arrivals', 'cashback': 'Upto 5%\nCashback'},
      {'name': 'H&M', 'badge': 'Flat 50% Off', 'cashback': 'Upto 8%\nCashback'},
    ],
    'Mobiles': [
      {'name': 'Amazon', 'badge': 'Smartphones', 'cashback': 'Upto 1.50%\nCashback'},
      {'name': 'Flipkart', 'badge': 'Accessories', 'cashback': 'Upto 7%\nCashback'},
      {'name': 'Croma', 'badge': 'Best Deals', 'cashback': 'Upto 4%\nCashback'},
      {'name': 'Reliance', 'badge': 'JioPhone', 'cashback': 'Upto 3%\nCashback'},
    ],
    'Beauty & Grooming': [
      {'name': 'Nykaa', 'badge': 'Makeup', 'cashback': 'Upto 12%\nCashback'},
      {'name': 'Purplle', 'badge': 'Skincare', 'cashback': 'Upto 15%\nCashback'},
      {'name': 'Amazon', 'badge': 'Beauty Sale', 'cashback': 'Upto 1.50%\nCashback'},
      {'name': 'Flipkart', 'badge': 'Health & Beauty', 'cashback': 'Upto 7%\nCashback'},
    ],
    'Home & Appliances': [
      {'name': 'Amazon', 'badge': 'Home Decor', 'cashback': 'Upto 1.50%\nCashback'},
      {'name': 'Flipkart', 'badge': 'Appliances', 'cashback': 'Upto 7%\nCashback'},
      {'name': 'Pepperfry', 'badge': 'Furniture', 'cashback': 'Upto 10%\nCashback'},
      {'name': 'Urban Ladder', 'badge': 'Best Deals', 'cashback': 'Upto 8%\nCashback'},
    ],
    'Education': [
      {'name': 'Udemy', 'badge': 'Online Courses', 'cashback': 'Upto 15%\nCashback'},
      {'name': 'Coursera', 'badge': 'Certificates', 'cashback': 'Upto 12%\nCashback'},
      {'name': 'upGrad', 'badge': 'Degree Programs', 'cashback': 'Upto 10%\nCashback'},
      {'name': 'Great Learning', 'badge': 'Free Courses', 'cashback': 'Upto 8%\nCashback'},
    ],
    'Pharmacy': [
      {'name': '1mg', 'badge': 'Medicine', 'cashback': 'Upto 20%\nCashback'},
      {'name': 'PharmEasy', 'badge': 'Health Products', 'cashback': 'Upto 18%\nCashback'},
      {'name': 'Netmeds', 'badge': 'Lab Tests', 'cashback': 'Upto 15%\nCashback'},
      {'name': 'Apollo', 'badge': 'Wellness', 'cashback': 'Upto 12%\nCashback'},
    ],
    'Grocery': [
      {'name': 'BigBasket', 'badge': 'Fresh Produce', 'cashback': 'Upto 5%\nCashback'},
      {'name': 'Blinkit', 'badge': '10 Min Delivery', 'cashback': 'Upto 3%\nCashback'},
      {'name': 'Amazon Fresh', 'badge': 'Groceries', 'cashback': 'Upto 1.50%\nCashback'},
      {'name': 'Swiggy Instamart', 'badge': 'Daily Needs', 'cashback': 'Upto 4%\nCashback'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '🔥',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Top categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Category circles - horizontal scrollable
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryCircle(
                label: 'Most\nPopular',
                gradient: LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
                ),
                innerText: 'MOST\nPOPULAR',
                innerTextSize: 8,
                innerColor: AppTheme.primaryBlue,
                isSelected: selectedCategory == 'Most Popular',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Most Popular';
                  });
                },
              ),
              _CategoryCircle(
                label: 'Fashion',
                image: Icons.checkroom,
                gradient: LinearGradient(
                  colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5)],
                ),
                isSelected: selectedCategory == 'Fashion',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Fashion';
                  });
                },
              ),
              _CategoryCircle(
                label: 'Mobiles',
                image: Icons.phone_android,
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
                ),
                isSelected: selectedCategory == 'Mobiles',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Mobiles';
                  });
                },
              ),
              _CategoryCircle(
                label: 'Beauty &\nGrooming',
                image: Icons.spa,
                gradient: LinearGradient(
                  colors: [Color(0xFFEC407A), Color(0xFFF06292)],
                ),
                isSelected: selectedCategory == 'Beauty & Grooming',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Beauty & Grooming';
                  });
                },
              ),
              _CategoryCircle(
                label: 'Home &\nAppliances',
                image: Icons.home,
                gradient: LinearGradient(
                  colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                ),
                isSelected: selectedCategory == 'Home & Appliances',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Home & Appliances';
                  });
                },
              ),
              _CategoryCircle(
                label: 'Education',
                image: Icons.school,
                gradient: LinearGradient(
                  colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
                ),
                isSelected: selectedCategory == 'Education',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Education';
                  });
                },
              ),
              _CategoryCircle(
                label: 'Pharmacy',
                image: Icons.medical_services,
                gradient: LinearGradient(
                  colors: [Color(0xFFEF5350), Color(0xFFE57373)],
                ),
                isSelected: selectedCategory == 'Pharmacy',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Pharmacy';
                  });
                },
              ),
              _CategoryCircle(
                label: 'Grocery',
                image: Icons.shopping_cart,
                gradient: LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF81C784)],
                ),
                isSelected: selectedCategory == 'Grocery',
                onTap: () {
                  setState(() {
                    selectedCategory = 'Grocery';
                  });
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Store cards grid - changes based on selected category
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StorePromoCard(
                      storeName: categoryStores[selectedCategory]![0]['name']!,
                      badge: categoryStores[selectedCategory]![0]['badge']!,
                      cashback: categoryStores[selectedCategory]![0]['cashback']!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StorePromoCard(
                      storeName: categoryStores[selectedCategory]![1]['name']!,
                      badge: categoryStores[selectedCategory]![1]['badge']!,
                      cashback: categoryStores[selectedCategory]![1]['cashback']!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StorePromoCard(
                      storeName: categoryStores[selectedCategory]![2]['name']!,
                      badge: categoryStores[selectedCategory]![2]['badge']!,
                      cashback: categoryStores[selectedCategory]![2]['cashback']!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StorePromoCard(
                      storeName: categoryStores[selectedCategory]![3]['name']!,
                      badge: categoryStores[selectedCategory]![3]['badge']!,
                      cashback: categoryStores[selectedCategory]![3]['cashback']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final IconData? image;
  final Color? textColor;
  final Color? innerColor;
  final String? innerText;
  final double? innerTextSize;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _CategoryCircle({
    required this.label,
    required this.gradient,
    this.image,
    this.textColor,
    this.innerColor,
    this.innerText,
    this.innerTextSize,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                border: isSelected 
                    ? Border.all(color: AppTheme.primaryBlue, width: 3) 
                    : null,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: innerColor != null && innerColor != Colors.transparent
                  ? Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: innerColor,
                        ),
                        child: image != null
                            ? Icon(image, color: Colors.white, size: 28)
                            : innerText != null
                                ? Center(
                                    child: Text(
                                      innerText!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: innerTextSize ?? 8,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      label.split('\n')[0].toUpperCase(),
                                      style: TextStyle(
                                        color: textColor ?? Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                      ),
                    )
                  : image != null
                      ? Icon(image, color: Colors.white, size: 36)
                      : Center(
                          child: Text(
                            label.split('\n')[0].toUpperCase(),
                            style: TextStyle(
                              color: textColor ?? Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StorePromoCard extends StatelessWidget {
  final String storeName;
  final String badge;
  final String cashback;
  
  const _StorePromoCard({
    required this.storeName,
    required this.badge,
    required this.cashback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Store logo placeholder
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                storeName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Cashback button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              cashback,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEAL CARDS SECTION (Expandable)
// ═══════════════════════════════════════════════════════════════════════════
class _DealCardsSection extends StatefulWidget {
  @override
  State<_DealCardsSection> createState() => _DealCardsSectionState();
}

class _DealCardsSectionState extends State<_DealCardsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final deals = [
      {'store': 'Amazon.in', 'text': 'Upto 50% off'},
      {'store': 'Flipkart', 'text': 'Sale is live'},
      {'store': 'Ajio', 'text': 'Upto 60% off'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.yellow.shade700, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Deal cards
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _isExpanded ? deals.length : 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cashbackOrange, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          deals[index]['text']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deals[index]['store']!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upto 8% Cashback',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.cashbackOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // View all EXPAND button
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isExpanded ? 'Show less' : 'view all',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FLASH DEAL SECTION (like reference image 1)
// ═══════════════════════════════════════════════════════════════════════════
class _FlashDealSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB8B8B8), Color(0xFFD8D8D8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Title
          const Text(
            'FLASH DEAL',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.errorRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Ends in 20:58:37',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Deal cards horizontal scroll
          SizedBox(
            height: 310,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) {
                final deals = [
                  {'store': 'STRCH', 'discount': 'Flat 10% OFF', 'desc': 'On Premium, Flexible Women\'s Activewear', 'cashback': 'Flat 75%'},
                  {'store': 'Amazon', 'discount': 'Min 60% OFF', 'desc': 'Oversized sweatshirts, cargos & more', 'cashback': 'Upto 1.95%'},
                  {'store': 'Flipkart', 'discount': 'Sale is live', 'desc': 'Electronics, Fashion & more', 'cashback': 'Upto 7%'},
                ];
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.errorRed, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store logo + Today's Deal
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.scaffoldBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  deals[index]['store']![0],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Today's",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    "Deal",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Product image placeholder
                        Container(
                          height: 64,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.scaffoldBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(Icons.image, size: 36, color: AppTheme.textLight),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Discount
                              Text(
                                deals[index]['discount']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Description
                              Text(
                                deals[index]['desc']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Cashback
                              Text(
                                '${deals[index]['cashback']} Cashback',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Grab Deal button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Grab Deal',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // View All button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'View All',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TODAY'S TOP DEALS (like reference image 5)
// ═══════════════════════════════════════════════════════════════════════════
class _TodaysTopDeals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.local_fire_department, color: AppTheme.cashbackOrange, size: 28),
              const SizedBox(width: 8),
              const Text(
                "Today's Top Deals",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Deal cards
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              final deals = [
                {
                  'title': 'Min. 60% Off',
                  'desc': 'Oversized sweatshirts, cargos & more',
                  'store': 'amazon',
                  'cashback': 'Up to 1.95% PW Voucher...',
                  'bgColor': Color(0xFF4A0E0E),
                  'button': 'BUY NOW',
                },
                {
                  'title': '50-90% OFF',
                  'desc': 'This Is How We Slay',
                  'store': 'AJIO',
                  'cashback': 'Up to 13% PW Cashback',
                  'bgColor': Color(0xFF4A0E0E),
                  'button': '50-90% Off',
                },
                {
                  'title': 'Sale Live',
                  'desc': 'Fashion Sale on Myntra',
                  'store': 'Myntra',
                  'cashback': 'Up to 6% PW Cashback',
                  'bgColor': Color(0xFF4A0E0E),
                  'button': 'Grab Now',
                },
              ];
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [deals[index]['bgColor'] as Color, (deals[index]['bgColor'] as Color).withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deals[index]['title'] as String,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deals[index]['desc'] as String,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Store logo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            deals[index]['store'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deals[index]['button'] as String,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Cashback
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Text(
                          deals[index]['cashback'] as String,
                          style: TextStyle(
                            color: AppTheme.cashbackOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
