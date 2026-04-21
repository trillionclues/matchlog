# MatchLog — Architecture

> Flutter Clean Architecture + Firebase (Phase 1-3) → Spring Boot (Phase 4). Sport-agnostic data model. Offline-first. FPL-inspired UI.

---

## Table of Contents

- [System Overview](#system-overview)
- [Flutter App Architecture](#flutter-app-architecture)
- [Firebase Architecture (Phase 1-3)](#firebase-architecture-phase-1-3)
- [Spring Boot Architecture (Phase 4+)](#spring-boot-architecture-phase-4)
- [Offline-First Strategy](#offline-first-strategy)
- [Push Notification Architecture](#push-notification-architecture)
- [Bet Slip Verification Architecture](#bet-slip-verification-architecture)
- [Multi-Sport Plugin Architecture](#multi-sport-plugin-architecture)
- [State Management](#state-management)

---

## System Overview

### Phase 1-3: Firebase

```
┌─────────────────────────────────────┐
│            FLUTTER APP              │
│  ┌───────────┐  ┌────────────────┐  │
│  │ Riverpod  │  │   Drift (SQL)  │  │
│  │ Providers │  │ Local Database │  │
│  └─────┬─────┘  └───────┬────────┘  │
│        │                │           │
│  ┌─────┴────────────────┴────────┐  │
│  │     Repository Layer          │  │
│  │  (abstract interface)         │  │
│  └─────┬────────────────┬────────┘  │
│        │                │           │
│  ┌─────┴─────┐   ┌──────┴───────┐  │
│  │ Firebase   │   │ Football API │  │
│  │ DataSource │   │ DataSource   │  │
│  └─────┬─────┘   └──────┬───────┘  │
└────────┼─────────────────┼──────────┘
         │                 │
    ┌────┴────┐      ┌────┴──────┐
    │Firebase │      │API-Football│
    │Platform │      │TheSportsDB│
    └─────────┘      └───────────┘
    Auth│Firestore│    REST API
    Storage│FCM
```

### Phase 4+: Spring Boot

```
┌─────────────────────────────────────┐
│            FLUTTER APP              │
│  ┌───────────┐  ┌────────────────┐  │
│  │ Riverpod  │  │   Drift (SQL)  │  │
│  │ Providers │  │ Local Database │  │
│  └─────┬─────┘  └───────┬────────┘  │
│        │                │           │
│  ┌─────┴────────────────┴────────┐  │
│  │     Repository Layer          │  │
│  │  (SAME abstract interface)    │  │
│  └─────┬────────────────┬────────┘  │
│        │                │           │
│  ┌─────┴──────┐  ┌──────┴───────┐  │
│  │ Spring API  │  │ Football API │  │
│  │ DataSource  │  │ DataSource   │  │
│  └─────┬──────┘  └──────┬───────┘  │
└────────┼─────────────────┼──────────┘
         │                 │
    ┌────┴──────────┐ ┌───┴──────┐
    │ SPRING BOOT   │ │API-Football│
    │ ┌───────────┐ │ └──────────┘
    │ │PostgreSQL │ │
    │ │Redis      │ │
    │ │FCM Admin  │ │
    │ └───────────┘ │
    └───────────────┘
```

**Key insight:** The Flutter app's repository layer doesn't change. `FirebaseDataSource` gets replaced by `SpringApiDataSource`. Presentation layer is completely untouched.

---

## Flutter App Architecture

### Clean Architecture (Feature-First)

```
lib/
├── core/                              # Shared infrastructure
│   ├── config/
│   │   ├── app_config.dart            # Environment config (dev/staging/prod)
│   │   ├── backend_config.dart        # BackendType enum (firebase|spring)
│   │   └── feature_flags.dart         # Remote feature flags
│   ├── network/
│   │   ├── api_client.dart            # Dio instance + interceptors
│   │   ├── api_interceptors.dart      # Auth token, logging, retry
│   │   ├── connectivity_service.dart  # Network state monitoring
│   │   └── sync_queue.dart            # Offline action queue
│   ├── database/
│   │   ├── app_database.dart          # Drift database definition
│   │   ├── app_database.g.dart        # Generated code
│   │   ├── daos/
│   │   │   ├── match_dao.dart         # Match entry queries
│   │   │   ├── bet_dao.dart           # Bet entry queries
│   │   │   ├── group_dao.dart         # Bookie group queries
│   │   │   └── prediction_dao.dart    # Prediction queries
│   │   └── type_converters.dart       # Sport enum, WatchType converters
│   ├── notifications/
│   │   ├── notification_service.dart   # FCM setup + foreground/background
│   │   ├── notification_handler.dart   # Route to correct screen on tap
│   │   ├── notification_queue.dart     # Offline batching logic
│   │   └── channels.dart              # Android notification channels
│   ├── di/
│   │   ├── providers.dart             # Core Riverpod providers
│   │   └── service_locator.dart       # Initialization sequence
│   ├── router/
│   │   ├── app_router.dart            # GoRouter configuration
│   │   ├── routes.dart                # Route constants
│   │   └── deep_link_handler.dart     # App Links / Universal Links
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData definition
│   │   ├── colors.dart                # Color palette (FPL-inspired)
│   │   ├── typography.dart            # Text styles
│   │   └── spacing.dart               # Consistent spacing tokens
│   └── utils/
│       ├── formatters.dart            # Currency, date, odds formatting
│       ├── validators.dart            # Form validation rules
│       └── extensions.dart            # Dart extensions
│
├── features/                          # Feature modules (Clean Architecture)
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository_impl.dart
│   │   │   ├── firebase_auth_source.dart    # Phase 1-3
│   │   │   └── spring_auth_source.dart      # Phase 4+
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── app_user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart     # Abstract interface
│   │   │   └── usecases/
│   │   │       ├── sign_in.dart
│   │   │       ├── sign_up.dart
│   │   │       └── sign_out.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   └── onboarding_screen.dart
│   │       ├── widgets/
│   │       │   ├── social_login_button.dart
│   │       │   └── auth_form.dart
│   │       └── providers/
│   │           └── auth_providers.dart
│   │
│   ├── diary/
│   │   ├── data/
│   │   │   ├── diary_repository_impl.dart
│   │   │   ├── diary_local_source.dart      # Drift DAO
│   │   │   ├── diary_firebase_source.dart   # Firestore
│   │   │   └── diary_spring_source.dart     # REST API (Phase 4)
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── match_entry.dart
│   │   │   │   └── watch_type.dart
│   │   │   ├── repositories/
│   │   │   │   └── diary_repository.dart
│   │   │   └── usecases/
│   │   │       ├── log_match.dart
│   │   │       ├── get_diary_entries.dart
│   │   │       ├── delete_entry.dart
│   │   │       └── calculate_stats.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── diary_screen.dart         # Main diary feed
│   │       │   ├── log_match_screen.dart     # Match logging form
│   │       │   ├── match_detail_screen.dart  # Entry detail view
│   │       │   └── stats_dashboard.dart      # Personal stats
│   │       ├── widgets/
│   │       │   ├── match_card.dart           # Diary entry card
│   │       │   ├── rating_stars.dart         # 1-5 star input
│   │       │   ├── watch_type_selector.dart  # Stadium/TV/Streaming
│   │       │   ├── roi_chart.dart            # CustomPainter chart
│   │       │   ├── calendar_heatmap.dart     # GitHub-style heatmap
│   │       │   └── stat_card.dart            # Individual stat tile
│   │       └── providers/
│   │           ├── diary_providers.dart
│   │           └── stats_providers.dart
│   │
│   ├── betting/
│   │   ├── data/
│   │   │   ├── betting_repository_impl.dart
│   │   │   ├── betting_local_source.dart
│   │   │   ├── betting_firebase_source.dart
│   │   │   └── betting_spring_source.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── bet_entry.dart
│   │   │   │   ├── bet_type.dart
│   │   │   │   ├── bet_result.dart
│   │   │   │   └── bookmaker.dart
│   │   │   ├── repositories/
│   │   │   │   └── betting_repository.dart
│   │   │   └── usecases/
│   │   │       ├── log_bet.dart
│   │   │       ├── settle_bet.dart
│   │   │       └── calculate_roi.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── betting_screen.dart
│   │       │   ├── log_bet_screen.dart
│   │       │   └── roi_dashboard.dart
│   │       ├── widgets/
│   │       │   ├── bet_card.dart
│   │       │   ├── odds_input.dart
│   │       │   ├── bookmaker_selector.dart
│   │       │   └── roi_breakdown.dart       # CustomPainter
│   │       └── providers/
│   │           └── betting_providers.dart
│   │
│   ├── match_search/
│   │   ├── data/
│   │   │   ├── fixture_repository_impl.dart
│   │   │   ├── football_api_source.dart     # API-Football / TheSportsDB
│   │   │   ├── basketball_api_source.dart   # Phase 4+
│   │   │   └── f1_api_source.dart           # Phase 5+
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── fixture.dart
│   │   │   │   ├── league.dart
│   │   │   │   ├── team.dart
│   │   │   │   └── sport.dart               # Sport enum
│   │   │   └── repositories/
│   │   │       └── fixture_repository.dart   # Abstract, sport-pluggable
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── search_screen.dart
│   │       └── widgets/
│   │           ├── fixture_card.dart
│   │           ├── league_filter.dart
│   │           └── search_bar.dart
│   │
│   ├── social/                              # Phase 2
│   │   ├── data/
│   │   │   ├── social_repository_impl.dart
│   │   │   ├── social_firebase_source.dart
│   │   │   └── social_spring_source.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── user_profile.dart
│   │   │   │   ├── follow_relationship.dart
│   │   │   │   └── activity_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── social_repository.dart
│   │   │   └── usecases/
│   │   │       ├── follow_user.dart
│   │   │       ├── unfollow_user.dart
│   │   │       └── get_feed.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── profile_screen.dart
│   │       │   ├── feed_screen.dart
│   │       │   ├── followers_screen.dart
│   │       │   └── user_search_screen.dart
│   │       └── widgets/
│   │           ├── activity_card.dart
│   │           ├── user_avatar.dart
│   │           └── follow_button.dart
│   │
│   ├── groups/                              # Phase 2
│   │   ├── data/
│   │   │   ├── group_repository_impl.dart
│   │   │   ├── group_firebase_source.dart
│   │   │   └── group_spring_source.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── bookie_group.dart
│   │   │   │   ├── group_member.dart
│   │   │   │   ├── group_prediction.dart
│   │   │   │   └── group_invite.dart
│   │   │   ├── repositories/
│   │   │   │   └── group_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_group.dart
│   │   │       ├── join_group.dart
│   │   │       ├── submit_prediction.dart
│   │   │       └── get_leaderboard.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── groups_list_screen.dart
│   │       │   ├── group_detail_screen.dart
│   │       │   ├── create_group_screen.dart
│   │       │   ├── prediction_board.dart
│   │       │   └── leaderboard_screen.dart
│   │       └── widgets/
│   │           ├── group_card.dart
│   │           ├── prediction_card.dart
│   │           ├── leaderboard_row.dart
│   │           └── invite_code_card.dart
│   │
│   ├── predictions/                         # Phase 2-3
│   │   ├── data/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── prediction.dart
│   │   │   │   └── prediction_league.dart
│   │   │   └── usecases/
│   │   │       ├── submit_prediction.dart
│   │   │       └── calculate_scores.dart
│   │   └── presentation/
│   │
│   ├── verification/                        # Phase 2-3 (Tipster Verification)
│   │   ├── data/
│   │   │   ├── verification_repository_impl.dart
│   │   │   ├── verification_firebase_source.dart
│   │   │   ├── verification_spring_source.dart
│   │   │   └── ocr_service.dart             # Google ML Kit text recognition
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── scanned_bet_slip.dart     # OCR-extracted bet slip data
│   │   │   │   ├── truth_score.dart          # Computed verification rating
│   │   │   │   └── verification_status.dart  # pending, verified, rejected, flagged
│   │   │   ├── repositories/
│   │   │   │   └── verification_repository.dart
│   │   │   └── usecases/
│   │   │       ├── scan_bet_slip.dart         # OCR pipeline: image → structured data
│   │   │       ├── verify_bet_slip.dart       # Cross-reference with fixture results
│   │   │       ├── calculate_truth_score.dart  # Aggregate verified data → score
│   │   │       └── flag_suspicious_slip.dart   # Fraud heuristics
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── scan_slip_screen.dart       # Camera capture + crop
│   │       │   ├── slip_review_screen.dart     # OCR results preview + edit
│   │       │   ├── truth_score_screen.dart     # User's verification profile
│   │       │   └── tipster_rankings_screen.dart # Public leaderboard by Truth Score
│   │       ├── widgets/
│   │       │   ├── slip_card.dart              # Scanned slip display
│   │       │   ├── truth_score_badge.dart      # Score indicator widget
│   │       │   ├── verification_status_chip.dart
│   │       │   └── ocr_overlay.dart            # Camera viewfinder overlay
│   │       └── providers/
│   │           ├── verification_providers.dart
│   │           └── truth_score_providers.dart
│   │
│   └── year_review/                         # Phase 1.5
│       ├── data/
│       │   └── review_generator.dart        # Aggregates user data
│       ├── domain/
│       │   └── entities/
│       │       └── year_review.dart
│       └── presentation/
│           ├── screens/
│           │   └── year_review_screen.dart   # Spotify Wrapped style
│           └── widgets/
│               ├── stat_card.dart
│               ├── review_slide.dart
│               └── share_card_generator.dart # RepaintBoundary → PNG
│
├── shared/                                  # Cross-feature shared items
│   ├── widgets/
│   │   ├── app_bar.dart
│   │   ├── bottom_nav.dart
│   │   ├── loading_shimmer.dart
│   │   ├── empty_state.dart
│   │   ├── error_state.dart
│   │   └── photo_grid.dart
│   ├── extensions/
│   │   ├── date_extensions.dart
│   │   ├── string_extensions.dart
│   │   └── num_extensions.dart
│   └── constants/
│       ├── bookmakers.dart                  # Known bookmaker list
│       ├── leagues.dart                     # Popular leagues
│       └── sports.dart                      # Sport configurations
│
├── app.dart                                 # MaterialApp with GoRouter
└── main.dart                                # Entry point + initialization
```

### Layer Rules (Strictly Enforced)

| Layer | Can Import | Cannot Import |
|-------|-----------|---------------|
| **Domain** | Nothing (pure Dart only) | Flutter, Firebase, Drift, any package |
| **Data** | Domain | Presentation |
| **Presentation** | Domain (via providers) | Data (directly) |
| **Core** | Packages only | Feature modules |

---

## Firebase Architecture (Phase 1-3)

### Firestore Collections Structure

```
users/{userId}
  ├── displayName: string
  ├── email: string
  ├── photoUrl: string?
  ├── tier: "free" | "pro" | "crew"
  ├── favoriteSport: "football" | ...
  ├── favoriteTeam: string?
  ├── createdAt: timestamp
  └── settings/
      └── {settingsDoc}
          ├── notifications: { matchReminders: bool, betSettlements: bool, socialActivity: bool }
          └── privacy: { showBettingStats: bool, profileVisibility: "public" | "friends" | "private" }

match_entries/{entryId}
  ├── userId: string
  ├── sport: "football" | "basketball" | ...
  ├── fixtureId: string
  ├── homeTeam: string
  ├── awayTeam: string?
  ├── score: string
  ├── league: string
  ├── watchType: "stadium" | "tv" | "streaming" | "radio"
  ├── rating: 1-5
  ├── review: string?
  ├── photos: string[]                  # Firebase Storage URLs
  ├── venue: string?
  ├── sportMetadata: map                # Sport-specific data
  ├── geoVerified: bool                 # Stadium check-in verified
  ├── createdAt: timestamp
  └── updatedAt: timestamp

bet_entries/{betId}
  ├── userId: string
  ├── sport: "football" | ...
  ├── fixtureId: string
  ├── betType: "win" | "draw" | "btts" | "over_under" | "correct_score" | "accumulator"
  ├── prediction: string
  ├── odds: number
  ├── stake: number
  ├── currency: "NGN" | "USD" | "GBP" | "EUR"
  ├── bookmaker: string
  ├── result: { won: bool, payout: number, settledAt: timestamp }?
  ├── visibility: "public" | "friends" | "private"
  ├── createdAt: timestamp
  └── updatedAt: timestamp

bookie_groups/{groupId}
  ├── name: string
  ├── adminId: string
  ├── privacy: "open" | "invite_only"
  ├── inviteCode: string               # Auto-generated 6-char alphanumeric
  ├── leagueFocus: string[]?
  ├── sportFocus: string?              # Sport-agnostic
  ├── memberCount: number              # Denormalized for queries
  ├── createdAt: timestamp
  ├── members/ (sub-collection)
  │   └── {userId}
  │       ├── role: "admin" | "member"
  │       ├── joinedAt: timestamp
  │       └── stats: { predictions: int, correct: int, winRate: double }
  └── predictions/ (sub-collection)
      └── {predictionId}
          ├── userId: string
          ├── fixtureId: string
          ├── prediction: string
          ├── confidence: "high" | "medium" | "low"
          ├── settled: bool
          ├── correct: bool?
          ├── points: int?
          └── createdAt: timestamp

follows/{followId}
  ├── followerId: string
  ├── followingId: string
  └── createdAt: timestamp

bet_slip_scans/{scanId}
  ├── userId: string
  ├── imageUrl: string                   # Firebase Storage URL of original photo
  ├── bookmaker: string                  # Detected or user-corrected bookmaker
  ├── slipCode: string?                  # Bet slip code/ticket ID (if detected)
  ├── extractedBets: [                   # Array of bets parsed from the slip
  │     {
  │       matchDescription: string,      # "Arsenal vs Chelsea"
  │       prediction: string,            # "Home Win"
  │       odds: number,
  │       fixtureId: string?             # Matched to API fixture (if found)
  │     }
  │   ]
  ├── totalOdds: number?                 # Accumulator total odds
  ├── stake: number
  ├── potentialPayout: number
  ├── currency: string
  ├── status: "pending" | "verified" | "rejected" | "flagged"
  ├── verifiedAt: timestamp?             # When the results were cross-referenced
  ├── won: bool?                         # Overall slip result
  ├── actualPayout: number?              # Actual payout (verified against results)
  ├── linkedBetEntryId: string?          # Auto-created BetEntry from this scan
  ├── ocrConfidence: number              # 0-1 confidence score from ML Kit
  ├── rawOcrText: string                 # Full OCR output for debugging
  ├── fraudFlags: string[]               # ["duplicate_image", "metadata_mismatch", etc.]
  ├── createdAt: timestamp
  └── updatedAt: timestamp

truth_scores/{userId}
  ├── userId: string
  ├── totalScannedSlips: int
  ├── verifiedSlips: int
  ├── rejectedSlips: int
  ├── flaggedSlips: int
  ├── verifiedWins: int
  ├── verifiedLosses: int
  ├── verifiedWinRate: double            # Based ONLY on verified data
  ├── verifiedRoi: double                # ROI from verified slips only
  ├── truthScore: int                    # 0-100 composite score
  ├── tier: "unverified" | "bronze" | "silver" | "gold" | "diamond"
  ├── lastUpdated: timestamp
  └── breakdown: {
        scanConsistency: double,          # How often scans match claimed results
        volumeScore: double,              # More verified data = higher score
        recencyScore: double,             # Recent verification activity
        flagPenalty: double               # Deduction for flagged/rejected slips
      }

activity_feed/{activityId}
  ├── userId: string                   # Who performed the action
  ├── type: "match_logged" | "bet_placed" | "prediction_made" | "bet_settled" | "review_posted" | "slip_verified"
  ├── referenceId: string              # ID of the match/bet/prediction/scan
  ├── summary: string                  # "Excel logged Arsenal vs Chelsea ⭐⭐⭐⭐"
  ├── createdAt: timestamp
  └── targetUserIds: string[]          # Followers who should see this (fan-out-on-write)
```

### Firestore Security Rules (Outline)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Match entries: owner can CRUD, friends can read if public
    match /match_entries/{entryId} {
      allow create: if request.auth.uid == request.resource.data.userId;
      allow read: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }

    // Bet entries: owner can CRUD, visibility-based read
    match /bet_entries/{betId} {
      allow create: if request.auth.uid == request.resource.data.userId;
      allow read: if request.auth != null
        && (resource.data.visibility == 'public'
            || resource.data.userId == request.auth.uid);
      allow update, delete: if request.auth.uid == resource.data.userId;
    }

    // Groups: members can read, admin can write
    match /bookie_groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.adminId;

      match /members/{memberId} {
        allow read: if request.auth != null;
        allow write: if request.auth.uid == memberId
                     || request.auth.uid == get(/databases/$(database)/documents/bookie_groups/$(groupId)).data.adminId;
      }

      match /predictions/{predId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
        allow update: if request.auth.uid == resource.data.userId;
      }
    }
  }
}
```

### Firebase Storage Structure

```
matchlog-storage/
├── users/{userId}/
│   ├── profile/
│   │   └── avatar.jpg
│   ├── match_photos/
│   │   └── {entryId}/
│   │       ├── photo_1.jpg
│   │       ├── photo_2.jpg
│   │       └── photo_3.jpg
│   └── bet_slips/                     # Scanned bet slip images
│       └── {scanId}/
│           ├── original.jpg            # Raw camera capture
│           └── cropped.jpg             # Auto-cropped bet slip region
└── groups/{groupId}/
    └── cover.jpg
```

---

## Spring Boot Architecture (Phase 4+)

See [DATA_MODELS.md](./DATA_MODELS.md) for JPA entity definitions.

### API Structure

```
matchlog-api/
├── src/main/java/com/matchlog/api/
│   ├── MatchlogApiApplication.java
│   ├── config/
│   │   ├── SecurityConfig.java           # Spring Security filter chain
│   │   ├── RedisConfig.java              # Cache + session store
│   │   ├── CorsConfig.java               # Mobile app CORS
│   │   ├── SchedulingConfig.java         # @EnableScheduling
│   │   └── WebSocketConfig.java          # Real-time feed updates
│   ├── controller/
│   │   ├── AuthController.java           # Login, register, refresh
│   │   ├── DiaryController.java          # Match CRUD
│   │   ├── BettingController.java        # Bet CRUD + settlement
│   │   ├── StatsController.java          # ROI analytics
│   │   ├── SocialController.java         # Follow, feed, profiles
│   │   ├── GroupController.java          # Bookie Groups
│   │   ├── PredictionController.java     # Predictions + leagues
│   │   ├── VerificationController.java   # Bet slip scan + Truth Score
│   │   └── NotificationController.java   # Preferences
│   ├── dto/                              # Request/Response objects
│   ├── entity/                           # JPA entities
│   ├── repository/                       # Spring Data JPA
│   ├── service/                          # Business logic
│   │   ├── MatchResultUpdater.java       # @Scheduled background worker
│   │   ├── BetSlipVerifier.java          # @Scheduled: verify pending scans against results
│   │   ├── TruthScoreCalculator.java     # Recompute Truth Scores on new verified data
│   │   ├── NotificationDispatcher.java   # FCM push via Admin SDK
│   │   └── AiInsightService.java         # Gemini Flash
│   ├── exception/                        # Global error handling
│   └── security/                         # JWT auth
├── src/main/resources/
│   ├── application.yml
│   ├── application-dev.yml
│   └── db/migration/                     # Flyway migrations
├── docker-compose.yml
└── pom.xml
```

---

## Offline-First Strategy

### Write Path (Logging a Match/Bet)

```
User taps "Log Match"
    │
    ▼
┌─────────────────┐
│ Write to Drift   │  ← Always succeeds (local SQLite)
│ (local database) │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Online? │
    └────┬────┘
     Yes │  No
    ┌────┴──┐  ┌────────────┐
    │ Sync  │  │ Queue in    │
    │ to    │  │ SyncQueue   │
    │ remote│  │ (pending)   │
    └───────┘  └──────┬──────┘
                      │
              When connectivity returns:
                      │
               ┌──────┴──────┐
               │ Replay      │
               │ queued ops  │
               │ in order    │
               └─────────────┘
```

### Read Path (Viewing Diary)

```
User opens Diary screen
    │
    ▼
┌──────────────────────┐
│ Read from Drift       │  ← Always fast (local)
│ (local database)      │
└───────────┬──────────┘
            │
       ┌────┴────┐
       │ Online? │
       └────┬────┘
        Yes │  No
    ┌───────┴───────┐
    │ Fetch remote,  │     Show local data only
    │ merge & update │     (no loading state)
    │ local cache    │
    └────────────────┘
```

### SyncQueue Implementation

```dart
class SyncQueue {
  final Drift _db;
  final ConnectivityService _connectivity;

  // Each pending operation
  // id, type (create|update|delete), collection, documentId, payload, retryCount, createdAt

  Future<void> enqueue(SyncOperation op) async {
    await _db.syncQueueDao.insert(op);
    if (await _connectivity.isOnline) {
      await _processQueue();
    }
  }

  Future<void> _processQueue() async {
    final pending = await _db.syncQueueDao.getPending();
    for (final op in pending) {
      try {
        await _executeRemote(op);
        await _db.syncQueueDao.markCompleted(op.id);
      } catch (e) {
        if (op.retryCount >= 3) {
          await _db.syncQueueDao.markFailed(op.id);
        } else {
          await _db.syncQueueDao.incrementRetry(op.id);
        }
      }
    }
  }
}
```

---

## Push Notification Architecture

### Notification Flow

```
Trigger (match starts, bet settles, friend posts)
    │
    ▼
┌───────────────────────────┐
│ Cloud Function / Scheduler │
│ (or Spring Boot @Scheduled)│
└────────────┬──────────────┘
             │
    ┌────────┴─────────┐
    │ AI-Moderated?     │
    └────┬─────────┬───┘
     Yes │         │ No
    ┌────┴──────┐  │
    │ Gemini    │  │
    │ Flash     │  │
    │ Generate  │  │
    │ personalized│ │
    │ copy      │  │
    └────┬──────┘  │
         │         │
    ┌────┴─────────┴───┐
    │ FCM Dispatch      │
    │ (topic or token)  │
    └────────┬─────────┘
             │
    ┌────────┴────────┐
    │ Device Online?   │
    └────┬────────┬───┘
     Yes │        │ No
         │   ┌────┴────────┐
         │   │ FCM queues   │
         │   │ (Google infra)│
         │   └──────────────┘
    ┌────┴──────────────┐
    │ flutter_local_     │
    │ notifications      │
    │ renders locally    │
    └───────────────────┘
```

### Notification Channels (Android)

| Channel ID | Name | Importance | Vibrate | Sound |
|-----------|------|-----------|---------|-------|
| `match_reminders` | Match Reminders | High | Yes | Default |
| `bet_settlements` | Bet Results | High | Yes | Custom |
| `social_activity` | Friend Activity | Default | No | None |
| `weekly_digest` | Weekly Digest | Low | No | None |
| `ai_insights` | AI Insights | Default | No | Default |

---

## Bet Slip Verification Architecture

### Why This Matters

"Tipsters" on Twitter and WhatsApp post screenshots of won betting tickets. These are trivially photoshopped. There is **no way to verify a tipster's actual ROI**. MatchLog solves this with **Proof of Stake** — OCR-scanned bet slips cross-referenced against real match results.

### OCR Pipeline

```
User taps "Scan Bet Slip"
    │
    ▼
┌─────────────────────┐
│ Camera Capture       │  ← image_picker + camera2
│ + Auto-Crop          │  ← Edge detection via ML Kit
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    │ Google ML    │
    │ Kit Text     │  ← On-device OCR (offline-capable)
    │ Recognition  │
    └──────┬──────┘
           │
    ┌──────┴──────────────────┐
    │ BetSlipParser            │  ← Bookmaker-specific parsers
    │ ┌──────────────────────┐ │
    │ │ Bet9jaParser         │ │
    │ │ SportyBetParser      │ │
    │ │ BetKingParser        │ │
    │ │ GenericParser        │ │  ← Fallback for unknown formats
    │ └──────────────────────┘ │
    └──────────┬──────────────┘
               │
    ┌──────────┴──────────┐
    │ User Review Screen    │  ← User corrects any OCR errors
    │ (editable fields)     │
    └──────────┬──────────┘
               │
    ┌──────────┴──────────┐
    │ Save to Drift (local) │  ← Immediate persistence
    │ + Queue Sync          │
    └──────────┬──────────┘
               │
    ┌──────────┴──────────────────┐
    │ Fixture Matcher               │  ← Match "Arsenal vs Chelsea" → fixtureId
    │ (TheSportsDB fuzzy search)    │
    └──────────┬──────────────────┘
               │
    ┌──────────┴──────────┐
    │ Upload image to       │
    │ Firebase Storage      │
    └──────────┬──────────┘
               │
    ┌──────────┴──────────┐
    │ Create BetEntry from  │  ← Auto-log bet from scanned data
    │ scanned data          │
    └───────────────────────┘
```

### Bookmaker-Specific Parsers

```dart
// features/verification/data/parsers/

abstract class BetSlipParser {
  /// Bookmaker identifier
  String get bookmakerKey;

  /// Detect if this parser can handle the given OCR text
  bool canParse(String rawText);

  /// Parse structured data from raw OCR text
  ParsedBetSlip parse(String rawText);
}

class Bet9jaParser extends BetSlipParser {
  @override String get bookmakerKey => 'bet9ja';

  @override
  bool canParse(String rawText) {
    // Detect Bet9ja-specific patterns: "Bet9ja", booking codes, etc.
    return rawText.toLowerCase().contains('bet9ja') ||
           RegExp(r'B9J-[A-Z0-9]+').hasMatch(rawText);
  }

  @override
  ParsedBetSlip parse(String rawText) {
    // Extract:
    // - Booking code (B9J-XXXXX)
    // - Individual selections (match + market + odds)
    // - Total odds
    // - Stake / potential payout
    final bookingCode = _extractBookingCode(rawText);
    final selections = _extractSelections(rawText);
    final totalOdds = _extractTotalOdds(rawText);
    final stake = _extractStake(rawText);

    return ParsedBetSlip(
      bookmaker: 'bet9ja',
      slipCode: bookingCode,
      bets: selections,
      totalOdds: totalOdds,
      stake: stake,
      potentialPayout: stake * totalOdds,
    );
  }
}

// Registry
class BetSlipParserRegistry {
  final List<BetSlipParser> _parsers = [
    Bet9jaParser(),
    SportyBetParser(),
    BetKingParser(),
    OneXBetParser(),
    GenericBetSlipParser(), // Fallback
  ];

  BetSlipParser getParser(String rawText) {
    return _parsers.firstWhere(
      (p) => p.canParse(rawText),
      orElse: () => GenericBetSlipParser(),
    );
  }
}
```

### Truth Score Computation

```dart
class CalculateTruthScore {
  /// Compute a 0-100 composite score from verified bet data
  TruthScore calculate(TruthScoreInput input) {
    // 1. Scan Consistency (40% weight)
    // How often do scan results match the actual outcomes?
    final scanConsistency = input.verifiedSlips > 0
        ? (input.consistentSlips / input.verifiedSlips) * 100
        : 0.0;

    // 2. Volume Score (25% weight)
    // More verified data = more trustworthy
    // Logarithmic scale: diminishing returns past 50 slips
    final volumeScore = min(100, (log(input.verifiedSlips + 1) / log(51)) * 100);

    // 3. Recency Score (20% weight)
    // Recent verification activity matters more
    final daysSinceLastScan = DateTime.now().difference(input.lastScanDate).inDays;
    final recencyScore = max(0, 100 - (daysSinceLastScan * 2)); // Decays over ~50 days

    // 4. Flag Penalty (15% weight, subtracted)
    // Flagged or rejected slips reduce trust
    final flagPenalty = input.totalScannedSlips > 0
        ? ((input.flaggedSlips + input.rejectedSlips) / input.totalScannedSlips) * 100
        : 0.0;

    // Composite score
    final rawScore = (scanConsistency * 0.40)
                   + (volumeScore * 0.25)
                   + (recencyScore * 0.20)
                   - (flagPenalty * 0.15);

    final truthScore = rawScore.clamp(0, 100).round();

    // Tier assignment
    final tier = switch (truthScore) {
      >= 90 => TruthTier.diamond,
      >= 75 => TruthTier.gold,
      >= 55 => TruthTier.silver,
      >= 30 => TruthTier.bronze,
      _     => TruthTier.unverified,
    };

    return TruthScore(
      score: truthScore,
      tier: tier,
      breakdown: TruthScoreBreakdown(
        scanConsistency: scanConsistency,
        volumeScore: volumeScore,
        recencyScore: recencyScore,
        flagPenalty: flagPenalty,
      ),
    );
  }
}
```

### Fraud Detection Heuristics

```dart
class FraudDetectionService {
  /// Run all heuristic checks on a scanned slip
  List<FraudFlag> analyze(ScannedBetSlip slip, File imageFile) {
    final flags = <FraudFlag>[];

    // 1. Duplicate Image Detection
    //    Hash the image and compare against previous submissions
    final imageHash = _perceptualHash(imageFile);
    if (_isDuplicateHash(imageHash, slip.userId)) {
      flags.add(FraudFlag.duplicateImage);
    }

    // 2. EXIF Metadata Mismatch
    //    Check if photo timestamp is consistent with match dates
    final exifDate = _extractExifDate(imageFile);
    if (exifDate != null && exifDate.isBefore(slip.earliestKickoff)) {
      flags.add(FraudFlag.metadataMismatch);
    }

    // 3. OCR Confidence Threshold
    //    If ML Kit confidence is too low, text may be manipulated
    if (slip.ocrConfidence < 0.6) {
      flags.add(FraudFlag.lowOcrConfidence);
    }

    // 4. Odds Anomaly
    //    Compare scanned odds against market odds (if available from Odds API)
    for (final bet in slip.extractedBets) {
      if (bet.odds > 50.0) {
        flags.add(FraudFlag.unrealisticOdds);
      }
    }

    // 5. Win Rate Anomaly
    //    Statistical impossibility check
    //    e.g., 50+ consecutive wins on high-odds bets
    if (_checkStatisticalAnomaly(slip.userId)) {
      flags.add(FraudFlag.statisticalAnomaly);
    }

    return flags;
  }
}
```

---

## Multi-Sport Plugin Architecture

```dart
// Each sport registers itself
abstract class SportPlugin {
  Sport get sport;
  String get displayName;
  IconData get icon;
  Color get primaryColor;

  // Data source for fixtures
  FixtureDataSource get fixtureSource;

  // Available bet types for this sport
  List<BetTypeDefinition> get betTypes;

  // Sport-specific form fields for match logging
  List<SportMetadataField> get metadataFields;

  // How to display a score
  String formatScore(String rawScore);
}

class FootballPlugin extends SportPlugin {
  @override Sport get sport => Sport.football;
  @override String get displayName => 'Football';
  @override List<BetTypeDefinition> get betTypes => [
    BetTypeDefinition('win', 'Match Winner', ['Home', 'Draw', 'Away']),
    BetTypeDefinition('btts', 'Both Teams to Score', ['Yes', 'No']),
    BetTypeDefinition('over_under', 'Over/Under Goals', ['O0.5', 'O1.5', 'O2.5', 'O3.5']),
    BetTypeDefinition('correct_score', 'Correct Score', []),
  ];
  @override List<SportMetadataField> get metadataFields => [
    SportMetadataField('halfTimeScore', 'Half-time Score', FieldType.text),
    SportMetadataField('redCards', 'Red Cards', FieldType.number),
  ];
}
```

---

## State Management

### Riverpod Provider Hierarchy

```
// Core providers (app-wide)
connectivityProvider      → Stream<bool>
currentUserProvider       → AsyncValue<AppUser?>
backendConfigProvider     → BackendType (firebase|spring)
syncQueueProvider         → SyncQueue

// Feature providers (scoped to feature)
diaryEntriesProvider      → AsyncValue<List<MatchEntry>>
betEntriesProvider        → AsyncValue<List<BetEntry>>
statsProvider             → AsyncValue<UserStats>
feedProvider              → AsyncValue<List<ActivityItem>>
groupsProvider            → AsyncValue<List<BookieGroup>>
leaderboardProvider(id)   → AsyncValue<List<LeaderboardEntry>>
fixtureSearchProvider(q)  → AsyncValue<List<Fixture>>
```

### Provider Types Used

| Type | When | Example |
|------|------|---------|
| `Provider` | Static dependencies | HTTP client, database instance |
| `StateNotifierProvider` | Complex mutable state | Form state, filters |
| `FutureProvider` | One-shot async data | User profile fetch |
| `StreamProvider` | Real-time data | Firestore listeners, connectivity |
| `Provider.family` | Parameterized queries | `leaderboardProvider(groupId)` |
| `AsyncNotifierProvider` | Async state with mutations | CRUD operations with loading/error states |
