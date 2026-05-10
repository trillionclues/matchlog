// CustomPainter that draws GitHub-style activity grid.
// Cells are 12×12 px with a 4px gap, arranged in 7 rows (Sun–Sat) and up to
// 53 columns (weeks). Month labels are drawn above the first column of each new month.

library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/heatmap_models.dart';

class HeatmapPainter extends CustomPainter {
  final List<HeatmapDay> days;
  final ThemeData theme;

  // Populated during [paint]; parallel to [days] — index i holds the screen
  // rect for days[i]. Used by parent GestureDetector for hit-testing.
  List<Rect> cellRects = [];

  static const double cellSize = MatchLogSpacing.md;

  static const double gap = MatchLogSpacing.xs;

  static const double step = cellSize + gap;

  static const double monthLabelHeight = MatchLogSpacing.lg;

  HeatmapPainter({required this.days, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    cellRects = [];

    if (days.isEmpty) return;

    // days[0] is the oldest day.
    // Compute day-of-week offset so column 0 starts on the Sunday of
    // the week that contains days[0].
    final startDayOfWeek = days[0].date.weekday % 7;

    final paint = Paint()..style = PaintingStyle.fill;
    final rrRadius = const Radius.circular(2.0);

    int? lastLabelMonth;

    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final col = (i + startDayOfWeek) ~/ 7;
      final row = (i + startDayOfWeek) % 7;

      final x = col * step;
      final y = monthLabelHeight + row * step;

      paint.color = day.tier.toColor();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          rrRadius,
        ),
        paint,
      );

      // Record rect for hit-testing.
      cellRects.add(Rect.fromLTWH(x, y, cellSize, cellSize));

      // Draw month label when this day is the first of a new month and the
      // column has changed (i.e. we haven't already labelled this column).
      if (day.date.day == 1 && day.date.month != lastLabelMonth) {
        lastLabelMonth = day.date.month;
        _drawMonthLabel(canvas, col, day.date);
      }
    }

    // If no label was drawn yet (window starts mid-month), draw the label for
    // the very first column so the grid is never completely unlabelled.
    if (lastLabelMonth == null && days.isNotEmpty) {
      _drawMonthLabel(canvas, 0, days[0].date);
    }
  }

  void _drawMonthLabel(Canvas canvas, int col, DateTime date) {
    const monthAbbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final label = monthAbbr[date.month - 1];

    final style = (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );

    final tp = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(col * step, 0));
  }

  @override
  bool shouldRepaint(HeatmapPainter oldDelegate) => oldDelegate.days != days;
}
