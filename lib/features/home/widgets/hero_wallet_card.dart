import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class HeroWalletCard extends StatelessWidget {
  final double totalCashback;
  final double pendingAmount;
  final double availableAmount;
  final double paidAmount;
  final VoidCallback? onActivate;

  const HeroWalletCard({
    super.key,
    required this.totalCashback,
    required this.pendingAmount,
    required this.availableAmount,
    required this.paidAmount,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryOrangeDark, AppTheme.primaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        boxShadow: AppTheme.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          const Text(
            'Hi 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          
          // Your Cashback
          const Text(
            'Your Cashback',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: totalCashback),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '₹${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Status Chips
          Row(
            children: [
              _buildChip('Pending', '₹${pendingAmount.toStringAsFixed(0)}'),
              const SizedBox(width: AppTheme.spacingSmall),
              _buildChip('Available', '₹${availableAmount.toStringAsFixed(0)}'),
              const SizedBox(width: AppTheme.spacingSmall),
              _buildChip('Paid', '₹${paidAmount.toStringAsFixed(0)}'),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // CTA Button with scale animation
          _AnimatedButton(
            onPressed: onActivate,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Activate Cashback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingSmall,
          horizontal: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal animated button widget for scale effect
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _AnimatedButton({
    required this.child,
    this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
