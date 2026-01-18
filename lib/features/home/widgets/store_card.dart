import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: Icon(
                          Icons.store,
                          color: AppTheme.textLight,
                          size: 32,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.store,
                          color: AppTheme.textLight,
                          size: 32,
                        ),
                      ),
                    ),
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


