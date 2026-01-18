import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TrustSignals extends StatelessWidget {
  const TrustSignals({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.screenPadding),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrangeLight,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      ),
      child: Column(
        children: [
          const Text(
            'Why KashAndaz? 🌟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          _buildTrustItem(
            Icons.shield_outlined,
            'Secure & Trusted',
            'Your data is encrypted and protected',
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          _buildTrustItem(
            Icons.verified_outlined,
            'Guaranteed Cashback',
            'Track every penny you earn with us',
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          _buildTrustItem(
            Icons.block,
            'No Hidden Charges',
            '100% transparent - what you see is what you get',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryOrange,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
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


