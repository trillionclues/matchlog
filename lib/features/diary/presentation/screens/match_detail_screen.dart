// MatchDetailScreen — full journal entry view for a single match.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matchlog/core/router/routes.dart';
import 'package:matchlog/core/utils/app_logger.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/photo_grid.dart';
import '../../../../shared/widgets/snackbar.dart';
import '../providers/diary_providers.dart';
import '../widgets/rating_stars.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String entryId;
  const MatchDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _isDeleting = false;

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
    final entryAsync = ref.watch(matchEntryDetailProvider(widget.entryId));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Detail'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(matchEntryDetailProvider(widget.entryId)),
        ),
        data: (entry) {
          if (entry == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  MatchLogSpacing.gapLg,
                  Text('Entry not found', style: theme.textTheme.headlineSmall),
                  MatchLogSpacing.gapSm,
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(MatchLogSpacing.lg),
            children: [
              // Teams + score
              if (entry.awayTeam != null) ...[
                Center(
                  child: Text(
                    entry.homeTeam,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                MatchLogSpacing.gapSm,
                Center(
                  child: Text(
                    entry.score,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                MatchLogSpacing.gapSm,
                Center(
                  child: Text(
                    entry.awayTeam!,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                Center(
                  child: Text(
                    entry.homeTeam,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                MatchLogSpacing.gapSm,
                Center(
                  child: Text(
                    entry.score,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
              MatchLogSpacing.gapXl,

              // Metadata chips
              Wrap(
                spacing: MatchLogSpacing.sm,
                runSpacing: MatchLogSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  _MetaChip(
                    icon: Icons.emoji_events_outlined,
                    label: entry.league,
                    colorScheme: colorScheme,
                    textTheme: theme.textTheme,
                  ),
                  _MetaChip(
                    icon: _watchTypeIcon(entry.watchType),
                    label: _watchTypeLabel(entry.watchType),
                    colorScheme: colorScheme,
                    textTheme: theme.textTheme,
                  ),
                  _MetaChip(
                    icon: Icons.sports_outlined,
                    label:
                        entry.sport[0].toUpperCase() + entry.sport.substring(1),
                    colorScheme: colorScheme,
                    textTheme: theme.textTheme,
                  ),
                  if (entry.venue != null && entry.venue!.isNotEmpty)
                    _MetaChip(
                      icon: Icons.location_on_outlined,
                      label: entry.venue!,
                      colorScheme: colorScheme,
                      textTheme: theme.textTheme,
                    ),
                  if (entry.geoVerified)
                    _MetaChip(
                      icon: Icons.verified_rounded,
                      label: 'Verified',
                      colorScheme: colorScheme,
                      textTheme: theme.textTheme,
                      highlight: true,
                    ),
                ],
              ),
              MatchLogSpacing.gapXl,

              // Rating
              Center(child: RatingStars(rating: entry.rating, size: 28)),
              MatchLogSpacing.gapXl,

              // Review
              if (entry.review != null && entry.review!.isNotEmpty) ...[
                Text('Review', style: theme.textTheme.labelLarge),
                MatchLogSpacing.gapSm,
                Text(
                  entry.review!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                MatchLogSpacing.gapXl,
              ],

              // Photos
              if (entry.photos.isNotEmpty) ...[
                Text('Photos', style: theme.textTheme.labelLarge),
                MatchLogSpacing.gapSm,
                PhotoGrid(photoUrls: entry.photos),
                MatchLogSpacing.gapXl,
              ],

              // Date footer
              Center(
                child: Text(
                  DateFormatter.formatFull(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              MatchLogSpacing.gapXl,
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This will permanently remove this match from your diary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              final result = await ref
                  .read(deleteEntryControllerProvider.notifier)
                  .delete(widget.entryId);
              if (!mounted) return;
              setState(() => _isDeleting = false);
              if (result.isSuccess) {
                MatchLogSnackBar.success(context, 'Entry deleted.');
                context.go(Routes.diary);
              } else {
                AppLogger.log('Delete failed: ${result.message}');
                MatchLogSnackBar.error(
                    context, result.message ?? 'Delete failed.');
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool highlight;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: MatchLogSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlight
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: highlight
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
