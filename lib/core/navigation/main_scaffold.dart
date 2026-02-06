import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../features/home/home_screen.dart';
import '../../features/missing_cashback/missing_cashback_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/stores/stores_listing_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../core/utils/page_transitions.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  late int _currentIndex;
  String? _storesCategory;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  void _setIndex(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  static const Set<int> _protectedTabs = {2, 3, 4};

  Future<void> _handleBottomNavTap(int index) async {
    if (_currentIndex == index) return;

    // Home/Stores remain accessible to guests.
    if (!_protectedTabs.contains(index)) {
      _setIndex(index);
      return;
    }

    final authState = ref.read(authProvider);
    final user = authState.asData?.value;
    if (user != null) {
      _setIndex(index);
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      SlidePageRoute<bool>(page: const LoginScreen(popOnSuccess: true)),
    );
    if (!mounted) return;

    if (result == true) {
      _setIndex(index);
    }
  }

  void _openStores({String? category}) {
    if (_currentIndex == 1 && _storesCategory == category) return;
    setState(() {
      _storesCategory = category;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffoldScope(
      currentIndex: _currentIndex,
      setIndex: _setIndex,
      openStores: _openStores,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeScreen(),
            StoresListingScreen(category: _storesCategory),
            const WalletScreen(),
            const MissingCashbackScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: _handleBottomNavTap,
        ),
      ),
    );
  }
}

class MainScaffoldScope extends InheritedWidget {
  final int currentIndex;
  final void Function(int index) setIndex;
  final void Function({String? category}) openStores;

  const MainScaffoldScope({
    super.key,
    required super.child,
    required this.currentIndex,
    required this.setIndex,
    required this.openStores,
  });

  static MainScaffoldScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainScaffoldScope>();
  }

  @override
  bool updateShouldNotify(MainScaffoldScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cashbackOrange.withAlpha(26),
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
        onTap: onTap,
      ),
    );
  }
}
