import '../entities/match_entry.dart';

/// Calculates the current and longest streaks from a list of [MatchEntry]s.
///
/// Returns a record `(currentStreak, longestStreak)`.
(int current, int longest) calculateStreaks(List<MatchEntry> entries) {
  if (entries.isEmpty) return (0, 0);

  final days = entries
      .map((e) =>
          DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  if (days.isEmpty) return (0, 0);

  var currentStreak = 1;
  var longestStreak = 1;
  var streak = 1;

  // Check if current streak is active (last entry was today or yesterday).
  final today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final isActive = days.first.difference(today).inDays.abs() <= 1;

  for (var i = 1; i < days.length; i++) {
    final diff = days[i - 1].difference(days[i]).inDays;
    if (diff == 1) {
      streak++;
    } else {
      if (i == 1 || (i > 1 && isActive)) {
        currentStreak = streak;
      }
      longestStreak = streak > longestStreak ? streak : longestStreak;
      streak = 1;
    }
  }

  longestStreak = streak > longestStreak ? streak : longestStreak;
  if (isActive) currentStreak = streak;
  if (!isActive) currentStreak = 0;

  return (currentStreak, longestStreak);
}
