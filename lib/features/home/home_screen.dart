import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../core/navigation/main_scaffold.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/widgets/store_logo.dart';
import '../../core/widgets/press_scale.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/models/user_model.dart';
import '../auth/screens/login_screen.dart';
import 'models/home_models.dart';
import 'providers/home_provider.dart';
import '../stores/store_detail_screen.dart';
import '../stores/stores_listing_screen.dart';
import '../search/global_search_screen.dart';

final _homeSelectedCategoryProvider = StateProvider.autoDispose<String>((ref) => 'Most Popular');
final _homeDealsExpandedProvider = StateProvider.autoDispose<bool>((ref) => false);

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

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ProviderSubscription<AsyncValue<User?>> _authSub;

  @override
  void initState() {
    super.initState();

    // When auth state changes (login/logout), refresh home data so wallet/personalized
    // sections update without requiring a manual pull-to-refresh.
    _authSub = ref.listenManual<AsyncValue<User?>>(authProvider, (previous, next) {
      final prevId = previous?.asData?.value?.id;
      final nextId = next.asData?.value?.id;
      if (prevId != nextId) {
        ref.invalidate(homeDataProvider);
      }
    });
  }

  @override
  void dispose() {
    _authSub.close();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final homeData = ref.watch(homeDataProvider);
    final user = ref.watch(authProvider.select((v) => v.asData?.value));
    final isGuest = user == null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.scaffoldBg,
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: homeData.when(
        data: (data) => RefreshIndicator(
          color: AppTheme.primaryBlue,
          onRefresh: () async {
            ref.invalidate(homeDataProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: 16,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return const SizedBox(height: 12);
                case 1:
                  // WALLET HERO (logged-in) OR LOGIN CTA (guest)
                  return isGuest
                      ? _LoginCtaCard(
                          onLogin: () async {
                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(popOnSuccess: true),
                              ),
                            );
                            if (!mounted) return;
                            if (ok == true) {
                              ref.invalidate(homeDataProvider);
                            }
                          },
                        )
                      : _WalletHeroCard(wallet: data.wallet);
                case 2:
                  return const SizedBox(height: 12);
                case 3:
                  return const _SearchBar();
                case 4:
                  return const SizedBox(height: 20);
                case 5:
                  return _TrendingStores(stores: data.topStores);
                case 6:
                  return const SizedBox(height: 24);
                case 7:
                  return const _TopCategories();
                case 8:
                  return const SizedBox(height: 24);
                case 9:
                  return _DealCardsSection(stores: data.topStores);
                case 10:
                  return const SizedBox(height: 24);
                case 11:
                  return _HowCashbackWorksCard();
                case 12:
                  return const SizedBox(height: 24);
                case 13:
                  return _FlashDealSection(stores: data.topStores);
                case 14:
                  return const SizedBox(height: 24);
                case 15:
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TodaysTopDeals(stores: data.topStores),
                      const SizedBox(height: 32),
                    ],
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
        error: (err, stack) => _buildErrorState(err),
      ),
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
                  color: Colors.white.withAlpha(77),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComingSoonScreen(
                  title: 'Daily Spin',
                  message: 'This feature is coming soon. Stay tuned!',
                ),
              ),
            );
          },
        ),
        // Bell icon
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComingSoonScreen(
                  title: 'Notifications',
                  message: 'This feature is coming soon. Stay tuned!',
                ),
              ),
            );
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
          Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authProvider);
              final user = authState.maybeWhen(data: (u) => u, orElse: () => null);

              String formatMoney(num value, {String currency = 'INR'}) {
                final symbol = currency == 'INR' ? '₹' : '$currency ';
                return '$symbol${value.toStringAsFixed(2)}';
              }

              final walletAsync = user == null
                  ? const AsyncValue<WalletSummary?>.data(null)
                  : ref.watch(homeDataProvider).maybeWhen(
                        data: (data) => AsyncValue.data(data.wallet),
                        loading: () => const AsyncValue.loading(),
                        error: (e, s) => AsyncValue.error(e, s),
                        orElse: () => const AsyncValue.loading(),
                      );

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () {
                          Navigator.pop(context);
                          final scope = MainScaffoldScope.maybeOf(context);
                          if (scope != null) {
                            scope.setIndex(4);
                            return;
                          }
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                    ),
                    Column(
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
                              Text(
                                user == null ? 'Hello User!' : user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user == null ? 'user@gmail.com' : user.email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              if (user == null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'login to earn !',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (user != null) ...[
                      const SizedBox(height: 8),
                      walletAsync.when(
                        data: (wallet) {
                          if (wallet == null) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Earned', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatMoney(wallet.totalEarned, currency: wallet.currency),
                                      style: const TextStyle(
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
                                    const Text('Pending', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatMoney(wallet.pending, currency: wallet.currency),
                                      style: const TextStyle(
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
                                    const Text('Confirmed', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatMoney(wallet.available, currency: wallet.currency),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ),
                        error: (e, s) => const SizedBox.shrink(),
                      ),
                    ] else
                      const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Menu items with new structure
          Expanded(
            child: Builder(
              builder: (context) {
                final items = <Widget>[
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
                        onTap: () {
                          Navigator.pop(context);
                          final scope = MainScaffoldScope.maybeOf(context);
                          if (scope != null) {
                            scope.openStores();
                            return;
                          }
                          Navigator.pushNamed(context, '/stores');
                        },
                        iconColor: Color(0xFFFF6B35),
                      ),
                      _DrawerItem(
                        icon: Icons.star,
                        title: 'Top Product',
                        onTap: () {
                          Navigator.pop(context);
                          final scope = MainScaffoldScope.maybeOf(context);
                          if (scope != null) {
                            scope.setIndex(2);
                            return;
                          }
                          Navigator.pushNamed(context, '/wallet');
                        },
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
                        onTap: () {
                          Navigator.pop(context);
                          final scope = MainScaffoldScope.maybeOf(context);
                          if (scope != null) {
                            scope.openStores(category: 'Electronics');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoresListingScreen(category: 'Electronics'),
                            ),
                          );
                        },
                        iconColor: AppTheme.primaryBlue,
                      ),
                      _DrawerItem(
                        icon: Icons.checkroom,
                        title: 'Fashion',
                        onTap: () {
                          Navigator.pop(context);
                          final scope = MainScaffoldScope.maybeOf(context);
                          if (scope != null) {
                            scope.openStores(category: 'Fashion');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoresListingScreen(category: 'Fashion'),
                            ),
                          );
                        },
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
                        onTap: () {
                          Navigator.pop(context);
                          final scope = MainScaffoldScope.maybeOf(context);
                          if (scope != null) {
                            scope.setIndex(3);
                            return;
                          }
                          Navigator.pushNamed(context, '/missing_cashback');
                        },
                        iconColor: Color(0xFF4CAF50),
                      ),
                      _DrawerItem(
                        icon: Icons.star_border,
                        title: 'Rate the app',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ComingSoonScreen(
                                title: 'Help / About',
                                message: 'This feature is coming soon. Stay tuned!',
                              ),
                            ),
                          );
                        },
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
                    onPressed: () {
                      Navigator.pop(context);
                      final scope = MainScaffoldScope.maybeOf(context);
                      if (scope != null) {
                        scope.openStores();
                        return;
                      }
                      Navigator.pushNamed(context, '/stores');
                    },
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
                ];

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, index) => items[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err) {
    final isNetwork = err is ApiNetworkException;
    final isTimeout = err is ApiTimeoutException;
    final isServer = err is ApiServerException;
    final isUnauth = err is ApiUnauthenticatedException;

    final title = isNetwork
      ? 'No Internet Connection'
      : isTimeout
        ? 'Request timed out'
        : isServer
          ? 'Server temporarily unavailable'
          : isUnauth
            ? 'You are signed out'
            : 'Oops! Something went wrong';

    final message = isNetwork
      ? 'Please check your internet connection and try again'
      : isTimeout
        ? 'The server took too long to respond. Please try again.'
        : isServer
          ? (err as ApiServerException).message
          : isUnauth
            ? 'You can still browse stores as a guest.'
            : err.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              (isNetwork || isTimeout) ? Icons.wifi_off_rounded : Icons.error_outline,
              size: 56,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () => ref.invalidate(homeDataProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isNetwork || isTimeout)
                      ? AppTheme.primaryBlue
                      : AppTheme.cashbackOrange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCtaCard extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginCtaCard({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login to start earning cashback',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Browse stores as guest, login to activate cashback.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Login to earn cashback',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
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
  final Color? iconColor;
  
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.textPrimary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      dense: true,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM WALLET HERO
// ═══════════════════════════════════════════════════════════════════════════
class _WalletHeroCard extends StatelessWidget {
  final WalletSummary wallet;

  const _WalletHeroCard({required this.wallet});

  String _formatInr(double value) {
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Cashback',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatInr(wallet.totalEarned),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final scope = MainScaffoldScope.maybeOf(context);
                    if (scope != null) {
                      scope.setIndex(2);
                      return;
                    }
                    Navigator.pushNamed(context, '/wallet');
                  },
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                  child: const Text(
                    'Wallet →',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _WalletMetric(
                    label: 'Available',
                    value: _formatInr(wallet.available),
                    valueColor: AppTheme.cashbackGreen,
                    background: AppTheme.accentTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WalletMetric(
                    label: 'Pending',
                    value: _formatInr(wallet.pending),
                    valueColor: AppTheme.textPrimary,
                    background: AppTheme.accentYellow,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color background;

  const _WalletMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CASHBACK WORKFLOW (new)
// ═══════════════════════════════════════════════════════════════════════════
class _HowCashbackWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How cashback works',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const _HowStep(
              icon: Icons.search,
              color: AppTheme.accentYellow,
              title: 'Pick a store',
              subtitle: 'Open any store from KashAndaz',
            ),
            const SizedBox(height: 10),
            const _HowStep(
              icon: Icons.shopping_bag_outlined,
              color: AppTheme.accentPink,
              title: 'Shop as usual',
              subtitle: 'Complete checkout in the same session',
            ),
            const SizedBox(height: 10),
            const _HowStep(
              icon: Icons.verified_outlined,
              color: AppTheme.accentTeal,
              title: 'Earn cashback',
              subtitle: 'We track it and add it to your wallet',
            ),
          ],
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _HowStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ComingSoonScreen extends StatelessWidget {
  final String title;
  final String message;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Lightweight interaction + logo fallback
// ═══════════════════════════════════════════════════════════════════════════
class _Pressable extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _Pressable({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

class _StoreLogoOrMonogram extends StatelessWidget {
  final String url;
  final String name;
  final double size;

  const _StoreLogoOrMonogram({
    required this.url,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Never show initials-based logos for stores.
    return StoreLogo(url: url, storeName: name, size: 40);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            SlidePageRoute(page: const GlobalSearchScreen()),
          );
        },
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
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// TRENDING STORES (like reference image 3)
// ═══════════════════════════════════════════════════════════════════════════
class _TrendingStores extends StatelessWidget {
  final List<Store> stores;
  
  const _TrendingStores({required this.stores});

  @override
  Widget build(BuildContext context) {
    final visible = stores.where((s) => s.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.store, color: AppTheme.primaryBlue, size: 28),
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
              InkWell(
                onTap: () {
                  final scope = MainScaffoldScope.maybeOf(context);
                  if (scope != null) {
                    scope.openStores();
                    return;
                  }
                  Navigator.pushNamed(context, '/stores');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Store cards horizontal scroll
        SizedBox(
          height: 214,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(right: index < visible.length - 1 ? 12 : 0),
                child: SizedBox(
                  width: 188,
                  child: _TrendingStoreCard(
                    store: visible[index],
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
  final Store store;
  
  const _TrendingStoreCard({
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () {
        Navigator.push(
          context,
          SlidePageRoute(page: StoreDetailScreen(store: store)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Earn Cashback',
                style: TextStyle(
                  color: AppTheme.cashbackOrange,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StoreLogoOrMonogram(url: store.logoUrl, name: store.name, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    store.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'Earn ${store.cashbackRate} Cashback',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.cashbackGreen,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(page: StoreDetailScreen(store: store)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Earn Cashback',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP CATEGORIES (like reference image 2)
// ═══════════════════════════════════════════════════════════════════════════
class _TopCategories extends ConsumerWidget {
  const _TopCategories();

  static const List<_CategorySpec> _categories = [
    _CategorySpec(
      label: 'Most\nPopular',
      category: null,
      icon: Icons.local_fire_department,
      color: AppTheme.accentYellow,
    ),
    _CategorySpec(
      label: 'Fashion',
      category: 'Fashion',
      icon: Icons.checkroom,
      color: AppTheme.accentPink,
    ),
    _CategorySpec(
      label: 'Mobiles',
      category: 'Mobiles',
      icon: Icons.phone_android,
      color: AppTheme.accentPurple,
    ),
    _CategorySpec(
      label: 'Beauty',
      category: 'Beauty',
      icon: Icons.spa,
      color: AppTheme.accentTeal,
    ),
    _CategorySpec(
      label: 'Home',
      category: 'Home',
      icon: Icons.home,
      color: AppTheme.accentYellow,
    ),
    _CategorySpec(
      label: 'Education',
      category: 'Education',
      icon: Icons.school,
      color: AppTheme.accentPurple,
    ),
    _CategorySpec(
      label: 'Pharmacy',
      category: 'Pharmacy',
      icon: Icons.medical_services,
      color: AppTheme.accentTeal,
    ),
    _CategorySpec(
      label: 'Grocery',
      category: 'Grocery',
      icon: Icons.shopping_cart,
      color: AppTheme.accentPink,
    ),
  ];

  static String? _toCategoryParam(String selectedCategory) {
    if (selectedCategory == 'Most Popular') {
      return null;
    }
    // Keep lightweight + tolerant of backend naming differences.
    if (selectedCategory == 'Beauty & Grooming') {
      return 'Beauty';
    }
    if (selectedCategory == 'Home & Appliances') {
      return 'Home';
    }
    return selectedCategory;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(_homeSelectedCategoryProvider);
    final selectedCategoryParam = _toCategoryParam(selectedCategory);

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
              _Pressable(
                onTap: () {
                  final scope = MainScaffoldScope.maybeOf(context);
                  if (scope != null) {
                    scope.openStores(category: selectedCategoryParam);
                    return;
                  }
                  Navigator.push(
                    context,
                    SlidePageRoute(
                      page: StoresListingScreen(category: selectedCategoryParam),
                    ),
                  );
                },
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category circles - horizontal scrollable
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final spec = _categories[index];
              final isSelected = selectedCategory == (spec.category ?? 'Most Popular');
              return _CategoryCircle(
                label: spec.label,
                icon: spec.icon,
                color: spec.color,
                isSelected: isSelected,
                onTap: () {
                  ref.read(_homeSelectedCategoryProvider.notifier).state =
                      spec.category ?? 'Most Popular';
                },
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Real stores preview (never fake)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Builder(
            builder: (context) {
              final storesAsync = ref.watch(storesProvider(selectedCategoryParam));
              final fallbackTopStores = ref.watch(
                homeDataProvider.select(
                  (v) => v.asData?.value.topStores ?? const <Store>[],
                ),
              );

              return storesAsync.when(
                data: (stores) {
                  List<Store> preview = stores.take(4).toList();
                  if (preview.isEmpty) {
                    preview = fallbackTopStores.take(4).toList();
                  }

                  if (preview.isEmpty) {
                    return _Pressable(
                      onTap: () {
                        final scope = MainScaffoldScope.maybeOf(context);
                        if (scope != null) {
                          scope.openStores(category: selectedCategoryParam);
                          return;
                        }
                        Navigator.push(
                          context,
                          SlidePageRoute(
                            page: StoresListingScreen(category: selectedCategoryParam),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.store, color: AppTheme.primaryBlue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Browse stores and start earning cashback',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _StorePromoCard(store: preview[0])),
                          const SizedBox(width: 12),
                          Expanded(child: _StorePromoCard(store: preview.length > 1 ? preview[1] : preview[0])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StorePromoCard(store: preview.length > 2 ? preview[2] : preview[0])),
                          const SizedBox(width: 12),
                          Expanded(child: _StorePromoCard(store: preview.length > 3 ? preview[3] : preview[0])),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) {
                  return _Pressable(
                    onTap: () {
                      final scope = MainScaffoldScope.maybeOf(context);
                      if (scope != null) {
                        scope.openStores(category: selectedCategoryParam);
                        return;
                      }
                      Navigator.push(
                        context,
                        SlidePageRoute(
                          page: StoresListingScreen(category: selectedCategoryParam),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: const Text(
                        'Could not load stores right now. Tap to browse all stores.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategorySpec {
  final String label;
  final String? category;
  final IconData icon;
  final Color color;

  const _CategorySpec({
    required this.label,
    required this.category,
    required this.icon,
    required this.color,
  });
}

class _CategoryCircle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCircle({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final circleShadow = isSelected
        ? [
            BoxShadow(
              color: AppTheme.primaryBlue.withAlpha(64),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ];

    return _Pressable(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                width: 3,
              ),
              boxShadow: circleShadow,
            ),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                scale: isSelected ? 1.03 : 1.0,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(46),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _StorePromoCard extends StatelessWidget {
  final Store store;
  
  const _StorePromoCard({
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () {
        Navigator.push(
          context,
          SlidePageRoute(page: StoreDetailScreen(store: store)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Earn Cashback',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.cashbackOrange,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StoreLogoOrMonogram(
                  url: store.logoUrl,
                  name: store.name,
                  size: 44,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    store.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Earn ${store.cashbackRate} ${store.cashbackType == 'percentage' ? 'Cashback' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DEAL CARDS SECTION (Expandable)
// ═══════════════════════════════════════════════════════════════════════════
class _DealCardsSection extends ConsumerStatefulWidget {
  final List<Store> stores;

  const _DealCardsSection({required this.stores});

  @override
  ConsumerState<_DealCardsSection> createState() => _DealCardsSectionState();
}

class _DealCardsSectionState extends ConsumerState<_DealCardsSection> {
  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(_homeDealsExpandedProvider);

    final stores = widget.stores;
    final int maxCount;
    if (isExpanded) {
      maxCount = stores.length > 10 ? 10 : stores.length;
    } else {
      maxCount = stores.length > 3 ? 3 : stores.length;
    }
    final visible = stores.take(maxCount).toList();

    if (visible.isEmpty) {
      return _Pressable(
        onTap: () {
          final scope = MainScaffoldScope.maybeOf(context);
          if (scope != null) {
            scope.openStores();
            return;
          }
          Navigator.pushNamed(context, '/stores');
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: const [
              Icon(Icons.local_offer, color: AppTheme.primaryBlue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Explore stores & activate cashback deals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.accentYellow, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Deals for you',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(_homeDealsExpandedProvider.notifier).state = !isExpanded;
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isExpanded ? 'Show less' : 'See more',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final store = visible[index];
                return SizedBox(
                  width: 180,
                  child: _Pressable(
                    onTap: () {
                      Navigator.push(
                        context,
                        SlidePageRoute(page: StoreDetailScreen(store: store)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentYellow,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Earn Cashback',
                              style: TextStyle(
                                color: AppTheme.cashbackOrange,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StoreLogoOrMonogram(url: store.logoUrl, name: store.name, size: 52),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  store.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SlidePageRoute(page: StoreDetailScreen(store: store)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Earn ${store.cashbackRate}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
  final List<Store> stores;

  const _FlashDealSection({required this.stores});

  @override
  Widget build(BuildContext context) {
    final visible = stores.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.errorRed.withAlpha(115), width: 2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'FLASH DEAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Limited-time cashback rates',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              _Pressable(
                onTap: () {
                  final scope = MainScaffoldScope.maybeOf(context);
                  if (scope != null) {
                    scope.openStores();
                    return;
                  }
                  Navigator.pushNamed(context, '/stores');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            _Pressable(
              onTap: () {
                final scope = MainScaffoldScope.maybeOf(context);
                if (scope != null) {
                  scope.openStores();
                  return;
                }
                Navigator.pushNamed(context, '/stores');
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.store, color: AppTheme.primaryBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Browse stores to find the best cashback deals',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visible.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final store = visible[index];
                  final subtitle = (store.description ?? '').trim().isEmpty
                      ? 'Shop as usual — earn cashback automatically'
                      : store.description!.trim();

                  return SizedBox(
                    width: 240,
                    child: _Pressable(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(page: StoreDetailScreen(store: store)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.errorRed.withAlpha(89), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _StoreLogoOrMonogram(url: store.logoUrl, name: store.name, size: 52),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    store.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Earn ${store.cashbackRate} Cashback',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.cashbackGreen,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    SlidePageRoute(page: StoreDetailScreen(store: store)),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Earn Cashback',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
  final List<Store> stores;

  const _TodaysTopDeals({required this.stores});

  @override
  Widget build(BuildContext context) {
    final visible = stores.take(5).toList();
    final bg = <List<Color>>[
      [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
      [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
      [const Color(0xFF004D40), const Color(0xFF00695C)],
      [const Color(0xFF263238), const Color(0xFF37474F)],
      [const Color(0xFFBF360C), const Color(0xFFD84315)],
    ];

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
              _Pressable(
                onTap: () {
                  final scope = MainScaffoldScope.maybeOf(context);
                  if (scope != null) {
                    scope.openStores();
                    return;
                  }
                  Navigator.pushNamed(context, '/stores');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Deal cards
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Pressable(
              onTap: () {
                final scope = MainScaffoldScope.maybeOf(context);
                if (scope != null) {
                  scope.openStores();
                  return;
                }
                Navigator.pushNamed(context, '/stores');
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Text(
                  'Browse stores to see today\'s top cashback rates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: visible.length > 3 ? 3 : visible.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final store = visible[index];
                final colors = bg[index % bg.length];
                final subtitle = (store.description ?? '').trim().isEmpty
                    ? 'Tap to activate cashback and shop'
                    : store.description!.trim();

                return SizedBox(
                  width: 210,
                  child: _Pressable(
                    onTap: () {
                      Navigator.push(
                        context,
                        SlidePageRoute(page: StoreDetailScreen(store: store)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earn ${store.cashbackRate}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _StoreLogoOrMonogram(
                                    url: store.logoUrl,
                                    name: store.name,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    store.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Earn Cashback',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
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
