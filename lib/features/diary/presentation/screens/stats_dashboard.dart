// StatsDashboard — personal reflection screen with headline cards
// and league/team/watch-type breakdowns.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/error_state.dart';
import '../providers/stats_providers.dart';
import '../widgets/stat_card.dart';

class StatsDashboard extends ConsumerWidget {
  const StatsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Stats')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(statsProvider),
        ),
        data: (stats) {
          if (stats.totalMatchesWatched == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(MatchLogSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    MatchLogSpacing.gapLg,
                    Text('No stats yet',
                        style: theme.textTheme.headlineSmall),
                    MatchLogSpacing.gapSm,
                    Text(
                      'Log some matches and your stats will appear here.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(MatchLogSpacing.lg),
            children: [
              // Headline stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: MatchLogSpacing.sm,
                crossAxisSpacing: MatchLogSpacing.sm,
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                    label: 'Matches watched',
                    value: '${stats.totalMatchesWatched}',
                    icon: Icons.sports_outlined,
                  ),
                  StatCard(
                    label: 'Average rating',
                    value: stats.averageRating.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                  ),
                  StatCard(
                    label: 'Current streak',
                    value: '${stats.currentStreak}d',
                    icon: Icons.local_fire_department_outlined,
                  ),
                  StatCard(
                    label: 'Stadium visits',
                    value: '${stats.stadiumVisits}',
                    icon: Icons.stadium_outlined,
                  ),
                ],
              ),
              MatchLogSpacing.gapXl,

              // This month
              _SectionHeader(
                title: 'This month',
                value: '${stats.matchesThisMonth} matches',
              ),
              MatchLogSpacing.gapLg,

              // Longest streak
              _SectionHeader(
                title: 'Longest streak',
                value: '${stats.longestStreak} days',
              ),
              MatchLogSpacing.gapXl,

              // League breakdown
              if (stats.matchesByLeague.isNotEmpty) ...[
                Text('By league', style: theme.textTheme.titleMedium),
                MatchLogSpacing.gapSm,
                ..._buildBreakdown(
                  stats.matchesByLeague,
                  stats.totalMatchesWatched,
                  colorScheme,
                  theme,
                ),
                MatchLogSpacing.gapXl,
              ],

              // Team breakdown
              if (stats.matchesByTeam.isNotEmpty) ...[
                Text('By team', style: theme.textTheme.titleMedium),
                MatchLogSpacing.gapSm,
                ..._buildBreakdown(
                  stats.matchesByTeam,
                  stats.totalMatchesWatched,
                  colorScheme,
                  theme,
                ),
                MatchLogSpacing.gapXl,
              ],

              // Watch type breakdown
              if (stats.matchesByWatchType.isNotEmpty) ...[
                Text('By watch type', style: theme.textTheme.titleMedium),
                MatchLogSpacing.gapSm,
                ..._buildBreakdown(
                  stats.matchesByWatchType,
                  stats.totalMatchesWatched,
                  colorScheme,
                  theme,
                ),
                MatchLogSpacing.gapXl,
              ],

              // Betting summary (if any bets exist)
              if (stats.totalBets > 0) ...[
                Text('Betting summary', style: theme.textTheme.titleMedium),
                MatchLogSpacing.gapSm,
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: MatchLogSpacing.sm,
                  crossAxisSpacing: MatchLogSpacing.sm,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      label: 'Total bets',
                      value: '${stats.totalBets}',
                      icon: Icons.receipt_long_outlined,
                    ),
                    StatCard(
                      label: 'Win rate',
                      value: '${(stats.winRate * 100).toStringAsFixed(0)}%',
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),
                MatchLogSpacing.gapXl,
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBreakdown(
    Map<String, int> data,
    int total,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(8).map((e) {
      final ratio = total > 0 ? e.value / total : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: MatchLogSpacing.sm),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                e.key,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: MatchLogSpacing.roundedSm,
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor:
                      colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: MatchLogSpacing.sm),
            SizedBox(
              width: 28,
              child: Text(
                '${e.value}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String value;

  const _SectionHeader({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        )),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}
