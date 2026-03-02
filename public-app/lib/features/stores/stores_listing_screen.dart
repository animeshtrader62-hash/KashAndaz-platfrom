import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/store_logo.dart';
import '../../core/utils/page_transitions.dart';

import '../../core/navigation/main_scaffold.dart';
import '../../theme/app_theme.dart';
import '../home/models/home_models.dart';
import '../home/providers/home_provider.dart';
import 'store_detail_screen.dart';

enum _StoreSort { highestCashback, popular, az }

class StoresListingScreen extends ConsumerStatefulWidget {
  final String? category;

  const StoresListingScreen({super.key, this.category});

  @override
  ConsumerState<StoresListingScreen> createState() => _StoresListingScreenState();
}

class _StoresListingScreenState extends ConsumerState<StoresListingScreen>
  with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  _StoreSort _sort = _StoreSort.highestCashback;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        setState(() {
          // local filter only
        });
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final storesAsync = ref.watch(storesProvider(widget.category));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Stores',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final scope = MainScaffoldScope.maybeOf(context);
            if (scope != null) {
              scope.setIndex(0);
              return;
            }
            Navigator.maybePop(context);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () {
              FocusScope.of(context).requestFocus(_searchFocusNode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildSortRow(),
            Expanded(
              child: storesAsync.when(
                data: (stores) {
                  final filtered = _applyLocalFilterAndSort(stores);
                  if (filtered.isEmpty) {
                    return const _EmptyState(
                      title: 'No stores available right now',
                      subtitle: 'Please check back later',
                    );
                  }
                  return RefreshIndicator(
                    color: AppTheme.primaryBlue,
                    onRefresh: () async {
                      ref.invalidate(storesProvider(widget.category));
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      cacheExtent: 300,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _StoreCard(
                          store: filtered[index],
                          onViewDetails: () => _openStoreDetails(filtered[index]),
                        );
                      },
                    ),
                  );
                },
                loading: () => const _StoresSkeletonList(),
                error: (err, stack) => _ErrorState(
                  error: err,
                  onRetry: () => ref.invalidate(storesProvider(widget.category)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: const Color(0xFFF5F7FA),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search stores like Amazon, Flipkart, Myntra',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      color: const Color(0xFFF5F7FA),
      child: Wrap(
        spacing: 10,
        children: [
          _SortChip(
            label: 'Highest Cashback',
            selected: _sort == _StoreSort.highestCashback,
            onTap: () => setState(() => _sort = _StoreSort.highestCashback),
          ),
          _SortChip(
            label: 'Popular',
            selected: _sort == _StoreSort.popular,
            onTap: () => setState(() => _sort = _StoreSort.popular),
          ),
          _SortChip(
            label: 'A–Z',
            selected: _sort == _StoreSort.az,
            onTap: () => setState(() => _sort = _StoreSort.az),
          ),
        ],
      ),
    );
  }

  List<Store> _applyLocalFilterAndSort(List<Store> stores) {
    final query = _searchController.text.trim().toLowerCase();

    var list = stores.where((s) => s.isActive).toList();

    if (query.isNotEmpty) {
      list = list.where((s) => s.name.toLowerCase().contains(query)).toList();
    }

    switch (_sort) {
      case _StoreSort.az:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _StoreSort.popular:
        list.sort(
          (a, b) => (b.popularityScore ?? 0).compareTo(a.popularityScore ?? 0),
        );
        break;
      case _StoreSort.highestCashback:
        list.sort(
          (a, b) => _cashbackNumeric(b).compareTo(_cashbackNumeric(a)),
        );
        break;
    }

    return list;
  }

  double _cashbackNumeric(Store store) {
    final raw = store.cashbackRate;
    final match = RegExp(r'([0-9]+(\.[0-9]+)?)').firstMatch(raw);
    if (match == null) {
      return 0;
    }
    return double.tryParse(match.group(1) ?? '') ?? 0;
  }

  void _openStoreDetails(Store store) {
    Navigator.push(
      context,
      SlidePageRoute(page: StoreDetailScreen(store: store)),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StoreCard extends StatefulWidget {
  final Store store;
  final VoidCallback onViewDetails;

  const _StoreCard({required this.store, required this.onViewDetails});

  @override
  State<_StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<_StoreCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final description = widget.store.description?.trim() ?? '';

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.white,
        elevation: 0.6,
        shadowColor: Colors.black12,
        borderRadius: radius,
        child: InkWell(
          onTap: widget.onViewDetails,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Logo(logoUrl: widget.store.logoUrl, storeName: widget.store.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF212121),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Up to ${widget.store.cashbackRate} Cashback',
                        style: const TextStyle(
                          color: Color(0xFF1FA463),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: widget.onViewDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String logoUrl;
  final String storeName;

  const _Logo({required this.logoUrl, required this.storeName});

  @override
  Widget build(BuildContext context) {
    return StoreLogo(url: logoUrl, storeName: storeName);
  }
}

class _StoresSkeletonList extends StatelessWidget {
  const _StoresSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 160,
                      color: const Color(0xFFF3F4F6),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 120,
                      color: const Color(0xFFF3F4F6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 92,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 54, color: AppTheme.errorRed),
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
              error.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
