library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats.freezed.dart';
part 'user_stats.g.dart';

@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    // ── Diary stats ──
    @Default(0) int totalMatchesWatched,
    @Default(0) int matchesThisMonth,
    @Default({}) Map<String, int> matchesByLeague,
    @Default({}) Map<String, int> matchesByTeam,
    @Default({}) Map<String, int> matchesByWatchType,
    @Default(0.0) double averageRating,
    @Default(0) int stadiumVisits,
    @Default(0) int currentStreak,
    @Default(0) int longestStreak,

    // ── Betting stats ──
    @Default(0) int totalBets,
    @Default(0) int betsWon,
    @Default(0) int betsLost,
    @Default(0) int betsPending,
    @Default(0.0) double winRate,
    @Default(0.0) double totalStaked,
    @Default(0.0) double totalPayout,
    @Default(0.0) double roi,
    @Default({}) Map<String, double> roiByLeague,
    @Default({}) Map<String, double> roiByBetType,
    @Default({}) Map<String, double> roiByBookmaker,
    String? mostProfitableLeague,
    String? mostProfitableBetType,
    String? leastProfitableBookmaker,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}
