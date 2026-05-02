library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final Widget icon;

  const SocialLoginButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    this.label = 'Continue with Google',
    this.icon = const _GoogleIcon(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: MatchLogSpacing.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedMd,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            MatchLogSpacing.hGapMd,
            Text(
              isLoading ? 'Connecting...' : label,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    const segments = [
      (Color(0xFF4285F4), 0.0, 0.5), // blue  — top-right
      (Color(0xFF34A853), 0.5, 0.75), // green — bottom-right
      (Color(0xFFFBBC05), 0.75, 1.0), // yellow — bottom-left
      (Color(0xFFEA4335), 1.0, 1.25), // red   — top-left
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    const pi2 = 6.2831853;
    for (final (color, start, end) in segments) {
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.62),
        start * pi2 - 1.5708,
        (end - start) * pi2,
        false,
        paint,
      );
    }

    // Horizontal bar of the G
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.55, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
