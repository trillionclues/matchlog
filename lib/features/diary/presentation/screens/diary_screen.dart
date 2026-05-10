library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/email_verification_banner.dart';
import '../../domain/repositories/diary_repository.dart';
import '../providers/diary_providers.dart';
import '../widgets/match_card.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;
    final entries = ref.watch(diaryEntriesProvider);
    final activeFilter = ref.watch(diaryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Stats',
            onPressed: () => context.push(Routes.stats),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push(Routes.profile),
          ),
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.more_vert_rounded),
          //   onSelected: (value) async {
          //     if (value == 'logout') {
          //       await ref.read(authControllerProvider.notifier).signOut();
          //       if (context.mounted) {
          //         MatchLogSnackBar.info(context, 'Signed out.');
          //       }
          //     }
          //   },
          //   itemBuilder: (_) => [
          //     PopupMenuItem(
          //       value: 'settings',
          //       onTap: () => context.push(Routes.settings),
          //       child: const Row(
          //         children: [
          //           Icon(Icons.settings_outlined, size: 20),
          //           SizedBox(width: MatchLogSpacing.sm),
          //           Text('Settings'),
          //         ],
          //       ),
          //     ),
          //     PopupMenuItem(
          //       value: 'logout',
          //       child: Row(
          //         children: [
          //           Icon(Icons.logout_rounded, size: 20, color: colorScheme.error),
          //           const SizedBox(width: MatchLogSpacing.sm),
          //           Text('Sign out', style: TextStyle(color: colorScheme.error)),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        
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

          _FilterChips(
            active: activeFilter,
            onChanged: (filter) =>
                ref.read(diaryFilterProvider.notifier).state = filter,
          ),

          Expanded(
            child: entries.when(
              loading: () => ShimmerList(
                itemBuilder: () => const MatchCardShimmer(),
              ),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(diaryEntriesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.book_outlined,
                    title: 'Your match diary',
                    subtitle:
                        'Start logging matches to build your sports diary.',
                    ctaText: 'Log a match',
                    onCta: () => context.push(Routes.logMatch),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(diaryEntriesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: MatchLogSpacing.sm,
                      bottom: 80, // clear the FAB
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) => MatchCard(
                      entry: list[i],
                      onTap: () => context.push(Routes.matchDetail.replaceAll(':id', list[i].id)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final DiaryFilter active;
  final ValueChanged<DiaryFilter> onChanged;

  const _FilterChips({required this.active, required this.onChanged});

  static const _filters = [
    (DiaryFilter.all, 'All'),
    (DiaryFilter.stadium, 'Stadium'),
    (DiaryFilter.tv, 'TV'),
    (DiaryFilter.streaming, 'Streaming'),
    (DiaryFilter.radio, 'Radio'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: MatchLogSpacing.lg),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: MatchLogSpacing.sm),
        itemBuilder: (_, i) {
          final (filter, label) = _filters[i];
          return FilterChip(
            label: Text(label),
            selected: active == filter,
            onSelected: (_) => onChanged(filter),
          );
        },
      ),
    );
  }
}
