// Factory that aps Sport enum values to display names, icons, and accent colors.
// Used throughout for sport-aware theming and filtering.

library;

import 'package:flutter/material.dart';
import '../../core/database/type_converters.dart';
import '../../core/theme/colors.dart';

class SportConfig {
  final Sport sport;
  final String displayName;
  final String emoji;
  final IconData icon;
  final Color accentColor;

  // Whether this sport is available in the current phase.
  // Football first; other sports later.
  final bool isAvailable;

  const SportConfig({
    required this.sport,
    required this.displayName,
    required this.emoji,
    required this.icon,
    required this.accentColor,
    this.isAvailable = false,
  });
}

const kSportConfigs = <Sport, SportConfig>{
  Sport.football: SportConfig(
    sport: Sport.football,
    displayName: 'Football',
    emoji: '⚽',
    icon: Icons.sports_soccer_rounded,
    accentColor: MatchLogColors.footballAccent,
    isAvailable: true, // Phase 1
  ),
  Sport.basketball: SportConfig(
    sport: Sport.basketball,
    displayName: 'Basketball',
    emoji: '🏀',
    icon: Icons.sports_basketball_rounded,
    accentColor: MatchLogColors.basketballAccent,
  ),
  Sport.formula1: SportConfig(
    sport: Sport.formula1,
    displayName: 'Formula 1',
    emoji: '🏎️',
    icon: Icons.speed_rounded,
    accentColor: MatchLogColors.f1Accent,
  ),
  Sport.mma: SportConfig(
    sport: Sport.mma,
    displayName: 'MMA / UFC',
    emoji: '🥊',
    icon: Icons.sports_mma_rounded,
    accentColor: MatchLogColors.mmaAccent,
  ),
  Sport.cricket: SportConfig(
    sport: Sport.cricket,
    displayName: 'Cricket',
    emoji: '🏏',
    icon: Icons.sports_cricket_rounded,
    accentColor: MatchLogColors.cricketAccent,
  ),
  Sport.tennis: SportConfig(
    sport: Sport.tennis,
    displayName: 'Tennis',
    emoji: '🎾',
    icon: Icons.sports_tennis_rounded,
    accentColor: MatchLogColors.tennisAccent,
  ),
};

// Returns the [SportConfig] for a given [Sport].
SportConfig sportConfig(Sport sport) =>
    kSportConfigs[sport] ?? kSportConfigs[Sport.football]!;

// Returns only the sports available in the current phase.
List<SportConfig> get availableSports =>
    kSportConfigs.values.where((s) => s.isAvailable).toList();
