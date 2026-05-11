// eligibility predicate for the Stadium Check-In feature.

// An entry is eligible for check-in iff ALL three conditions hold:
//   1. watchType == 'stadium'
//   2. geoVerified == false
//   3. createdAt calendar date (year/month/day) == today in device local timezone

// The same-day constraint (condition 3) is the critical anti-exploit guard.
// It prevents retroactive verification of past matches and closes the
// "venue squatter" exploit where a user physically present at a stadium
// could verify old entries logged at the same location.

// This is a pure function with no side effects and no dependencies.
// The [now] parameter is injectable so tests can control the clock.

library;

import '../entities/match_entry.dart';

class CheckInEligibility {
  const CheckInEligibility();

  // Returns `true` iff [entry] is eligible for stadium check-in.
  bool call(MatchEntry entry, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final matchDate = entry.createdAt;

    final isSameDay = matchDate.year == today.year &&
        matchDate.month == today.month &&
        matchDate.day == today.day;

    return entry.watchType == 'stadium' && !entry.geoVerified && isSameDay;
  }
}
