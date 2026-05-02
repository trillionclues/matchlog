// Stats providers for the diary feature.
// Rebuilds when diary data entries changes.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/usecases/calculate_stats.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'diary_providers.dart';

final calculateStatsUseCaseProvider = Provider<CalculateStats>((ref) {
  return CalculateStats(ref.watch(diaryRepositoryProvider));
});

final statsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const UserStats();

  ref.watch(diaryEntriesProvider);

  return ref.watch(calculateStatsUseCaseProvider).call(userId: user.id);
});
