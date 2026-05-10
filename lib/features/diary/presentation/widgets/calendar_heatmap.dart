// GitHub-style activity grid embedded in StatsDashboard.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/bottom_sheet.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../providers/diary_providers.dart';
import '../providers/heatmap_models.dart';
import '../providers/stats_providers.dart';
import 'day_detail_sheet.dart';
import 'heatmap_painter.dart';
import 'streak_summary_row.dart';

class CalendarHeatmap extends ConsumerWidget {
  const CalendarHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapAsync = ref.watch(heatmapProvider);

    return heatmapAsync.when(
      loading: () => const _HeatmapShimmer(),
      error: (e, _) => _HeatmapError(
        message: e.toString(),
        onRetry: () => ref.invalidate(heatmapProvider),
      ),
      data: (data) {
        final allEmpty = data.days.every((d) => d.count == 0);
        if (allEmpty) return const _HeatmapEmpty();
        return _HeatmapContent(data: data);
      },
    );
  }
}

class _HeatmapShimmer extends StatelessWidget {
  const _HeatmapShimmer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const gridWidth = 53 * HeatmapPainter.step - HeatmapPainter.gap;
    const gridHeight = HeatmapPainter.monthLabelHeight +
        7 * HeatmapPainter.step -
        HeatmapPainter.gap;

    return MatchLogShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: gridWidth,
            height: gridHeight,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: MatchLogSpacing.roundedMd,
            ),
          ),
          MatchLogSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: MatchLogSpacing.roundedMd,
                  ),
                ),
              ),
              MatchLogSpacing.hGapSm,
              Expanded(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: MatchLogSpacing.roundedMd,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HeatmapError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorState(message: message, onRetry: onRetry);
  }
}

class _HeatmapEmpty extends StatelessWidget {
  const _HeatmapEmpty();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'No activity yet',
      subtitle: 'Log your first match and it will appear here.',
    );
  }
}

// ---------------------------------------------------------------------------
// actual heatmap grid + streak row
// ---------------------------------------------------------------------------

class _HeatmapContent extends ConsumerStatefulWidget {
  final HeatmapData data;

  const _HeatmapContent({required this.data});

  @override
  ConsumerState<_HeatmapContent> createState() => _HeatmapContentState();
}

class _HeatmapContentState extends ConsumerState<_HeatmapContent> {
  late HeatmapPainter _painter;

  // Canvas size: 53 columns × step − gap wide, monthLabelHeight + 7 rows × step − gap tall.
  static const _canvasSize = Size(
    53 * HeatmapPainter.step - HeatmapPainter.gap,
    HeatmapPainter.monthLabelHeight + 7 * HeatmapPainter.step - HeatmapPainter.gap,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _painter = HeatmapPainter(
      days: widget.data.days,
      theme: Theme.of(context),
    );
  }

  @override
  void didUpdateWidget(_HeatmapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.days != widget.data.days) {
      _painter = HeatmapPainter(
        days: widget.data.days,
        theme: Theme.of(context),
      );
    }
  }

  void _onCellTap(BuildContext context, int idx) {
    final day = widget.data.days[idx];

    // entries from diaryEntriesProvider and filter to this day.
    final entriesAsync = ref.read(diaryEntriesProvider);
    final allEntries = entriesAsync.valueOrNull ?? [];
    final dayEntries = allEntries.where((e) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      return d == day.date;
    }).toList();

    MatchLogBottomSheet.show(
      context: context,
      builder: (_) => DayDetailSheet(day: day, entries: dayEntries),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity', style: theme.textTheme.titleMedium),
        MatchLogSpacing.gapSm,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: GestureDetector(
            onTapUp: (details) {
              final local = details.localPosition;
              final idx = _painter.cellRects.indexWhere(
                (r) => r.contains(local),
              );
              if (idx >= 0) _onCellTap(context, idx);
            },
            child: CustomPaint(
              painter: _painter,
              size: _canvasSize,
            ),
          ),
        ),
        MatchLogSpacing.gapMd,
        // StreakSummaryRow(streaks: widget.data.streaks),
      ],
    );
  }
}
