// Pulsing skeleton placeholders that match dimensions of real contents

library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/spacing.dart';

class MatchLogShimmer extends StatelessWidget {
  final Widget child;

  const MatchLogShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.outlineVariant,
      child: child,
    );
  }
}

class MatchCardShimmer extends StatelessWidget {
  const MatchCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MatchLogShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MatchLogSpacing.lg,
          vertical: MatchLogSpacing.sm,
        ),
        padding: MatchLogSpacing.cardPadding,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: MatchLogSpacing.roundedMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBox(180, 12, colorScheme),
            const SizedBox(height: MatchLogSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(48, 48, colorScheme, circular: true),
                _shimmerBox(80, 28, colorScheme),
                _shimmerBox(48, 48, colorScheme, circular: true),
              ],
            ),
            const SizedBox(height: MatchLogSpacing.md),
            // Rating + review
            _shimmerBox(120, 12, colorScheme),
            const SizedBox(height: MatchLogSpacing.sm),
            _shimmerBox(200, 12, colorScheme),
          ],
        ),
      ),
    );
  }
}

class BetCardShimmer extends StatelessWidget {
  const BetCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MatchLogShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MatchLogSpacing.lg,
          vertical: MatchLogSpacing.sm,
        ),
        padding: MatchLogSpacing.cardPadding,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: MatchLogSpacing.roundedMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _shimmerBox(160, 16, colorScheme),
                _shimmerBox(48, 24, colorScheme),
              ],
            ),
            const SizedBox(height: MatchLogSpacing.sm),
            _shimmerBox(120, 12, colorScheme),
            const SizedBox(height: MatchLogSpacing.sm),
            _shimmerBox(200, 12, colorScheme),
          ],
        ),
      ),
    );
  }
}

Widget _shimmerBox(
  double width,
  double height,
  ColorScheme colorScheme, {
  bool circular = false,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: colorScheme.surfaceContainerHighest,
      borderRadius:
          circular ? MatchLogSpacing.roundedFull : MatchLogSpacing.roundedSm,
    ),
  );
}

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
