import 'package:flutter/material.dart';

import '../../../core/widgets/store_logo.dart';
import '../../../theme/app_theme.dart';

class StoreCard extends StatelessWidget {
  final String storeName;
  final String logoUrl;
  final String cashbackText;
  final VoidCallback onActivateTap;

  const StoreCard({
    super.key,
    required this.storeName,
    required this.logoUrl,
    required this.cashbackText,
    required this.onActivateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onActivateTap,
          borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              children: [
                // Store Logo
                SizedBox(
                  width: 40,
                  height: 40,
                  child: StoreLogo(
                    url: logoUrl,
                    storeName: storeName,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingMedium),
                
                // Store Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      
                      // Cashback Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.chipBackground,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                        child: Text(
                          'Up to $cashbackText Cashback',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingSmall),
                
                // Activate Button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  ),
                  child: const Text(
                    'ACTIVATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cardWhite,
                      letterSpacing: 0.5,
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


