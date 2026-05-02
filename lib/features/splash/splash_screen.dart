library;

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/typography.dart';
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
    return Scaffold(
      backgroundColor: MatchLogColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackdrop(),
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
                        const MatchLogBrandMark(
                          width: 120,
                          height: 108,
                        ),
                        const SizedBox(height: MatchLogSpacing.xl),
                        Text(
                          'MatchLog',
                          style: MatchLogTypography.headlineXL.copyWith(
                            color: MatchLogColors.textPrimary,
                            letterSpacing: -0.8,
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(height: MatchLogSpacing.sm),
                        Text(
                          'Track the match. Log the story.',
                          style: MatchLogTypography.bodyMedium.copyWith(
                            color: MatchLogColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: widget.hasError
                ? _ErrorFooter(onRetry: widget.onRetry)
                : FadeTransition(
                    opacity: _fadeIn,
                    child: const _LoadingDots(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

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
                color: MatchLogColors.primary.withValues(alpha: opacity),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Something went wrong',
          style: MatchLogTypography.bodyMedium.copyWith(
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
              style: MatchLogTypography.labelLarge.copyWith(
                color: MatchLogColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle gradient glow behind the logo
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    MatchLogColors.primary.withValues(alpha: 0.06),
                    MatchLogColors.background,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MatchLogColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -90,
            bottom: 140,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MatchLogColors.secondary.withValues(alpha: 0.07),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
