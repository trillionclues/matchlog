library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';

class SocialLoginRow extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onApplePressed;
  final bool isLoading;

  const SocialLoginRow({
    super.key,
    required this.onGooglePressed,
    this.onApplePressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            onPressed: isLoading ? null : onGooglePressed,
            icon: const _GoogleIcon(),
            label: 'Google',
          ),
        ),
        const SizedBox(width: MatchLogSpacing.md),
        Expanded(
          child: _SocialButton(
            onPressed: isLoading ? null : onApplePressed,
            icon: const _AppleIcon(),
            label: 'Apple',
          ),
        ),
      ],
    );
  }
}

// single full-width Google button.
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
            borderRadius: MatchLogSpacing.roundedFull,
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

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: MatchLogSpacing.md),
          side: BorderSide(color: colorScheme.outlineVariant),
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: MatchLogSpacing.roundedFull,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: MatchLogSpacing.sm),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
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
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Icon(
      Icons.apple,
      size: 20,
      color: colorScheme.onSurface,
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
      (Color(0xFF4285F4), 0.0, 0.5),
      (Color(0xFF34A853), 0.5, 0.75),
      (Color(0xFFFBBC05), 0.75, 1.0),
      (Color(0xFFEA4335), 1.0, 1.25),
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
