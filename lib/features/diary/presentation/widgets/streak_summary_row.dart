

library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/heatmap_models.dart';

class StreakSummaryRow extends StatelessWidget {
  final StreakSummary streaks;

  const StreakSummaryRow({super.key, required this.streaks});

  @override
  Widget build(BuildContext context) {
    final currentValue = streaks.currentStreak == 0
        ? 'No active streak'
        : '${streaks.currentStreak} days';
    final longestValue = '${streaks.longestStreak} days';

    return Row(
      children: [
        Expanded(
          child: _StreakTile(
            icon: Icons.local_fire_department_outlined,
            label: 'Current streak',
            value: currentValue,
          ),
        ),
        MatchLogSpacing.hGapSm,
        Expanded(
          child: _StreakTile(
            icon: Icons.emoji_events_outlined,
            label: 'Longest streak',
            value: longestValue,
          ),
        ),
      ],
    );
  }
}

class _StreakTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StreakTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(MatchLogSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: MatchLogSpacing.roundedMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          MatchLogSpacing.gapXs,
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          MatchLogSpacing.gapXs,
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
