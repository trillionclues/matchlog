library;

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../shared/widgets/brand_mark.dart';

class SplashScreen extends StatefulWidget {
  final bool hasError;
  final VoidCallback? onRetry;

  const SplashScreen({
    super.key,
    this.hasError = false,
    this.onRetry,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MatchLogColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.0,
                colors: [
                  MatchLogColors.primary.withValues(alpha: 0.12),
                  MatchLogColors.background,
                ],
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: MatchLogSpacing.screenPadding,
              child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MatchLogBrandMark(width: 120, height: 108),
                    const SizedBox(height: MatchLogSpacing.xl),
                    Text(
                      'MatchLog',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: MatchLogColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: MatchLogSpacing.sm),
                    Text(
                      'Track the match. Log the story.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: MatchLogColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MatchLogSpacing.xxxl),
                    if (widget.hasError)
                      _ErrorFooter(onRetry: widget.onRetry)
                    else
                      const _LoadingDots(color: MatchLogColors.primary),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

class _LoadingDots extends StatefulWidget {
  final Color color;
  const _LoadingDots({required this.color});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value - i * 0.28) % 1.0;
            final t = (1.0 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
            final opacity = 0.25 + 0.75 * t;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class _ErrorFooter extends StatelessWidget {
  final VoidCallback? onRetry;
  const _ErrorFooter({this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Something went wrong',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: MatchLogColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: MatchLogSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: theme.textTheme.labelLarge?.copyWith(
                color: MatchLogColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
