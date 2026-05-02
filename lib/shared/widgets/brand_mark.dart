library;

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class MatchLogBrandMark extends StatelessWidget {
  final double width;
  final double height;

  const MatchLogBrandMark({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(
        painter: MatchLogBrandMarkPainter(),
      ),
    );
  }
}

class MatchLogBrandMarkPainter extends CustomPainter {
  const MatchLogBrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Valley depth — the sharp V where arches meet.
    final valleyY = h * 0.60;

    // ── Left half (crimson) — drawn first so purple overlaps on top ──
    final leftPath = Path()
      ..moveTo(0, h) // bottom-left
      ..lineTo(0, h * 0.15) // up the left outer edge
      ..cubicTo(
        0, 0, // CP1: pull up to top corner
        w * 0.06, 0, // CP2: round the corner
        w * 0.18, 0, // end: on top edge
      )
      ..cubicTo(
        w * 0.36, 0, // CP1: arch sweeps right along top
        w * 0.48, valleyY * 0.50, // CP2: curving down toward valley
        w * 0.52, valleyY, // end: slightly past center (overlap)
      )
      ..lineTo(w * 0.52, h) // down to bottom
      ..close();

    // ── Right half (purple) — drawn second, on top at intersection ──
    final rightPath = Path()
      ..moveTo(w, h) // bottom-right
      ..lineTo(w, h * 0.15) // up the right outer edge
      ..cubicTo(
        w, 0, // CP1: pull up to top corner
        w * 0.94, 0, // CP2: round the corner
        w * 0.82, 0, // end: on top edge
      )
      ..cubicTo(
        w * 0.64, 0, // CP1: arch sweeps left along top
        w * 0.52, valleyY * 0.50, // CP2: curving down toward valley
        w * 0.48, valleyY, // end: slightly past center (overlap)
      )
      ..lineTo(w * 0.48, h) // down to bottom
      ..close();

    canvas.drawPath(
      leftPath,
      Paint()
        ..color = MatchLogColors.primary
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      rightPath,
      Paint()
        ..color = MatchLogColors.secondary
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
