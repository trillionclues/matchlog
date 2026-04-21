// Runtime feature flags.
// Allows disabling in-progress or experimental features without shipping
// a new app release. All flags default to false, features are enabled as they are completed.

// These can be driven by Firebase Remote Config for server-side control. For now they are compile-time constants.

library;

class FeatureFlags {
  FeatureFlags._();

  // Stadium GPS check-in with geofencing verification.
  static const bool stadiumCheckIn = false;

  // AI-moderated push notification copy via Gemini Flash.
  static const bool aiNotifications = false;

  // GitHub-style calendar heatmap on the diary screen.
  static const bool calendarHeatmap = false;

  // Spotify Wrapped-style Year in Review with shareable cards.
  static const bool yearInReview = false;

  // Social profiles, follow system, and activity feed.
  static const bool socialLayer = false;

  // Bookie Groups with invite codes and prediction boards.
  static const bool bookieGroups = false;

  // Bet slip OCR scanning and tipster verification.
  static const bool betSlipScanning = false;

  // AI betting pattern analysis via Gemini Flash.
  static const bool aiBettingInsights = false;

  // Weekly prediction leagues within Bookie Groups.
  static const bool predictionLeagues = false;

  // Truth Score system for verified tipster rankings.
  static const bool truthScore = false;

  // In-app purchases (Pro / Crew tiers).
  static const bool inAppPurchases = false;

  // Betting affiliate referral links.
  static const bool affiliateLinks = false;
}
