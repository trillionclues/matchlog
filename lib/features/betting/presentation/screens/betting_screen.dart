library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/widgets/bottom_nav.dart';

class BettingScreen extends ConsumerWidget {
  const BettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Betting')),
      bottomNavigationBar: const MatchLogBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.logBet),
        child: const Icon(Icons.add_rounded),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_rounded,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('Your bet tracker', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Log bets to track your ROI across bookmakers.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
