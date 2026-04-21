// Pulsing skeleton placeholders that match the dimensions of real contents

library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

/// Base shimmer wrapper — applies the pulsing animation to any child.
class MatchLogShimmer extends StatelessWidget {
  final Widget child;

  const MatchLogShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: MatchLogColors.surfaceElevated,
      highlightColor: MatchLogColors.surfaceBorder,
      child: child,
    );
  }
}

/// Shimmer matching dimensions of MatchCard.
class MatchCardShimmer extends StatelessWidget {
  const MatchCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return MatchLogShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MatchLogSpacing.lg,
          vertical: MatchLogSpacing.sm,
        ),
        padding: MatchLogSpacing.cardPadding,
        decoration: BoxDecoration(
          color: MatchLogColors.surface,
          borderRadius: MatchLogSpacing.roundedMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12,
              width: 180,
              decoration: BoxDecoration(
                color: MatchLogColors.surfaceElevated,
                borderRadius: MatchLogSpacing.roundedSm,
              ),
            ),
            const SizedBox(height: MatchLogSpacing.md),
            // Score row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(48, 48, circular: true),
                _shimmerBox(80, 28),
                _shimmerBox(48, 48, circular: true),
              ],
            ),
            const SizedBox(height: MatchLogSpacing.md),
            // Rating + review
            _shimmerBox(120, 12),
            const SizedBox(height: MatchLogSpacing.sm),
            _shimmerBox(200, 12),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {bool circular = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MatchLogColors.surfaceElevated,
        borderRadius: circular
            ? MatchLogSpacing.roundedFull
            : MatchLogSpacing.roundedSm,
      ),
    );
  }
}

/// Shimmer matching the dimensions of BetCard.
class BetCardShimmer extends StatelessWidget {
  const BetCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return MatchLogShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MatchLogSpacing.lg,
          vertical: MatchLogSpacing.sm,
        ),
        padding: MatchLogSpacing.cardPadding,
        decoration: BoxDecoration(
          color: MatchLogColors.surface,
          borderRadius: MatchLogSpacing.roundedMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(160, 16),
                _shimmerBox(48, 24),
              ],
            ),
            const SizedBox(height: MatchLogSpacing.sm),
            _shimmerBox(120, 12),
            const SizedBox(height: MatchLogSpacing.sm),
            _shimmerBox(200, 12),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: MatchLogColors.surfaceElevated,
        borderRadius: MatchLogSpacing.roundedSm,
      ),
    );
  }
}

// list of [count] shimmer cards for full-screen loading states.
class ShimmerList extends StatelessWidget {
  final int count;
  final Widget Function() itemBuilder;

  const ShimmerList({
    super.key,
    this.count = 5,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => itemBuilder(),
    );
  }
}
