import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Shimmer loading widget for skeleton screens
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(Spacing.xs),
        ),
      ),
    );
  }
}

/// Shimmer for wallet card
class WalletCardShimmer extends StatelessWidget {
  const WalletCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Spacing.screenPadding),
      padding: const EdgeInsets.all(Spacing.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 100, height: 16),
          const SizedBox(height: Spacing.small),
          const ShimmerLoading(width: 150, height: 32),
          const SizedBox(height: Spacing.large),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoading(width: 80, height: 14),
                    SizedBox(height: Spacing.xs),
                    ShimmerLoading(width: 100, height: 20),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerLoading(width: 80, height: 14),
                    SizedBox(height: Spacing.xs),
                    ShimmerLoading(width: 100, height: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer for store card
class StoreCardShimmer extends StatelessWidget {
  const StoreCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Spacing.screenPadding,
        vertical: Spacing.small,
      ),
      padding: const EdgeInsets.all(Spacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const ShimmerLoading(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: Spacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLoading(width: double.infinity, height: 18),
                SizedBox(height: Spacing.small),
                ShimmerLoading(width: 100, height: 16),
              ],
            ),
          ),
          const ShimmerLoading(width: 60, height: 30),
        ],
      ),
    );
  }
}

/// Shimmer for transaction item
class TransactionShimmer extends StatelessWidget {
  const TransactionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Spacing.small),
      padding: const EdgeInsets.all(Spacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Row(
        children: [
          const ShimmerLoading(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
          const SizedBox(width: Spacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerLoading(width: double.infinity, height: 16),
                SizedBox(height: Spacing.xs),
                ShimmerLoading(width: 120, height: 14),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              ShimmerLoading(width: 80, height: 18),
              SizedBox(height: Spacing.xs),
              ShimmerLoading(width: 60, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}
