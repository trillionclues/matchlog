// Stats providers for diary feature.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/match_entry.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/usecases/calculate_stats.dart';
import '../../domain/utils/streak_calculator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'diary_providers.dart';
import 'heatmap_models.dart';

final calculateStatsUseCaseProvider = Provider<CalculateStats>((ref) {
  return CalculateStats(ref.watch(diaryRepositoryProvider));
});

final statsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const UserStats();

  ref.watch(diaryEntriesProvider);

  return ref.watch(calculateStatsUseCaseProvider).call(userId: user.id);
});

final heatmapProvider =
    StreamProvider.autoDispose<HeatmapData>((ref) async* {
  final entriesAsync = ref.watch(diaryEntriesProvider);

  yield* entriesAsync.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (entries) => Stream.value(_buildHeatmapData(entries)),
  );
});

// Builds a [HeatmapData] from the full list of [MatchEntry] objects.
//
// The 364-day window runs from [_today] − 363 days (inclusive) to [_today].
// Entries outside the window are excluded from cell counts but ALL entries
// are passed to [calculateStreaks] so streak numbers are not artificially
// capped by the visible window.
HeatmapData _buildHeatmapData(List<MatchEntry> entries) {
  final today = _today();
  final windowStart = today.subtract(const Duration(days: 363));

  // Group entries by normalised date, restricted to the window.
  final countByDate = <DateTime, int>{};
  for (final e in entries) {
    final d = _normalise(e.createdAt);
    if (!d.isBefore(windowStart) && !d.isAfter(today)) {
      countByDate[d] = (countByDate[d] ?? 0) + 1;
    }
  }

  // one HeatmapDay per day in the window (oldest first).
  final days = <HeatmapDay>[];
  for (var i = 0; i < 364; i++) {
    final date = windowStart.add(Duration(days: i));
    final count = countByDate[date] ?? 0;
    days.add(HeatmapDay(
      date: date,
      count: count,
      tier: IntensityTierX.fromCount(count),
    ));
  }

  // Pass ALL entries (not just windowed) so streaks reflect full history.
  final streaks = calculateStreaks(entries);
  return HeatmapData(
    days: days,
    streaks: StreakSummary(
      currentStreak: streaks.$1,
      longestStreak: streaks.$2,
    ),
  );
}

/// Returns today's date normalised to midnight local time.
DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Normalises [dt] to midnight local time (strips time-of-day component).
DateTime _normalise(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
