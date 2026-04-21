// MatchLog spacing and layout constants.
// 4pt grid system — all spacing values are multiples of 4.
// Usage:
//   Padding(padding: MatchLogSpacing.screenPadding, child: ...)
//   BorderRadius.circular(MatchLogSpacing.radiusMd)

library;

import 'package:flutter/material.dart';

class MatchLogSpacing {
  MatchLogSpacing._();

  // Scalar spacing (4pt grid)
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;

  // Standard horizontal screen padding — used on all full-width screens
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);

  // Standard card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  // Compact card padding — used for dense list items
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);

  // Horizontal padding for list tiles
  static const EdgeInsets listTilePadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // Border radii
  // 8px — small chips, badges, tags
  static const double radiusSm = 8.0;

  // 12px — cards, input fields, buttons (default)
  static const double radiusMd = 12.0;

  // 16px — bottom sheets, large cards
  static const double radiusLg = 16.0;

  // 24px — modals, dialogs
  static const double radiusXl = 24.0;

  // 100px — pill shape (fully rounded buttons, avatar borders)
  static const double radiusFull = 100.0;

  // BorderRadius helpers
  static BorderRadius get roundedSm   => BorderRadius.circular(radiusSm);
  static BorderRadius get roundedMd   => BorderRadius.circular(radiusMd);
  static BorderRadius get roundedLg   => BorderRadius.circular(radiusLg);
  static BorderRadius get roundedXl   => BorderRadius.circular(radiusXl);
  static BorderRadius get roundedFull => BorderRadius.circular(radiusFull);

  // SizedBox helpers
  static const SizedBox gapXs   = SizedBox(height: xs);
  static const SizedBox gapSm   = SizedBox(height: sm);
  static const SizedBox gapMd   = SizedBox(height: md);
  static const SizedBox gapLg   = SizedBox(height: lg);
  static const SizedBox gapXl   = SizedBox(height: xl);
  static const SizedBox gapXxl  = SizedBox(height: xxl);

  static const SizedBox hGapXs  = SizedBox(width: xs);
  static const SizedBox hGapSm  = SizedBox(width: sm);
  static const SizedBox hGapMd  = SizedBox(width: md);
  static const SizedBox hGapLg  = SizedBox(width: lg);
  static const SizedBox hGapXl  = SizedBox(width: xl);
}
