library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

class LocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationLabel;

  const LocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: ClipRRect(
        child: Stack(
          children: [
            // Map background
            CustomPaint(
              size: const Size(double.infinity, 220),
              painter: _MapPainter(colorScheme: colorScheme),
            ),

            // Pulse rings
            Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  return CustomPaint(
                    size: const Size(double.infinity, 220),
                    painter: _PulsePainter(
                      progress: _pulse.value,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ),

            // Location label callout
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 42),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      widget.locationLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // GPS accuracy badge
            Positioned(
              right: 12,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded,
                        size: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      'GPS · ±50m',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final ColorScheme colorScheme;
  _MapPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = colorScheme.surfaceContainerLow;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Grid lines
    final grid = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    // Abstract land blocks — seeded so they're consistent
    final rng = math.Random(42);
    final land = Paint()
      ..color = colorScheme.surfaceContainerHighest;
    final landStroke = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final blocks = [
      Rect.fromLTWH(size.width * 0.05, size.height * 0.3, size.width * 0.15, size.height * 0.15),
      Rect.fromLTWH(size.width * 0.28, size.height * 0.15, size.width * 0.18, size.height * 0.18),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.1, size.width * 0.14, size.height * 0.13),
      Rect.fromLTWH(size.width * 0.68, size.height * 0.45, size.width * 0.2, size.height * 0.2),
      Rect.fromLTWH(size.width * 0.1, size.height * 0.6, size.width * 0.22, size.height * 0.16),
      Rect.fromLTWH(size.width * 0.4, size.height * 0.62, size.width * 0.16, size.height * 0.14),
    ];

    for (final b in blocks) {
      final rr = RRect.fromRectAndRadius(b, const Radius.circular(6));
      canvas.drawRRect(rr, land);
      canvas.drawRRect(rr, landStroke);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => false;
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  _PulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer pulse ring
    final outerRadius = 12 + (progress * 24);
    final outerOpacity = (1 - progress) * 0.35;
    canvas.drawCircle(
      center, outerRadius,
      Paint()..color = color.withValues(alpha: outerOpacity),
    );

    // Inner halo
    canvas.drawCircle(
      center, 18,
      Paint()..color = color.withValues(alpha: 0.12),
    );

    // Dot
    canvas.drawCircle(center, 6, Paint()..color = color);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}