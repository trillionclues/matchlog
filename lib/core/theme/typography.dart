// MatchLog typography system.
// Two typefaces:
// - Inter (Google Fonts) — all UI text: headlines, body, labels, stat numbers
// - JetBrains Mono (Google Fonts) — odds display only

// Usage:
//   Text('Arsenal', style: MatchLogTypography.headlineMedium)
//   Text('2.10', style: MatchLogTypography.oddsDisplay)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class MatchLogTypography {
  MatchLogTypography._();

  // ── Headlines
  // 32px / w800 — screen titles, Year in Review hero numbers
  static TextStyle get headlineXL => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: MatchLogColors.textPrimary,
        letterSpacing: -0.5,
      );

  // 24px / w700 — section headers, match score display
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: MatchLogColors.textPrimary,
        letterSpacing: -0.3,
      );

  // 20px / w700 — card titles, screen sub-headers
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: MatchLogColors.textPrimary,
      );

  // 16px / w600 — list item titles, form section labels
  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: MatchLogColors.textPrimary,
      );

  // Body
  // 16px / w400 — primary body text, match reviews
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: MatchLogColors.textSecondary,
        height: 1.5,
      );

  // 14px / w400 — secondary body text, card descriptions
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: MatchLogColors.textSecondary,
        height: 1.5,
      );

  // 12px / w400 — captions, timestamps, helper text
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: MatchLogColors.textTertiary,
      );

  // Labels
  // 14px / w600 — button text, tab labels, chip text
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: MatchLogColors.textPrimary,
        letterSpacing: 0.5,
      );

  // 11px / w500 — micro labels, badge text, metadata
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: MatchLogColors.textTertiary,
        letterSpacing: 0.5,
      );

  // Stat Numbers
  // 36px / w900 — large stat numbers on dashboard (ROI, match count, win rate)
  static TextStyle get statNumber => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: MatchLogColors.textPrimary,
      );

  // Odds Display
  // 16px / w600 — JetBrains Mono for odds values.
  // Monospaced so "2.10" and "1.85" align in bet lists.
  // Uses primary color for visual hierarchy.
  static TextStyle get oddsDisplay => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: MatchLogColors.primary,
      );

  // Smaller odds variant for compact bet cards
  static TextStyle get oddsDisplaySmall => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: MatchLogColors.primary,
      );
}
