import 'package:flutter/material.dart';
import 'package:matchlog/core/theme/colors.dart';

enum IntensityTier { none, low, medium, high, peak }

extension IntensityTierX on IntensityTier {
  // Maps entry count to the appropriate tier.
  static IntensityTier fromCount(int count) => switch (count) {
        0 => IntensityTier.none,
        1 => IntensityTier.low,
        2 => IntensityTier.medium,
        3 => IntensityTier.high,
        _ => IntensityTier.peak, // 4 or more
      };

  Color toColor() => switch (this) {
        IntensityTier.none => MatchLogColors.surfaceBorder,
        IntensityTier.low =>
          MatchLogColors.primaryDark.withValues(alpha: 0.30),
        IntensityTier.medium =>
          MatchLogColors.primaryDark.withValues(alpha: 0.55),
        IntensityTier.high =>
          MatchLogColors.primaryDark.withValues(alpha: 0.80),
        IntensityTier.peak => MatchLogColors.primaryDark,
      };
}

// view-model for single calendar day in the heatmap.
class HeatmapDay {
  final DateTime date; // midnight-normalised
  final int count; // number of MatchEntry objects on this date
  final IntensityTier tier; // derived via IntensityTierX.fromCount

  const HeatmapDay({
    required this.date,
    required this.count,
    required this.tier,
  });
}

// Streak summary derived from full entry history.
class StreakSummary {
  final int currentStreak;
  final int longestStreak;

  const StreakSummary({
    required this.currentStreak,
    required this.longestStreak,
  });
}

// Top-level view-model produced by heatmapProvider.
class HeatmapData {
  /// Ordered list of days in the 52-week window, oldest first.
  final List<HeatmapDay> days;
  final StreakSummary streaks;

  const HeatmapData({required this.days, required this.streaks});
}
