library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/widgets/email_verification_banner.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../theme/spacing.dart';
import 'routes.dart';

final startupReadyProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    Future<void>.delayed(const Duration(milliseconds: 1500)),
    ref.watch(authStateProvider.future),
    ref.watch(onboardingCompletedProvider.future),
  ]);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listenable that fires whenever auth or onboarding state changes.
  // GoRouter re-evaluates its redirect when this notifies.
  final notifier = _RouterRefreshNotifier();

  ref.listen(authStateProvider, (_, __) => notifier.notify());
  ref.listen(onboardingCompletedProvider, (_, __) => notifier.notify());
  ref.listen(startupReadyProvider, (_, __) => notifier.notify());

  ref.onDispose(notifier.dispose);

  return GoRouter(
    // debugLogDiagnostics: AppConfig.instance.isStaging,
    initialLocation: Routes.loading,
    refreshListenable: notifier,
    redirect: (context, state) {
      final startupReady = ref.read(startupReadyProvider);
      final authState = ref.read(authStateProvider);
      final onboardingState = ref.read(onboardingCompletedProvider);

      final location = state.matchedLocation;
      final isLoadingRoute = location == Routes.loading;
      final onboardingComplete = onboardingState.valueOrNull ?? false;
      final user = authState.valueOrNull;

      if (startupReady.isLoading) {
        return isLoadingRoute ? null : Routes.loading;
      }

      if (startupReady.hasError) {
        return isLoadingRoute ? null : Routes.loading;
      }

      if (authState.isLoading || onboardingState.isLoading) {
        return isLoadingRoute ? null : Routes.loading;
      }

      if (onboardingState.hasError || authState.hasError) {
        return isLoadingRoute ? null : Routes.loading;
      }

      if (!onboardingComplete && user == null) {
        return location == Routes.onboarding ? null : Routes.onboarding;
      }

      if (location == Routes.loading) {
        if (user != null) {
          return Routes.diary;
        }
        return Routes.login;
      }

      if (user == null) {
        return _isPublicRoute(location) ? null : Routes.login;
      }

      if (location == Routes.login ||
          location == Routes.register ||
          location == Routes.onboarding) {
        return Routes.diary;
      }

      if (!user.emailVerified && _isSocialRoute(location)) {
        return Routes.diary;
      }

      return null;
    },
    errorBuilder: (context, state) => const _PlaceholderScreen(
      title: 'Page Not Found',
      icon: Icons.search_off_rounded,
    ),
    routes: [
      GoRoute(
        path: Routes.home,
        redirect: (_, __) => Routes.diary,
      ),
      GoRoute(
        path: Routes.loading,
        name: 'loading',
        builder: (context, state) => const _LoadingScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.diary,
        name: 'diary',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Diary',
          icon: Icons.book_outlined,
          showVerificationBanner: true,
          showBottomNav: true,
        ),
      ),
      GoRoute(
        path: Routes.logMatch,
        name: 'logMatch',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Log Match',
          icon: Icons.add_circle_outline_rounded,
          showVerificationBanner: true,
        ),
      ),
      GoRoute(
        path: Routes.matchDetail,
        name: 'matchDetail',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Match Detail',
          icon: Icons.sports_soccer_rounded,
          subtitle: state.pathParameters['id'],
          showVerificationBanner: true,
        ),
      ),
      GoRoute(
        path: Routes.betting,
        name: 'betting',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Betting',
          icon: Icons.track_changes_rounded,
          showBottomNav: true,
        ),
      ),
      GoRoute(
        path: Routes.logBet,
        name: 'logBet',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Log Bet',
          icon: Icons.add_circle_outline_rounded,
        ),
      ),
      GoRoute(
        path: Routes.stats,
        name: 'stats',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Stats',
          icon: Icons.bar_chart_rounded,
          showVerificationBanner: true,
        ),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Profile',
          icon: Icons.person_outline_rounded,
          showVerificationBanner: true,
          showBottomNav: true,
        ),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Settings',
          icon: Icons.settings_outlined,
          showVerificationBanner: true,
        ),
      ),
      GoRoute(
        path: Routes.feed,
        name: 'feed',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Feed',
          icon: Icons.dynamic_feed_rounded,
          showBottomNav: true,
        ),
      ),
      GoRoute(
        path: Routes.userProfile,
        name: 'userProfile',
        builder: (context, state) => _PlaceholderScreen(
          title: 'User Profile',
          icon: Icons.person_outline_rounded,
          subtitle: state.pathParameters['userId'],
        ),
      ),
      GoRoute(
        path: Routes.groups,
        name: 'groups',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Bookie Groups',
          icon: Icons.group_outlined,
        ),
      ),
      GoRoute(
        path: Routes.createGroup,
        name: 'createGroup',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Create Group',
          icon: Icons.group_add_outlined,
        ),
      ),
      GoRoute(
        path: Routes.groupDetail,
        name: 'groupDetail',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Group Detail',
          icon: Icons.group_outlined,
          subtitle: state.pathParameters['groupId'],
        ),
      ),
      GoRoute(
        path: Routes.joinGroup,
        name: 'joinGroup',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Join Group',
          icon: Icons.group_add_outlined,
          subtitle: state.pathParameters['code'],
        ),
      ),
      GoRoute(
        path: Routes.aiInsights,
        name: 'aiInsights',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'AI Insights',
          icon: Icons.auto_awesome_rounded,
        ),
      ),
      GoRoute(
        path: Routes.yearInReview,
        name: 'yearInReview',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Year in Review',
          icon: Icons.calendar_today_rounded,
        ),
      ),
      GoRoute(
        path: Routes.subscription,
        name: 'subscription',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Upgrade',
          icon: Icons.star_outline_rounded,
        ),
      ),
    ],
  );
});

bool _isPublicRoute(String location) {
  return location == Routes.loading ||
      location == Routes.login ||
      location == Routes.register ||
      location == Routes.onboarding;
}

bool _isSocialRoute(String location) {
  return location == Routes.feed ||
      location == Routes.groups ||
      location.startsWith('/groups/');
}

class _LoadingScreen extends ConsumerWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = ref.watch(startupReadyProvider).hasError ||
        ref.watch(authStateProvider).hasError ||
        ref.watch(onboardingCompletedProvider).hasError;

    return SplashScreen(
      hasError: hasError,
      onRetry: () {
        ref.invalidate(startupReadyProvider);
        ref.invalidate(authStateProvider);
        ref.invalidate(onboardingCompletedProvider);
      },
    );
  }
}

class _PlaceholderScreen extends ConsumerWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final bool showVerificationBanner;
  final bool showBottomNav;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    this.subtitle,
    this.showVerificationBanner = false,
    this.showBottomNav = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: showBottomNav ? const MatchLogBottomNav() : null,
      body: Column(
        children: [
          if (showVerificationBanner &&
              authUser != null &&
              !authUser.emailVerified)
            const EmailVerificationBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: MatchLogSpacing.cardPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    MatchLogSpacing.gapLg,
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (subtitle != null) ...[
                      MatchLogSpacing.gapSm,
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
