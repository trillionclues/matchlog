// MatchLog color palette — FPL-inspired dark theme

library;

import 'package:flutter/material.dart';

class MatchLogColors {
  MatchLogColors._();

  // Backgrounds
  static const Color background      = Color(0xFF0E0B16); // Deep dark purple-black
  static const Color surface         = Color(0xFF1A1625); // Card / surface background
  static const Color surfaceElevated = Color(0xFF241F31); // Elevated cards, modals
  static const Color surfaceBorder   = Color(0xFF2D2640); // Subtle borders

  // Primary — FPL Razzmatazz magenta 
  static const Color primary        = Color(0xFFE90052);
  static const Color primaryLight   = Color(0xFFFF3378); // Hover / pressed
  static const Color primaryDark    = Color(0xFFB80042); // Active state
  static const Color primarySurface = Color(0xFF2A0F1D); // Tint on dark bg

  // Secondary — Electric violet 
  static const Color secondary        = Color(0xFF963CFF);
  static const Color secondaryLight   = Color(0xFFB06FFF);
  static const Color secondaryDark    = Color(0xFF7B2DD4);
  static const Color secondarySurface = Color(0xFF1A0F2A);

  // Semantic 
  static const Color success        = Color(0xFF00DC82); // Bet won, correct prediction
  static const Color successSurface = Color(0xFF0A1F16);
  static const Color error          = Color(0xFFFF4D6A); // Bet lost, incorrect
  static const Color errorSurface   = Color(0xFF1F0A10);
  static const Color warning        = Color(0xFFFFB800); // Pending bets
  static const Color warningSurface = Color(0xFF1F1A0A);

  // Text 
  static const Color textPrimary   = Color(0xFFFFFFFF); // Headlines, primary text
  static const Color textSecondary = Color(0xFFB0A8C0); // Body text, descriptions
  static const Color textTertiary  = Color(0xFF6B6080); // Captions, timestamps
  static const Color textDisabled  = Color(0xFF4A4058); // Disabled states

  // Sport-specific accents 
  // Used when sport context is active (e.g., football diary entries get green
  // left border, basketball entries get orange, etc.)
  static const Color footballAccent   = Color(0xFF00DC82); // Green — the pitch
  static const Color basketballAccent = Color(0xFFFF8A00); // Orange
  static const Color f1Accent         = Color(0xFFE10600); // F1 red
  static const Color mmaAccent        = Color(0xFFFF6B35); // UFC orange-red
  static const Color cricketAccent    = Color(0xFF00B4D8); // Blue
  static const Color tennisAccent     = Color(0xFFCCFF00); // Yellow-green

  // Gradient helpers 
  // Used for hero cards, Year in Review, leaderboard top-3 rows
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primary],
  );

  static const LinearGradient wonGradient = LinearGradient(
    colors: [Color(0x4000DC82), Color(0x00000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lostGradient = LinearGradient(
    colors: [Color(0x40FF4D6A), Color(0x00000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
  );

  static const LinearGradient silverGradient = LinearGradient(
    colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
  );

  static const LinearGradient bronzeGradient = LinearGradient(
    colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
  );

  // Returns the sport accent color for a given sport string.
  // Falls back to [primary] for unknown sports.
  static Color sportAccent(String sport) {
    return switch (sport.toLowerCase()) {
      'football'   => footballAccent,
      'basketball' => basketballAccent,
      'formula1'   => f1Accent,
      'mma'        => mmaAccent,
      'cricket'    => cricketAccent,
      'tennis'     => tennisAccent,
      _            => primary,
    };
  }
}
