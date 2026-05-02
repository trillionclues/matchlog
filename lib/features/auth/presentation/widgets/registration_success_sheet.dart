library;

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/bottom_sheet.dart';

class RegistrationSuccessSheet extends StatelessWidget {
  final VoidCallback onContinue;

  const RegistrationSuccessSheet({
    super.key,
    required this.onContinue,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onContinue}) {
    return MatchLogBottomSheet.show(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => RegistrationSuccessSheet(onContinue: onContinue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MatchLogSpacing.xl,
        MatchLogSpacing.xxl,
        MatchLogSpacing.xl,
        MatchLogSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AnimatedSuccessIcon(),
          const SizedBox(height: MatchLogSpacing.xl),
          Text(
            'Successful!',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.sm),
          Text(
            'Your account is created successfully\nand ready now.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MatchLogSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.onSurface,
                foregroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: MatchLogSpacing.roundedFull,
                ),
              ),
              child: const Text(
                'Browse Home',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + MatchLogSpacing.md),
        ],
      ),
    );
  }
}

class _AnimatedSuccessIcon extends StatefulWidget {
  const _AnimatedSuccessIcon();

  @override
  State<_AnimatedSuccessIcon> createState() => _AnimatedSuccessIconState();
}

class _AnimatedSuccessIconState extends State<_AnimatedSuccessIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _checkAnim;
  late final Animation<double> _confettiAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _checkAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );

    _confettiAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use the success-related color from the color scheme
    final successColor = colorScheme.primary;

    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: _confettiAnim.value,
              accentColor: successColor,
            ),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: successColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: successColor.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: _checkAnim.value,
                    child: Icon(
                      Icons.check_rounded,
                      color: colorScheme.onPrimary,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  static final List<_ConfettiParticle> _particles = List.generate(
    14,
    (i) => _ConfettiParticle(i),
  );

  _ConfettiPainter({required this.progress, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    for (final p in _particles) {
      final t = progress;
      final radius = 30 + t * 40 * p.speed;
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final dx = center.dx + cos(p.angle) * radius;
      final dy = center.dy + sin(p.angle) * radius;

      final paint = Paint()
        ..color = p.color(accentColor).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (p.isCircle) {
        canvas.drawCircle(Offset(dx, dy), 3.0 * (1.0 - t * 0.3), paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(dx, dy),
              width: 6 * (1.0 - t * 0.3),
              height: 3 * (1.0 - t * 0.3),
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiParticle {
  late final double angle;
  late final double speed;
  late final bool isCircle;
  late final int colorIndex;

  _ConfettiParticle(int index) {
    final rng = Random(index * 42);
    angle = rng.nextDouble() * 2 * pi;
    speed = 0.7 + rng.nextDouble() * 0.6;
    isCircle = rng.nextBool();
    colorIndex = rng.nextInt(4);
  }

  Color color(Color accent) {
    return switch (colorIndex) {
      0 => accent,
      1 => const Color(0xFFFF6B35),
      2 => const Color(0xFFFFD700),
      _ => const Color(0xFF963CFF),
    };
  }
}
