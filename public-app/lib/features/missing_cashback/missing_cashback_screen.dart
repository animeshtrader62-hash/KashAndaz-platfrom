import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../core/navigation/main_scaffold.dart';
import '../../core/widgets/login_required.dart';
import '../auth/providers/auth_provider.dart';
import 'missing_cashback_form.dart';
import 'missing_cashback_list.dart';

/// Missing Cashback Screen - EXACT STRUCTURE FROM HAND-DRAWN UI
/// 
/// Structure:
/// 1. AppBar: "Missing Cashback" (Flipkart Blue)
/// 2. Filter Chips: In Review, Closed, Successfully
/// 3. List of missing cashback claims (empty state for now)
/// 4. Bottom CTA: "Have more cashback to track?"
class MissingCashbackScreen extends ConsumerStatefulWidget {
  const MissingCashbackScreen({super.key});

  @override
  ConsumerState<MissingCashbackScreen> createState() => _MissingCashbackScreenState();
}

class _MissingCashbackScreenState extends ConsumerState<MissingCashbackScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedFilter = 'In Review';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: AppTheme.scaffoldBg,
            appBar: AppBar(
              title: const Text('Missing Cashback'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  final scope = MainScaffoldScope.maybeOf(context);
                  if (scope != null) {
                    scope.setIndex(0);
                    return;
                  }
                  Navigator.pop(context);
                },
              ),
            ),
            body: const LoginRequiredView(
              message: 'Please login to track missing cashback.',
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: AppBar(
            title: const Text('Missing Cashback'),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                final scope = MainScaffoldScope.maybeOf(context);
                if (scope != null) {
                  scope.setIndex(0);
                  return;
                }
                Navigator.pop(context);
              },
            ),
          ),
          body: Column(
            children: [
          const SizedBox(height: 16),
          
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'In Review',
                  isSelected: _selectedFilter == 'In Review',
                  onTap: () => setState(() => _selectedFilter = 'In Review'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Closed',
                  isSelected: _selectedFilter == 'Closed',
                  onTap: () => setState(() => _selectedFilter = 'Closed'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Successfully',
                  isSelected: _selectedFilter == 'Successfully',
                  color: AppTheme.successGreen,
                  onTap: () => setState(() => _selectedFilter = 'Successfully'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content area (real list)
          Expanded(
            child: MissingCashbackList(filter: _selectedFilter),
          ),
          
          // Bottom CTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _openSubmitSheet(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.cashbackOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.cashbackOrange, width: 2),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Have more cashback to track?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('Missing Cashback'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              final scope = MainScaffoldScope.maybeOf(context);
              if (scope != null) {
                scope.setIndex(0);
                return;
              }
              Navigator.pop(context);
            },
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          title: const Text('Missing Cashback'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              final scope = MainScaffoldScope.maybeOf(context);
              if (scope != null) {
                scope.setIndex(0);
                return;
              }
              Navigator.pop(context);
            },
          ),
        ),
        body: const LoginRequiredView(
          message: 'Please login to track missing cashback.',
        ),
      ),
    );
  }

  void _openSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MissingCashbackForm(
        onSubmitted: () {
          // List refresh is handled via provider invalidation in the form.
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTER CHIP
// ═══════════════════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryBlue;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? chipColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
