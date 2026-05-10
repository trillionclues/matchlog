library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/snackbar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: MatchLogSpacing.screenPadding,
        children: [
          MatchLogSpacing.gapLg,
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                (authUser?.displayName ?? '?')[0].toUpperCase(),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          MatchLogSpacing.gapMd,
          Text(
            authUser?.displayName ?? 'MatchLog User',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            authUser?.email ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MatchLogSpacing.xxl),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: colorScheme.error),
            title: Text(
              'Sign out',
              style: TextStyle(color: colorScheme.error),
            ),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                MatchLogSnackBar.info(context, 'Signed out.');
              }
            },
          ),
        ],
      ),
    );
  }
}
