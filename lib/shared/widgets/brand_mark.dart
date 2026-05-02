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

    final leftOuter = w * 0.06;
    final leftInner = w * 0.31;
    final center = w * 0.50;
    final rightInner = w * 0.69;
    final rightOuter = w * 0.94;

    final archTop = h * 0.02;
    final postTop = h * 0.26;
    final valley = h * 0.70;
    final bottom = h * 0.98;

    final leftPath = Path()
      ..moveTo(leftOuter, bottom)
      ..lineTo(leftOuter, postTop)
      ..cubicTo(
        leftOuter,
        archTop,
        leftInner,
        archTop,
        leftInner,
        postTop,
      )
      ..lineTo(leftInner, valley)
      ..quadraticBezierTo(
        w * 0.40,
        h * 0.84,
        center,
        valley,
      )
      ..lineTo(center, bottom)
      ..close();

    final rightPath = Path()
      ..moveTo(rightOuter, bottom)
      ..lineTo(rightOuter, postTop)
      ..cubicTo(
        rightOuter,
        archTop,
        rightInner,
        archTop,
        rightInner,
        postTop,
      )
      ..lineTo(rightInner, valley)
      ..quadraticBezierTo(
        w * 0.60,
        h * 0.84,
        center,
        valley,
      )
      ..lineTo(center, bottom)
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
