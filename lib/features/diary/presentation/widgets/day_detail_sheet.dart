// bottom sheet showing all matches logged on a given day.

library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/match_entry.dart';
import '../providers/heatmap_models.dart';

class DayDetailSheet extends StatelessWidget {
  final HeatmapDay day;
  final List<MatchEntry> entries;

  const DayDetailSheet({
    super.key,
    required this.day,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate =
        DateFormat('EEEE, d MMMM yyyy').format(day.date);

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Text(
              formattedDate,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            MatchLogSpacing.gapMd,

            if (entries.isEmpty)
              _EmptyDay(colorScheme: colorScheme, theme: theme)
            else
              _EntryList(entries: entries, theme: theme),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _EmptyDay({required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MatchLogSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            MatchLogSpacing.gapSm,
            Text(
              'No matches logged on this day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  final List<MatchEntry> entries;
  final ThemeData theme;

  const _EntryList({required this.entries, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _EntryRow(entry: entry, theme: theme);
      },
    );
  }
}

class _EntryRow extends StatelessWidget {
  final MatchEntry entry;
  final ThemeData theme;

  const _EntryRow({required this.entry, required this.theme});

  @override
  Widget build(BuildContext context) {
    final sportColor = MatchLogColors.sportAccent(entry.sport);
    final matchTitle = entry.awayTeam != null
        ? '${entry.homeTeam} vs ${entry.awayTeam}'
        : entry.homeTeam;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MatchLogSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: sportColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          MatchLogSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                MatchLogSpacing.gapXs,
                Text(
                  entry.score,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                MatchLogSpacing.gapXs,
                _StarRating(rating: entry.rating),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _StarRating extends StatelessWidget {
  final int rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: i < rating
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        );
      }),
    );
  }
}
