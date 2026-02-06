import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../core/widgets/store_logo.dart';
import '../../core/utils/page_transitions.dart';
import '../home/models/home_models.dart';
import '../home/providers/home_provider.dart';
import '../stores/store_detail_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  String _query = '';

  static const _categories = <String>[
    'Fashion',
    'Electronics',
    'Beauty',
    'Home',
    'Travel',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    // Auto-focus after first frame so the keyboard comes up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _query = _controller.text.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: storesAsync.when(
          data: (stores) {
            final filteredStores = _filterStores(stores, _query);
            final filteredCategories = _filterCategories(_query);

            final hasAnyResults = filteredStores.isNotEmpty || filteredCategories.isNotEmpty;
            final showEmpty = _query.isNotEmpty && !hasAnyResults;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSearchInput()),

                if (showEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else ...[
                  // Stores (priority 1)
                  SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Stores'),
                  ),
                  if (filteredStores.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 14),
                        child: Text(
                          'No matching stores yet.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList.separated(
                        itemCount: filteredStores.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final store = filteredStores[index];
                          return _StoreResultCard(
                            store: store,
                            onTap: () => _openStore(store),
                          );
                        },
                      ),
                    ),

                  // Categories (priority 2)
                  SliverToBoxAdapter(
                    child: _SectionHeader(title: 'Categories'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverList.separated(
                      itemCount: filteredCategories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final name = filteredCategories[index];
                        return _CategoryCard(
                          title: name,
                          onTap: () {
                            Navigator.push(
                              context,
                              SlidePageRoute(
                                page: const ComingSoonScreen(
                                  title: 'Categories',
                                  message: 'Categories search is coming soon. Stay tuned!',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          ),
          error: (err, stack) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 52, color: AppTheme.errorRed),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load stores',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(storesProvider(null)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search stores, brands, categories',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  List<Store> _filterStores(List<Store> stores, String query) {
    final q = query.trim().toLowerCase();
    final activeStores = stores.where((s) => s.isActive).toList();
    if (q.isEmpty) {
      return activeStores;
    }

    return activeStores
        .where((s) => s.name.toLowerCase().contains(q))
        .toList();
  }

  List<String> _filterCategories(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return _categories;
    }
    return _categories.where((c) => c.toLowerCase().contains(q)).toList();
  }

  void _openStore(Store store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreDetailScreen(store: store),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _StoreResultCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const _StoreResultCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _StoreLogo(logoUrl: store.logoUrl, storeName: store.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Up to ${store.cashbackRate} Cashback',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1FA463),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _CategoryCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Icon(Icons.category, color: AppTheme.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  final String logoUrl;
  final String storeName;

  const _StoreLogo({required this.logoUrl, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return StoreLogo(url: logoUrl, storeName: storeName);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 60, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try searching for a different store or keyword',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
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
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
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
