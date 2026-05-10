library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/betting/presentation/screens/betting_screen.dart';
import '../../features/betting/presentation/screens/log_bet_screen.dart';
import '../../features/diary/presentation/screens/diary_screen.dart';
import '../../features/diary/presentation/screens/log_match_screen.dart';
import '../../features/diary/presentation/screens/match_detail_screen.dart';
import '../../features/diary/presentation/screens/stats_dashboard.dart';
import '../../features/groups/presentation/screens/group_screens.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/social/presentation/screens/feed_screen.dart';
import '../../features/social/presentation/screens/user_profile_screen.dart';
import '../../features/splash/splash_screen.dart';
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

      if (startupReady.isLoading && !startupReady.hasValue) {
        return isLoadingRoute ? null : Routes.loading;
      }

      if (startupReady.hasError && !startupReady.hasValue) {
        return isLoadingRoute ? null : Routes.loading;
      }

      // Only redirect to loading during a genuine cold start (no value yet).
      // When the auth stream refreshes (e.g. Google Sign-In cancelled),
      // isLoading is true but valueOrNull still holds the previous value.
      // Bouncing to splash in that case causes a flash.
      final authColdLoading = authState.isLoading && !authState.hasValue;
      final onboardingColdLoading =
          onboardingState.isLoading && !onboardingState.hasValue;

      if (authColdLoading || onboardingColdLoading) {
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
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64),
            SizedBox(height: 16),
            Text('Page not found'),
          ],
        ),
      ),
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
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: RegisterScreen()),
      ),
      GoRoute(
        path: Routes.diary,
        name: 'diary',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DiaryScreen(),
        ),
      ),
      GoRoute(
        path: Routes.logMatch,
        name: 'logMatch',
        builder: (context, state) => const LogMatchScreen(),
      ),
      GoRoute(
        path: Routes.matchDetail,
        name: 'matchDetail',
        builder: (context, state) => MatchDetailScreen(
          entryId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.stats,
        name: 'stats',
        builder: (context, state) => const StatsDashboard(),
      ),
      GoRoute(
        path: Routes.betting,
        name: 'betting',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BettingScreen(),
        ),
      ),
      GoRoute(
        path: Routes.logBet,
        name: 'logBet',
        builder: (context, state) => const LogBetScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ProfileScreen(),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.feed,
        name: 'feed',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: FeedScreen(),
        ),
      ),
      GoRoute(
        path: Routes.userProfile,
        name: 'userProfile',
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters['userId'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.groups,
        name: 'groups',
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: Routes.createGroup,
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: Routes.groupDetail,
        name: 'groupDetail',
        builder: (context, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.joinGroup,
        name: 'joinGroup',
        builder: (context, state) => JoinGroupScreen(
          code: state.pathParameters['code'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.aiInsights,
        name: 'aiInsights',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('AI Insights')),
          body: const Center(child: Text('AI Insights')),
        ),
      ),
      GoRoute(
        path: Routes.yearInReview,
        name: 'yearInReview',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Year in Review')),
          body: const Center(child: Text('Year in Review')),
        ),
      ),
      GoRoute(
        path: Routes.subscription,
        name: 'subscription',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Upgrade')),
          body: const Center(child: Text('Subscription')),
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

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
