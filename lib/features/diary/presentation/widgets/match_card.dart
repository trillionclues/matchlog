// MatchCard — dense but scannable diary feed card.
// Shows league/venue/watch-type metadata, teams + score,
// star rating with truncated review, and photo count + date footer.
library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/match_entry.dart' as domain;
import 'rating_stars.dart';

class MatchCard extends StatelessWidget {
  final domain.MatchEntry entry;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  IconData _watchTypeIcon(String type) => switch (type) {
        'stadium' => Icons.stadium_outlined,
        'tv' => Icons.tv_outlined,
        'streaming' => Icons.wifi_outlined,
        'radio' => Icons.radio_outlined,
        _ => Icons.visibility_outlined,
      };

  String _watchTypeLabel(String type) => switch (type) {
        'stadium' => 'Stadium',
        'tv' => 'TV',
        'streaming' => 'Streaming',
        'radio' => 'Radio',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: MatchLogSpacing.lg,
        vertical: MatchLogSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: MatchLogSpacing.roundedMd,
        child: Padding(
          padding: MatchLogSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metadata row: league · watch type · venue
              _MetadataRow(
                league: entry.league,
                watchType: entry.watchType,
                watchTypeIcon: _watchTypeIcon(entry.watchType),
                watchTypeLabel: _watchTypeLabel(entry.watchType),
                venue: entry.venue,
                colorScheme: colorScheme,
                textTheme: theme.textTheme,
              ),
              const SizedBox(height: MatchLogSpacing.md),

              // Teams and score
              _ScoreRow(
                homeTeam: entry.homeTeam,
                awayTeam: entry.awayTeam,
                score: entry.score,
                theme: theme,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: MatchLogSpacing.md),

              // Rating + review preview
              Row(
                children: [
                  RatingStars(rating: entry.rating, size: 16),
                  if (entry.review != null && entry.review!.isNotEmpty) ...[
                    const SizedBox(width: MatchLogSpacing.sm),
                    Expanded(
                      child: Text(
                        entry.review!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: MatchLogSpacing.sm),

              // Footer: photo count + date
              Row(
                children: [
                  if (entry.photos.isNotEmpty) ...[
                    Icon(
                      Icons.photo_outlined,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.photos.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(width: MatchLogSpacing.md),
                  ],
                  if (entry.geoVerified) ...[
                    Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: MatchLogSpacing.md),
                  ],
                  const Spacer(),
                  Text(
                    DateFormatter.formatRelative(entry.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final String league;
  final String watchType;
  final IconData watchTypeIcon;
  final String watchTypeLabel;
  final String? venue;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MetadataRow({
    required this.league,
    required this.watchType,
    required this.watchTypeIcon,
    required this.watchTypeLabel,
    required this.venue,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final muted = colorScheme.onSurface.withValues(alpha: 0.55);
    final style = textTheme.labelSmall?.copyWith(color: muted);

    return Row(
      children: [
        Flexible(
          child: Text(league, style: style, overflow: TextOverflow.ellipsis),
        ),
        Text(' · ', style: style),
        Icon(watchTypeIcon, size: 12, color: muted),
        const SizedBox(width: 2),
        Text(watchTypeLabel, style: style),
        if (venue != null && venue!.isNotEmpty) ...[
          Text(' · ', style: style),
          Flexible(
            child: Text(venue!, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String homeTeam;
  final String? awayTeam;
  final String score;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ScoreRow({
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (awayTeam == null) {
      // Individual sport (F1, MMA, Tennis)
      return Row(
        children: [
          Expanded(
            child: Text(
              homeTeam,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            score,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            homeTeam,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MatchLogSpacing.sm),
          child: Text(
            score,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            awayTeam!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
