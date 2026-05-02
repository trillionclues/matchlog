library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../providers/auth_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.auto_stories_rounded,
      eyebrow: 'Your sports diary',
      title: 'Log every\nmatch that\nmatters',
      description:
          'Build a sharp watch history with ratings, notes, and memories you can actually revisit.',
      accentColor: MatchLogColors.primary,
    ),
    _OnboardingSlide(
      icon: Icons.track_changes_rounded,
      eyebrow: 'Betting without clutter',
      title: 'Track bets\nbeyond one\nbookmaker',
      description:
          'Keep stake, odds, payout, and ROI in one clean record instead of scattered screenshots.',
      accentColor: MatchLogColors.secondary,
    ),
    _OnboardingSlide(
      icon: Icons.groups_rounded,
      eyebrow: 'Built for the next layer',
      title: 'Bring your\ncrew in\nlater',
      description:
          'Prediction groups and social play come next. Your personal history stays the foundation.',
      accentColor: MatchLogColors.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(authControllerProvider.notifier).completeOnboarding();
    if (!mounted) {
      return;
    }
    context.go(Routes.login);
  }

  // Future<void> _resetOnboarding() async {
  //   await ref.read(authControllerProvider.notifier).resetOnboarding();
  //   if (!mounted) {
  //     return;
  //   }
  //   setState(() => _pageIndex = 0);
  //   await _pageController.animateToPage(
  //     0,
  //     duration: const Duration(milliseconds: 250),
  //     curve: Curves.easeOut,
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = Theme.of(context);
    final slide = _slides[_pageIndex];

    return Scaffold(
      backgroundColor: MatchLogColors.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.6),
                  radius: 1.4,
                  colors: [
                    slide.accentColor.withValues(alpha: 0.12),
                    MatchLogColors.background,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MatchLogSpacing.lg,
                      vertical: MatchLogSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const MatchLogBrandMark(width: 28, height: 24),
                        MatchLogSpacing.hGapSm,
                        Text(
                          'MatchLog',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: MatchLogColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        // if (kDebugMode)
                        //   TextButton(
                        //     onPressed: isLoading ? null : _resetOnboarding,
                        //     child: const Text('Reset'),
                        //   ),
                        TextButton(
                          onPressed: isLoading ? null : _completeOnboarding,
                          child: Text(
                            'Skip',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: MatchLogColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemBuilder: (context, index) {
                        return _SlideContent(slide: _slides[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MatchLogSpacing.xl,
                      0,
                      MatchLogSpacing.xl,
                      MatchLogSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _slides.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              width: index == _pageIndex ? 32 : 8,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: index == _pageIndex
                                    ? slide.accentColor
                                    : MatchLogColors.surfaceBorder,
                                borderRadius: MatchLogSpacing.roundedFull,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: MatchLogSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (_pageIndex == _slides.length - 1) {
                                      await _completeOnboarding();
                                      return;
                                    }
                                    await _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 320),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MatchLogColors.textPrimary,
                              foregroundColor: MatchLogColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: MatchLogSpacing.roundedLg,
                              ),
                            ),
                            child: Text(
                              _pageIndex == _slides.length - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MatchLogSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: slide.accentColor.withValues(alpha: 0.15),
              borderRadius: MatchLogSpacing.roundedLg,
            ),
            child: Icon(
              slide.icon,
              color: slide.accentColor,
              size: 36,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.xl),
          Text(
            slide.eyebrow.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: slide.accentColor,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.md),
          Text(
            slide.title,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -1.0,
              color: MatchLogColors.textPrimary,
              fontSize: 42,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.xl),
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: MatchLogColors.textSecondary,
              height: 1.6,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
