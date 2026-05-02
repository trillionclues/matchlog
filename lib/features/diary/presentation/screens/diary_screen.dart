library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../../shared/widgets/snackbar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/email_verification_banner.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(Routes.profile),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  MatchLogSnackBar.info(context, 'Signed out.');
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'settings',
                onTap: () => context.push(Routes.settings),
                child: const Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: MatchLogSpacing.sm),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: colorScheme.error),
                    const SizedBox(width: MatchLogSpacing.sm),
                    Text('Sign out', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const MatchLogBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.logMatch),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          if (authUser != null && !authUser.emailVerified)
            const EmailVerificationBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: MatchLogSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    MatchLogSpacing.gapLg,
                    Text(
                      'Your match diary',
                      style: theme.textTheme.headlineMedium,
                    ),
                    MatchLogSpacing.gapSm,
                    Text(
                      'Start logging matches to build your sports diary.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
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
