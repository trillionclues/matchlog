/// Two typefaces:
/// - Bricolage Grotesque (google fonts) — headlines, titles, display text
/// - Inter (google fonts) — body text, labels, UI elements
///
/// Monospace:
/// - JetBrains Mono (google fonts) — odds display only

// Usage:
//   Text('Arsenal', style: Theme.of(context).textTheme.headlineMedium)
//   Text('2.10', style: MatchLogTypography.oddsDisplay)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MatchLogTypography {
  MatchLogTypography._();

  // 32px / w800 — screen titles, Year in Review headlines & hero numbers
  static TextStyle get headlineXL => GoogleFonts.bricolageGrotesque(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
      );

  // 24px / w700 — section headers, match score display
  static TextStyle get headlineLarge => GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      );

  // 20px / w700 — card titles, screen sub-headers
  static TextStyle get headlineMedium => GoogleFonts.bricolageGrotesque(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  // 16px / w600 — list item titles, form section labels
  static TextStyle get headlineSmall => GoogleFonts.bricolageGrotesque(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  // Body
  // 16px / w400 — primary body text, match reviews
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // 14px / w400 — secondary body text, card descriptions
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // 12px / w400 — captions, timestamps, helper text
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  // Labels
  // 14px / w600 — button text, tab labels, chip text
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // 11px / w500 — micro labels, badge text, metadata
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  // 36px / w900 — large stat numbers on dashboard (ROI, match count, win rate)
  static TextStyle get statNumber => GoogleFonts.bricolageGrotesque(
        fontSize: 36,
        fontWeight: FontWeight.w900,
      );

  // 16px / w600 — JetBrains Mono for odds values.
  // Monospaced so "2.10" and "1.85" align in bet lists.
  static TextStyle get oddsDisplay => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  // Smaller odds variant for compact bet cards
  static TextStyle get oddsDisplaySmall => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );
}
