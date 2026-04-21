// Drift type converters and domain enums.

/// All domain enums defined and shared between Drift tables (data layer)
// and the domain entities without creating circular imports.

// Enums are stored as integers in SQLite via Drift's intEnum converter.
// JSON columns (photos list, sportMetadata map) are stored as TEXT.

// IMPORTANT: Order of enum values matters — changing the order of
// existing values is a breaking schema change. Always append new values at the end.
library;

import 'dart:convert';
import 'package:drift/drift.dart';

enum Sport {
  football,
  basketball,
  formula1,
  mma,
  cricket,
  tennis,
}

enum WatchType {
  stadium,   // In-person attendance
  tv,        // Traditional broadcast
  streaming, // (DAZN, ESPN+, etc.)
  radio,     // Audio only
}

enum BetType {
  win,          // Match winner (football: home/draw/away)
  draw,
  btts,
  overUnder,
  correctScore,
  accumulator,  // Multi-selection parlay
  moneyline,    // Basketball/US sports winner
  prop,
}

enum BetVisibility {
  public,
  friends,  // mutual follows only
  private_, // owner only (trailing _ avoids Dart keyword conflict)
}

enum UserTier {
  free, // (limited bets/month, 1 group)
  pro,  // ($1.99/mo) — unlimited bets, AI insights
  crew, // ($2.99/mo) — unlimited groups, Prediction Leagues
}

enum GroupPrivacy {
  open, 
  inviteOnly,
}

enum GroupRole {
  admin,  // can manage members and pin predictions
  member,
}

enum PredictionConfidence {
  high,
  medium,
  low,
}

// Bet slip scan verification status.
enum VerificationStatus {
  pending,  // Awaiting cross-reference with match results
  verified, // Results confirmed against API data
  rejected, // Could not be verified (missing fixture data, etc.)
  flagged,  // Fraud heuristics triggered
}

// Truth Score tier for verified tipsters.
enum TruthTier {
  unverified, // Score 0-29, no verified slips
  bronze,     // Score 30-54
  silver,     // Score 55-74
  gold,       // Score 75-89
  diamond,    // Score 90-100
}

enum ActivityType {
  matchLogged,
  betPlaced,
  predictionMade,
  betSettled,
  reviewPosted,
  groupJoined,
  slipVerified,
}

// Converts between [List<dynamic>] and a TEXT SQLite column.
// Used for: photos (list of Storage URLs), leagueFocus, fraudFlags.
// Null-safe: encodes null as '[]', decodes '[]' as empty list.
class JsonListConverter extends TypeConverter<List<dynamic>, String> {
  const JsonListConverter();

  @override
  List<dynamic> fromSql(String fromDb) {
    try {
      final decoded = jsonDecode(fromDb);
      return decoded is List ? decoded : [];
    } catch (_) {
      return [];
    }
  }

  @override
  String toSql(List<dynamic> value) => jsonEncode(value);
}

// Converts between [Map<String, dynamic>] and a TEXT SQLite column.
// Used for: sportMetadata, breakdown (TruthScore), extractedBets.
// Null-safe: encodes null as '{}', decodes '{}' as empty map.
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    try {
      final decoded = jsonDecode(fromDb);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) => jsonEncode(value);
}
