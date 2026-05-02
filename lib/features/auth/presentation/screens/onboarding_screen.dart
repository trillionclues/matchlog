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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.auto_stories_rounded,
      eyebrow: 'Your sports diary',
      title: 'Log every match that matters',
      description:
          'Build a sharp watch history with ratings, notes, and memories you can actually revisit.',
      highlights: ['Ratings', 'Notes', 'Watch history'],
    ),
    _OnboardingSlide(
      icon: Icons.track_changes_rounded,
      eyebrow: 'Betting without clutter',
      title: 'Track bets beyond one bookmaker',
      description:
          'Keep stake, odds, payout, and ROI in one clean record instead of scattered screenshots.',
      highlights: ['Odds', 'Payouts', 'ROI'],
    ),
    _OnboardingSlide(
      icon: Icons.groups_rounded,
      eyebrow: 'Built for the next layer',
      title: 'Bring your crew in later',
      description:
          'Prediction groups and social play come next. Your personal history stays the foundation.',
      highlights: ['Groups', 'Predictions', 'Shares'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(authControllerProvider.notifier).completeOnboarding();
    if (!mounted) {
      return;
    }
    context.go(Routes.login);
  }

  Future<void> _resetOnboarding() async {
    await ref.read(authControllerProvider.notifier).resetOnboarding();
    if (!mounted) {
      return;
    }
    setState(() => _pageIndex = 0);
    await _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final slide = _slides[_pageIndex];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              colorScheme.surface.withValues(alpha: 0.96),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _AmbientOrb(
                size: 240,
                color: MatchLogColors.secondary.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              left: -60,
              bottom: 180,
              child: _AmbientOrb(
                size: 200,
                color: MatchLogColors.primary.withValues(alpha: 0.08),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(MatchLogSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MatchLogSpacing.md,
                            vertical: MatchLogSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: MatchLogSpacing.roundedFull,
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const MatchLogBrandMark(width: 26, height: 22),
                              MatchLogSpacing.hGapSm,
                              Text(
                                'MatchLog',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (kDebugMode)
                          TextButton(
                            onPressed: isLoading ? null : _resetOnboarding,
                            child: const Text('Reset'),
                          ),
                        TextButton(
                          onPressed: isLoading ? null : _completeOnboarding,
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                    const SizedBox(height: MatchLogSpacing.xl),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MatchLogSpacing.md,
                          vertical: MatchLogSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer
                              .withValues(alpha: 0.45),
                          borderRadius: MatchLogSpacing.roundedFull,
                        ),
                        child: Text(
                          'Step ${_pageIndex + 1} of ${_slides.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: MatchLogSpacing.lg),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (index) => setState(() => _pageIndex = index),
                        itemBuilder: (context, index) {
                          return _OnboardingCard(
                            slide: _slides[index],
                            pageIndex: index,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: MatchLogSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(MatchLogSpacing.lg),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: MatchLogSpacing.roundedLg,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: MatchLogSpacing.sm,
                            runSpacing: MatchLogSpacing.sm,
                            children: slide.highlights
                                .map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: MatchLogSpacing.md,
                                      vertical: MatchLogSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.10),
                                      borderRadius:
                                          MatchLogSpacing.roundedFull,
                                    ),
                                    child: Text(
                                      item,
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: MatchLogSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _slides.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: index == _pageIndex ? 28 : 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: index == _pageIndex
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  borderRadius:
                                      MatchLogSpacing.roundedFull,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: MatchLogSpacing.lg),
                          SizedBox(
                            width: double.infinity,
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
                                            const Duration(milliseconds: 280),
                                        curve: Curves.easeOutCubic,
                                      );
                                    },
                              child: Text(
                                _pageIndex == _slides.length - 1
                                    ? 'Get Started'
                                    : 'Continue',
                              ),
                            ),
                          ),
                        ],
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

class _OnboardingSlide {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> highlights;

  const _OnboardingSlide({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.highlights,
  });
}

class _OnboardingCard extends StatelessWidget {
  final _OnboardingSlide slide;
  final int pageIndex;

  const _OnboardingCard({
    required this.slide,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MatchLogSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: MatchLogSpacing.roundedXl,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: MatchLogColors.heroGradient,
              borderRadius: MatchLogSpacing.roundedLg,
            ),
            child: Icon(
              slide.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.xl),
          Text(
            slide.eyebrow.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.sm),
          Text(
            slide.title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.md),
          Text(
            slide.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(MatchLogSpacing.lg),
            decoration: BoxDecoration(
              color: pageIndex.isEven
                  ? MatchLogColors.primarySurface.withValues(alpha: 0.55)
                  : MatchLogColors.secondarySurface.withValues(alpha: 0.55),
              borderRadius: MatchLogSpacing.roundedLg,
            ),
            child: Row(
              children: [
                Text(
                  '0${pageIndex + 1}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: MatchLogSpacing.lg),
                Expanded(
                  child: Text(
                    slide.highlights.join(' • '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
