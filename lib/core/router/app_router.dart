
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_config.dart';
import 'routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: AppConfig.instance.isStaging,
    initialLocation: Routes.diary,

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
        path: Routes.diary,
        name: 'diary',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Diary',
          icon: Icons.book_outlined,
        ),
      ),
      GoRoute(
        path: Routes.logMatch,
        name: 'logMatch',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Log Match',
          icon: Icons.add_circle_outline_rounded,
        ),
      ),
      GoRoute(
        path: Routes.matchDetail,
        name: 'matchDetail',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Match Detail',
          icon: Icons.sports_soccer_rounded,
          subtitle: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: Routes.betting,
        name: 'betting',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Betting',
          icon: Icons.track_changes_rounded,
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
        ),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Profile',
          icon: Icons.person_outline_rounded,
        ),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Settings',
          icon: Icons.settings_outlined,
        ),
      ),

      GoRoute(
        path: Routes.feed,
        name: 'feed',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Feed',
          icon: Icons.dynamic_feed_rounded,
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
}

// Temporary placeholder screen used until feature screens are implemented.
// Shows the route name and icon so navigation can be tested end-to-end.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;

  const _PlaceholderScreen({
    required this.title,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
