
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

    return Padding(
       padding: const EdgeInsets.symmetric(
        horizontal: MatchLogSpacing.lg,
        vertical: MatchLogSpacing.xs,
      ),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: MatchLogSpacing.roundedMd,
        child: InkWell(
        onTap: onTap,
        borderRadius: MatchLogSpacing.roundedMd,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: MatchLogSpacing.roundedMd,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            padding: const EdgeInsets.all(MatchLogSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(
                        entry.league,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormatter.formatRelative(entry.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MatchLogSpacing.md),

                _ScoreBlock(entry: entry, theme: theme, colorScheme: colorScheme),
                const SizedBox(height: MatchLogSpacing.md),

                RatingStars(rating: entry.rating, size: 15),

                if (entry.review != null && entry.review!.isNotEmpty) ...[
                  const SizedBox(height: MatchLogSpacing.xs),
                  Text(
                    entry.review!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: MatchLogSpacing.sm),

                _Footer(entry: entry, colorScheme: colorScheme, textTheme: theme.textTheme),
                ],
              ),

              // _MetadataRow(
              //   league: entry.league,
              //   watchType: entry.watchType,
              //   watchTypeIcon: _watchTypeIcon(entry.watchType),
              //   watchTypeLabel: _watchTypeLabel(entry.watchType),
              //   venue: entry.venue,
              //   colorScheme: colorScheme,
              //   textTheme: theme.textTheme,
              // ),
              // const SizedBox(height: MatchLogSpacing.md),

              // _ScoreRow(
              //   homeTeam: entry.homeTeam,
              //   awayTeam: entry.awayTeam,
              //   score: entry.score,
              //   theme: theme,
              //   colorScheme: colorScheme,
              // ),
              // const SizedBox(height: MatchLogSpacing.md),
              // Row(
              //   children: [
              //     RatingStars(rating: entry.rating, size: 16),
              //     if (entry.review != null && entry.review!.isNotEmpty) ...[
              //       const SizedBox(width: MatchLogSpacing.sm),
              //       Expanded(
              //         child: Text(
              //           entry.review!,
              //           maxLines: 1,
              //           overflow: TextOverflow.ellipsis,
              //           style: theme.textTheme.bodySmall?.copyWith(
              //             color: colorScheme.onSurface.withValues(alpha: 0.6),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ],
              // ),
              // const SizedBox(height: MatchLogSpacing.sm),

              // Row(
              //   children: [
              //     if (entry.photos.isNotEmpty) ...[
              //       Icon(
              //         Icons.photo_outlined,
              //         size: 14,
              //         color: colorScheme.onSurface.withValues(alpha: 0.45),
              //       ),
              //       const SizedBox(width: 4),
              //       Text(
              //         '${entry.photos.length}',
              //         style: theme.textTheme.labelSmall?.copyWith(
              //           color: colorScheme.onSurface.withValues(alpha: 0.45),
              //         ),
              //       ),
              //       const SizedBox(width: MatchLogSpacing.md),
              //     ],
              //     if (entry.geoVerified) ...[
              //       Icon(
              //         Icons.verified_outlined,
              //         size: 14,
              //         color: colorScheme.primary,
              //       ),
              //       const SizedBox(width: MatchLogSpacing.md),
              //     ],
              //     const Spacer(),
              //     Text(
              //       DateFormatter.formatRelative(entry.createdAt),
              //       style: theme.textTheme.labelSmall?.copyWith(
              //         color: colorScheme.onSurface.withValues(alpha: 0.45),
              //       ),
              //     ),
              //   ],
              // ),
          ),
        ),
      ),
      );
  }
}


class _ScoreBlock extends StatelessWidget {
  final domain.MatchEntry entry;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ScoreBlock({required this.entry, required this.theme, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    // Individual sport — no away team
    if (entry.awayTeam == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              entry.homeTeam,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: MatchLogSpacing.roundedSm,
              border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Text(
              entry.score,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      );
    }

    // Team sport
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.homeTeam,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MatchLogSpacing.sm),
          child: Text(
            entry.score,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            entry.awayTeam!,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


class _Footer extends StatelessWidget {
  final domain.MatchEntry entry;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _Footer({required this.entry, required this.colorScheme, required this.textTheme});

  IconData _watchIcon(String type) => switch (type) {
        'stadium' => Icons.stadium_outlined,
        'tv' => Icons.tv_outlined,
        'streaming' => Icons.wifi_outlined,
        'radio' => Icons.radio_outlined,
        _ => Icons.visibility_outlined,
      };

  String _watchLabel(String type) => switch (type) {
        'stadium' => 'Stadium',
        'tv' => 'TV',
        'streaming' => 'Streaming',
        'radio' => 'Radio',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(
          icon: _watchIcon(entry.watchType),
          label: _watchLabel(entry.watchType),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        if (entry.venue != null && entry.venue!.isNotEmpty) ...[
          const SizedBox(width: MatchLogSpacing.xs),
          _Pill(
            icon: Icons.location_on_outlined,
            label: entry.venue!,
            colorScheme: colorScheme,
            textTheme: textTheme,
            maxWidth: 100,
          ),
        ],
        if (entry.geoVerified) ...[
          const SizedBox(width: MatchLogSpacing.xs),
          _Pill(
            icon: Icons.verified_outlined,
            label: 'Verified',
            colorScheme: colorScheme,
            textTheme: textTheme,
            iconColor: colorScheme.primary,
          ),
        ],
        const Spacer(),
        if (entry.photos.isNotEmpty)
          Row(
            children: [
              Icon(Icons.photo_outlined, size: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 3),
              Text(
                '${entry.photos.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Color? iconColor;
  final double? maxWidth;

  const _Pill({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
    this.iconColor,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusSm),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12,
              color: iconColor ?? colorScheme.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}