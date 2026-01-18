import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';

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

class _MissingCashbackScreenState extends ConsumerState<MissingCashbackScreen> {
  String _selectedFilter = 'In Review';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Missing Cashback'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                  onTap: () => setState(() => _selectedFilter == 'Successfully'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content area (empty state for now)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No missing cashback claims',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All your cashback is tracked',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom CTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to track cashback
                  _showTrackCashbackDialog(context);
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
  }

  void _showTrackCashbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Cashback'),
        content: const Text('Cashback tracking feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
          color: isSelected ? chipColor.withOpacity(0.1) : Colors.white,
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
