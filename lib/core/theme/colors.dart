library;

import 'package:flutter/material.dart';

class MatchLogColors {
  MatchLogColors._();

  static const Color background = Color(0xFF0E0B16);
  static const Color surface = Color(0xFF171124);
  static const Color surfaceElevated = Color(0xFF21182F);
  static const Color surfaceBorder = Color(0xFF2C2340);

  static const Color primary = Color(0xFFE90052);
  static const Color primaryLight = Color(0xFFFF3378);
  static const Color primaryDark = Color(0xFFC50046);
  static const Color primarySurface = Color(0xFF2A0F1D);

  static const Color secondary = Color(0xFF963CFF);
  static const Color secondaryLight = Color(0xFFB06FFF);
  static const Color secondaryDark = Color(0xFF7B2DD4);
  static const Color secondarySurface = Color(0xFF1A0F2A);

  static const Color success = Color(0xFF00DC82);
  static const Color successSurface = Color(0xFF0A1F16);
  static const Color error = Color(0xFFFF5C7A);
  static const Color errorSurface = Color(0xFF240C14);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFF241B09);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8AFC8);
  static const Color textTertiary = Color(0xFF8F83A4);
  static const Color textDisabled = Color(0xFF5C536E);

  // when a specific sport needs its own identity apart from the brand.
  static const Color footballAccent = Color(0xFF00DC82);
  static const Color basketballAccent = Color(0xFFFF8A00);
  static const Color f1Accent = Color(0xFFE10600);
  static const Color mmaAccent = Color(0xFFFF6B35);
  static const Color cricketAccent = Color(0xFF00B4D8);
  static const Color tennisAccent = Color(0xFFCCFF00);

  // hero cards, Year in Review, leaderboard top-3 rows
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
    colors: [Color(0x40FF5C7A), Color(0x00000000)],
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

  // returns the sport accent color for a given sport string.
  // falls back to [primary] for unknown sports.
  static Color sportAccent(String sport) {
    return switch (sport.toLowerCase()) {
      'football' => footballAccent,
      'basketball' => basketballAccent,
      'formula1' => f1Accent,
      'mma' => mmaAccent,
      'cricket' => cricketAccent,
      'tennis' => tennisAccent,
      _ => primary,
    };
  }
}

class MatchLogLightColors {
  MatchLogLightColors._();

  static const Color background = Color(0xFFF7F4FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFCFAFF);
  static const Color surfaceBorder = Color(0xFFE7DFF1);

  static const Color primary = Color(0xFFC61B59);
  static const Color primaryLight = Color(0xFFE0467B);
  static const Color primaryDark = Color(0xFFA31549);
  static const Color primarySurface = Color(0xFFFBE4EC);

  static const Color secondary = Color(0xFF7C59E8);
  static const Color secondaryLight = Color(0xFF9A7AF2);
  static const Color secondaryDark = Color(0xFF6542CE);
  static const Color secondarySurface = Color(0xFFF0EAFF);

  static const Color success = Color(0xFF00A96E);
  static const Color successSurface = Color(0xFFDFF8ED);
  static const Color error = Color(0xFFD94268);
  static const Color errorSurface = Color(0xFFFDE7ED);
  static const Color warning = Color(0xFFC98700);
  static const Color warningSurface = Color(0xFFFFF3D7);

  static const Color textPrimary = Color(0xFF1B1327);
  static const Color textSecondary = Color(0xFF5E536F);
  static const Color textTertiary = Color(0xFF988DAA);
  static const Color textDisabled = Color(0xFFC8C0D3);
}
