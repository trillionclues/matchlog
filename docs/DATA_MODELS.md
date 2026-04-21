# MatchLog — Data Models

> Complete data model definitions for Drift (local), Firestore (Phase 1-3), and Spring Boot JPA (Phase 4+). Sport-agnostic from day one.

---

## Core Enums

```dart
enum Sport { football, basketball, formula1, mma, cricket, tennis }

enum WatchType { stadium, tv, streaming, radio }

enum BetType { win, draw, btts, overUnder, correctScore, accumulator, moneyline, prop }

enum BetVisibility { public, friends, private_ }

enum UserTier { free, pro, crew }

enum GroupPrivacy { open, inviteOnly }

enum GroupRole { admin, member }

enum PredictionConfidence { high, medium, low }

enum ActivityType { matchLogged, betPlaced, predictionMade, betSettled, reviewPosted, groupJoined, slipVerified }

enum NotificationType { matchReminder, betSettlement, socialActivity, weeklyDigest, aiInsight, verificationResult }

enum VerificationStatus { pending, verified, rejected, flagged }

enum TruthTier { unverified, bronze, silver, gold, diamond }

enum FraudFlag { duplicateImage, metadataMismatch, lowOcrConfidence, unrealisticOdds, statisticalAnomaly }
```

---

## Drift Tables (Local SQLite)

```dart
// core/database/tables.dart

class MatchEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get sport => intEnum<Sport>()();
  TextColumn get fixtureId => text()();
  TextColumn get homeTeam => text()();
  TextColumn get awayTeam => text().nullable()();
  TextColumn get score => text()();
  TextColumn get league => text()();
  IntColumn get watchType => intEnum<WatchType>()();
  IntColumn get rating => integer().check(rating.isBetweenValues(1, 5))();
  TextColumn get review => text().nullable()();
  TextColumn get photos => text().map(const JsonListConverter()).withDefault(const Constant('[]'))();
  TextColumn get venue => text().nullable()();
  TextColumn get sportMetadata => text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  BoolColumn get geoVerified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class BetEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get sport => intEnum<Sport>()();
  TextColumn get fixtureId => text()();
  TextColumn get matchDescription => text()();  // "Arsenal vs Chelsea"
  IntColumn get betType => intEnum<BetType>()();
  TextColumn get prediction => text()();
  RealColumn get odds => real()();
  RealColumn get stake => real()();
  TextColumn get currency => text().withDefault(const Constant('NGN'))();
  TextColumn get bookmaker => text()();
  BoolColumn get settled => boolean().withDefault(const Constant(false))();
  BoolColumn get won => boolean().nullable()();
  RealColumn get payout => real().nullable()();
  DateTimeColumn get settledAt => dateTime().nullable()();
  IntColumn get visibility => intEnum<BetVisibility>()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class BookieGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get adminId => text()();
  IntColumn get privacy => intEnum<GroupPrivacy>()();
  TextColumn get inviteCode => text().unique()();
  TextColumn get leagueFocus => text().map(const JsonListConverter()).nullable()();
  IntColumn get sportFocus => intEnum<Sport>().nullable()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class GroupMembers extends Table {
  TextColumn get groupId => text().references(BookieGroups, #id)();
  TextColumn get userId => text()();
  IntColumn get role => intEnum<GroupRole>()();
  IntColumn get totalPredictions => integer().withDefault(const Constant(0))();
  IntColumn get correctPredictions => integer().withDefault(const Constant(0))();
  RealColumn get winRate => real().withDefault(const Constant(0.0))();
  DateTimeColumn get joinedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {groupId, userId};
}

class Predictions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get groupId => text().nullable().references(BookieGroups, #id)();
  TextColumn get fixtureId => text()();
  TextColumn get matchDescription => text()();
  TextColumn get prediction => text()();
  IntColumn get confidence => intEnum<PredictionConfidence>()();
  BoolColumn get settled => boolean().withDefault(const Constant(false))();
  BoolColumn get correct => boolean().nullable()();
  IntColumn get points => integer().nullable()();
  DateTimeColumn get kickoffAt => dateTime()();  // Hard deadline for submission
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Follows extends Table {
  TextColumn get followerId => text()();
  TextColumn get followingId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {followerId, followingId};
}

class UserProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get displayName => text()();
  TextColumn get email => text()();
  TextColumn get photoUrl => text().nullable()();
  /// True when the user has verified their email address.
  /// Always true for Google/Apple sign-in (set by Firebase automatically).
  /// Email/Password users start as false and verify via sendEmailVerification().
  BoolColumn get emailVerified => boolean().withDefault(const Constant(false))();
  IntColumn get tier => intEnum<UserTier>()();
  IntColumn get favoriteSport => intEnum<Sport>().nullable()();
  TextColumn get favoriteTeam => text().nullable()();
  IntColumn get followerCount => integer().withDefault(const Constant(0))();
  IntColumn get followingCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

// Offline sync queue
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()();  // create, update, delete
  TextColumn get collection => text()();  // match_entries, bet_entries, etc.
  TextColumn get documentId => text()();
  TextColumn get payload => text()();  // JSON
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get failed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

// Fixture cache (API responses cached locally)
class FixtureCache extends Table {
  TextColumn get fixtureId => text()();
  TextColumn get teamId => text().nullable()();
  TextColumn get data => text()();  // Full JSON response
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {fixtureId};
}

// Scanned bet slips (verification system)
class ScannedBetSlips extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get imageUrl => text().nullable()();  // Firebase Storage URL
  TextColumn get localImagePath => text().nullable()();  // Local path before upload
  TextColumn get bookmaker => text()();
  TextColumn get slipCode => text().nullable()();
  TextColumn get extractedBets => text().map(const JsonListConverter())();  // JSON array
  RealColumn get totalOdds => real().nullable()();
  RealColumn get stake => real()();
  RealColumn get potentialPayout => real()();
  TextColumn get currency => text().withDefault(const Constant('NGN'))();
  IntColumn get status => intEnum<VerificationStatus>()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  BoolColumn get won => boolean().nullable()();
  RealColumn get actualPayout => real().nullable()();
  TextColumn get linkedBetEntryId => text().nullable()();
  RealColumn get ocrConfidence => real()();
  TextColumn get rawOcrText => text()();
  TextColumn get fraudFlags => text().map(const JsonListConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Truth score cache (computed from verified slips)
class TruthScores extends Table {
  TextColumn get userId => text()();
  IntColumn get totalScannedSlips => integer().withDefault(const Constant(0))();
  IntColumn get verifiedSlips => integer().withDefault(const Constant(0))();
  IntColumn get rejectedSlips => integer().withDefault(const Constant(0))();
  IntColumn get flaggedSlips => integer().withDefault(const Constant(0))();
  IntColumn get verifiedWins => integer().withDefault(const Constant(0))();
  IntColumn get verifiedLosses => integer().withDefault(const Constant(0))();
  RealColumn get verifiedWinRate => real().withDefault(const Constant(0.0))();
  RealColumn get verifiedRoi => real().withDefault(const Constant(0.0))();
  IntColumn get truthScore => integer().withDefault(const Constant(0))();
  IntColumn get tier => intEnum<TruthTier>()();
  TextColumn get breakdown => text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();
  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
```

---

## Freezed Domain Entities

> **Note on AppUser entity:** The `AppUser` domain entity (defined in `features/auth/domain/entities/app_user.dart` when the auth feature is built) must include `emailVerified: bool`. This field is sourced from `FirebaseAuth.currentUser.emailVerified` and cached in the local `UserProfiles` table. It gates social features (feed posting, group joining, predictions, bet slip scanning) for Email/Password users. Google and Apple users always have `emailVerified = true`.

```dart
// features/auth/domain/entities/app_user.dart
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,           // Firebase UID
    required String email,
    required String displayName,
    String? photoUrl,
    required bool emailVerified,  // Always true for Google/Apple; requires verification for Email/Password
    required UserTier tier,
    required DateTime createdAt,
  }) = _AppUser;
}
```

```dart
// features/diary/domain/entities/match_entry.dart
@freezed
class MatchEntry with _$MatchEntry {
  const factory MatchEntry({
    required String id,
    required String userId,
    required Sport sport,
    required String fixtureId,
    required String homeTeam,
    String? awayTeam,
    required String score,
    required String league,
    required WatchType watchType,
    @IntInRange(1, 5) required int rating,
    String? review,
    @Default([]) List<String> photos,
    String? venue,
    @Default({}) Map<String, dynamic> sportMetadata,
    @Default(false) bool geoVerified,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MatchEntry;

  factory MatchEntry.fromJson(Map<String, dynamic> json) =>
      _$MatchEntryFromJson(json);
}

// features/betting/domain/entities/bet_entry.dart
@freezed
class BetEntry with _$BetEntry {
  const factory BetEntry({
    required String id,
    required String userId,
    required Sport sport,
    required String fixtureId,
    required String matchDescription,
    required BetType betType,
    required String prediction,
    required double odds,
    required double stake,
    @Default('NGN') String currency,
    required String bookmaker,
    @Default(false) bool settled,
    bool? won,
    double? payout,
    DateTime? settledAt,
    @Default(BetVisibility.private_) BetVisibility visibility,
    required DateTime createdAt,
  }) = _BetEntry;

  factory BetEntry.fromJson(Map<String, dynamic> json) =>
      _$BetEntryFromJson(json);
}

// Computed properties
extension BetEntryX on BetEntry {
  double get potentialPayout => stake * odds;
  double get profitLoss => settled
      ? (won == true ? payout! - stake : -stake)
      : 0;
  bool get isPending => !settled;
}

// features/groups/domain/entities/bookie_group.dart
@freezed
class BookieGroup with _$BookieGroup {
  const factory BookieGroup({
    required String id,
    required String name,
    required String adminId,
    required GroupPrivacy privacy,
    required String inviteCode,
    List<String>? leagueFocus,
    Sport? sportFocus,
    @Default(0) int memberCount,
    required DateTime createdAt,
  }) = _BookieGroup;

  factory BookieGroup.fromJson(Map<String, dynamic> json) =>
      _$BookieGroupFromJson(json);
}

// features/social/domain/entities/activity_item.dart
@freezed
class ActivityItem with _$ActivityItem {
  const factory ActivityItem({
    required String id,
    required String userId,
    required String displayName,
    String? userPhotoUrl,
    required ActivityType type,
    required String referenceId,
    required String summary,
    required DateTime createdAt,
  }) = _ActivityItem;

  factory ActivityItem.fromJson(Map<String, dynamic> json) =>
      _$ActivityItemFromJson(json);
}

// features/verification/domain/entities/scanned_bet_slip.dart
@freezed
class ScannedBetSlip with _$ScannedBetSlip {
  const factory ScannedBetSlip({
    required String id,
    required String userId,
    String? imageUrl,
    String? localImagePath,
    required String bookmaker,
    String? slipCode,
    required List<ExtractedBet> extractedBets,
    double? totalOdds,
    required double stake,
    required double potentialPayout,
    @Default('NGN') String currency,
    required VerificationStatus status,
    DateTime? verifiedAt,
    bool? won,
    double? actualPayout,
    String? linkedBetEntryId,
    required double ocrConfidence,
    required String rawOcrText,
    @Default([]) List<FraudFlag> fraudFlags,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ScannedBetSlip;

  factory ScannedBetSlip.fromJson(Map<String, dynamic> json) =>
      _$ScannedBetSlipFromJson(json);
}

@freezed
class ExtractedBet with _$ExtractedBet {
  const factory ExtractedBet({
    required String matchDescription,
    required String prediction,
    required double odds,
    String? fixtureId,  // Matched against API fixture
  }) = _ExtractedBet;

  factory ExtractedBet.fromJson(Map<String, dynamic> json) =>
      _$ExtractedBetFromJson(json);
}

// features/verification/domain/entities/truth_score.dart
@freezed
class TruthScore with _$TruthScore {
  const factory TruthScore({
    required String userId,
    required int totalScannedSlips,
    required int verifiedSlips,
    required int rejectedSlips,
    required int flaggedSlips,
    required int verifiedWins,
    required int verifiedLosses,
    required double verifiedWinRate,
    required double verifiedRoi,
    required int truthScore,      // 0-100
    required TruthTier tier,
    required TruthScoreBreakdown breakdown,
    required DateTime lastUpdated,
  }) = _TruthScore;

  factory TruthScore.fromJson(Map<String, dynamic> json) =>
      _$TruthScoreFromJson(json);
}

@freezed
class TruthScoreBreakdown with _$TruthScoreBreakdown {
  const factory TruthScoreBreakdown({
    required double scanConsistency,  // 40% weight
    required double volumeScore,      // 25% weight
    required double recencyScore,     // 20% weight
    required double flagPenalty,      // 15% weight (subtracted)
  }) = _TruthScoreBreakdown;

  factory TruthScoreBreakdown.fromJson(Map<String, dynamic> json) =>
      _$TruthScoreBreakdownFromJson(json);
}
```

---

## Computed Stats Models

```dart
// features/diary/domain/entities/user_stats.dart
@freezed
class UserStats with _$UserStats {
  const factory UserStats({
    // Match stats
    required int totalMatchesWatched,
    required int matchesThisMonth,
    required Map<String, int> matchesByLeague,     // { "Premier League": 12 }
    required Map<String, int> matchesByTeam,        // { "Arsenal": 8 }
    required Map<WatchType, int> matchesByWatchType, // { stadium: 3, tv: 15 }
    required double averageRating,
    required int stadiumVisits,
    required int currentStreak,                     // Consecutive days with a logged match
    required int longestStreak,

    // Betting stats
    required int totalBets,
    required int betsWon,
    required int betsLost,
    required int betsPending,
    required double winRate,
    required double totalStaked,
    required double totalPayout,
    required double roi,                            // (totalPayout - totalStaked) / totalStaked * 100
    required Map<String, double> roiByLeague,
    required Map<String, double> roiByBetType,
    required Map<String, double> roiByBookmaker,
    required String mostProfitableLeague,
    required String mostProfitableBetType,
    required String leastProfitableBookmaker,
  }) = _UserStats;
}

// features/groups/domain/entities/leaderboard_entry.dart
@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required int rank,
    required String userId,
    required String displayName,
    String? photoUrl,
    required int totalPredictions,
    required int correctPredictions,
    required double winRate,
    required int totalPoints,
    required int currentStreak,          // Consecutive correct predictions
  }) = _LeaderboardEntry;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      _$LeaderboardEntryFromJson(json);
}

// features/year_review/domain/entities/year_review.dart
@freezed
class YearReview with _$YearReview {
  const factory YearReview({
    required int year,
    required int totalMatches,
    required int totalBets,
    required double roi,
    required String topTeam,
    required String topLeague,
    required int stadiumVisits,
    required int countriesWatched,         // Unique league countries
    required int longestStreak,
    required String bestMonth,
    required double bestRoi,               // Best single-month ROI
    required String mostWatchedRival,      // Team you've watched the most against
    required int predictionsCorrect,
    required double predictionAccuracy,
    String? aiSummary,                     // Gemini-generated paragraph
    // Verification stats
    int? slipsScanned,
    int? slipsVerified,
    int? truthScore,
    TruthTier? truthTier,
  }) = _YearReview;
}
```

---

## Spring Boot JPA Entities (Phase 4)

```java
// entity/User.java
@Entity
@Table(name = "users")
public class User {
    @Id
    private String id;
    private String displayName;
    private String email;
    private String photoUrl;

    @Enumerated(EnumType.STRING)
    private UserTier tier;

    @Enumerated(EnumType.STRING)
    private Sport favoriteSport;

    private String favoriteTeam;
    private int followerCount;
    private int followingCount;
    private LocalDateTime createdAt;
}

// entity/MatchEntry.java
@Entity
@Table(name = "match_entries", indexes = {
    @Index(name = "idx_match_user_sport", columnList = "userId, sport"),
    @Index(name = "idx_match_created", columnList = "createdAt DESC")
})
public class MatchEntry {
    @Id
    private String id;
    private String userId;

    @Enumerated(EnumType.STRING)
    private Sport sport;

    private String fixtureId;
    private String homeTeam;
    private String awayTeam;
    private String score;
    private String league;

    @Enumerated(EnumType.STRING)
    private WatchType watchType;

    private int rating;

    @Column(columnDefinition = "TEXT")
    private String review;

    @Type(JsonType.class)
    @Column(columnDefinition = "jsonb")
    private List<String> photos;

    private String venue;

    @Type(JsonType.class)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> sportMetadata;

    private boolean geoVerified;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "userId", insertable = false, updatable = false)
    private User user;
}

// entity/BetEntry.java
@Entity
@Table(name = "bet_entries", indexes = {
    @Index(name = "idx_bet_user", columnList = "userId"),
    @Index(name = "idx_bet_fixture", columnList = "fixtureId"),
    @Index(name = "idx_bet_settled", columnList = "settled")
})
public class BetEntry {
    @Id
    private String id;
    private String userId;

    @Enumerated(EnumType.STRING)
    private Sport sport;

    private String fixtureId;
    private String matchDescription;

    @Enumerated(EnumType.STRING)
    private BetType betType;

    private String prediction;
    private BigDecimal odds;
    private BigDecimal stake;
    private String currency;
    private String bookmaker;
    private boolean settled;
    private Boolean won;
    private BigDecimal payout;
    private LocalDateTime settledAt;

    @Enumerated(EnumType.STRING)
    private BetVisibility visibility;

    private LocalDateTime createdAt;
}

// entity/BookieGroup.java
@Entity
@Table(name = "bookie_groups")
public class BookieGroup {
    @Id
    private String id;
    private String name;
    private String adminId;

    @Enumerated(EnumType.STRING)
    private GroupPrivacy privacy;

    @Column(unique = true)
    private String inviteCode;

    @Type(JsonType.class)
    @Column(columnDefinition = "jsonb")
    private List<String> leagueFocus;

    @Enumerated(EnumType.STRING)
    private Sport sportFocus;

    private int memberCount;
    private LocalDateTime createdAt;

    @OneToMany(mappedBy = "group", cascade = CascadeType.ALL)
    private List<GroupMember> members;

    @OneToMany(mappedBy = "group", cascade = CascadeType.ALL)
    private List<Prediction> predictions;
}
```

---

## Flyway Migrations (Phase 4)

```sql
-- V1__create_users.sql
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY,
    display_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    photo_url TEXT,
    tier VARCHAR(20) NOT NULL DEFAULT 'FREE',
    favorite_sport VARCHAR(20),
    favorite_team VARCHAR(255),
    follower_count INT NOT NULL DEFAULT 0,
    following_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- V2__create_match_entries.sql
CREATE TABLE match_entries (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    sport VARCHAR(20) NOT NULL,
    fixture_id VARCHAR(255) NOT NULL,
    home_team VARCHAR(255) NOT NULL,
    away_team VARCHAR(255),
    score VARCHAR(50) NOT NULL,
    league VARCHAR(255) NOT NULL,
    watch_type VARCHAR(20) NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    photos JSONB DEFAULT '[]',
    venue VARCHAR(255),
    sport_metadata JSONB DEFAULT '{}',
    geo_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX idx_match_user_sport ON match_entries(user_id, sport);
CREATE INDEX idx_match_created ON match_entries(created_at DESC);

-- V3__create_bet_entries.sql
CREATE TABLE bet_entries (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    sport VARCHAR(20) NOT NULL,
    fixture_id VARCHAR(255) NOT NULL,
    match_description VARCHAR(500) NOT NULL,
    bet_type VARCHAR(30) NOT NULL,
    prediction VARCHAR(500) NOT NULL,
    odds DECIMAL(10, 2) NOT NULL,
    stake DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
    bookmaker VARCHAR(100) NOT NULL,
    settled BOOLEAN NOT NULL DEFAULT false,
    won BOOLEAN,
    payout DECIMAL(10, 2),
    settled_at TIMESTAMP,
    visibility VARCHAR(20) NOT NULL DEFAULT 'PRIVATE',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bet_user ON bet_entries(user_id);
CREATE INDEX idx_bet_settled ON bet_entries(settled);

-- V4__create_bookie_groups.sql
CREATE TABLE bookie_groups (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    admin_id VARCHAR(255) NOT NULL REFERENCES users(id),
    privacy VARCHAR(20) NOT NULL DEFAULT 'INVITE_ONLY',
    invite_code VARCHAR(6) UNIQUE NOT NULL,
    league_focus JSONB,
    sport_focus VARCHAR(20),
    member_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE group_members (
    group_id VARCHAR(255) NOT NULL REFERENCES bookie_groups(id) ON DELETE CASCADE,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    role VARCHAR(10) NOT NULL DEFAULT 'MEMBER',
    total_predictions INT NOT NULL DEFAULT 0,
    correct_predictions INT NOT NULL DEFAULT 0,
    win_rate DECIMAL(5, 2) NOT NULL DEFAULT 0,
    joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (group_id, user_id)
);

-- V5__create_predictions.sql
CREATE TABLE predictions (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    group_id VARCHAR(255) REFERENCES bookie_groups(id) ON DELETE SET NULL,
    fixture_id VARCHAR(255) NOT NULL,
    match_description VARCHAR(500) NOT NULL,
    prediction VARCHAR(500) NOT NULL,
    confidence VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
    settled BOOLEAN NOT NULL DEFAULT false,
    correct BOOLEAN,
    points INT,
    kickoff_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pred_group ON predictions(group_id);
CREATE INDEX idx_pred_kickoff ON predictions(kickoff_at);

-- V6__create_follows.sql
CREATE TABLE follows (
    follower_id VARCHAR(255) NOT NULL REFERENCES users(id),
    following_id VARCHAR(255) NOT NULL REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

CREATE INDEX idx_follow_follower ON follows(follower_id);
CREATE INDEX idx_follow_following ON follows(following_id);

-- V7__create_bet_slip_scans.sql
CREATE TABLE bet_slip_scans (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(id),
    image_url TEXT,
    bookmaker VARCHAR(100) NOT NULL,
    slip_code VARCHAR(100),
    extracted_bets JSONB NOT NULL DEFAULT '[]',
    total_odds DECIMAL(10, 2),
    stake DECIMAL(10, 2) NOT NULL,
    potential_payout DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    verified_at TIMESTAMP,
    won BOOLEAN,
    actual_payout DECIMAL(10, 2),
    linked_bet_entry_id VARCHAR(255) REFERENCES bet_entries(id),
    ocr_confidence DECIMAL(3, 2) NOT NULL,
    raw_ocr_text TEXT NOT NULL,
    fraud_flags JSONB DEFAULT '[]',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX idx_scan_user ON bet_slip_scans(user_id);
CREATE INDEX idx_scan_status ON bet_slip_scans(status);
CREATE INDEX idx_scan_bookmaker ON bet_slip_scans(bookmaker);

-- V8__create_truth_scores.sql
CREATE TABLE truth_scores (
    user_id VARCHAR(255) PRIMARY KEY REFERENCES users(id),
    total_scanned_slips INT NOT NULL DEFAULT 0,
    verified_slips INT NOT NULL DEFAULT 0,
    rejected_slips INT NOT NULL DEFAULT 0,
    flagged_slips INT NOT NULL DEFAULT 0,
    verified_wins INT NOT NULL DEFAULT 0,
    verified_losses INT NOT NULL DEFAULT 0,
    verified_win_rate DECIMAL(5, 2) NOT NULL DEFAULT 0,
    verified_roi DECIMAL(10, 2) NOT NULL DEFAULT 0,
    truth_score INT NOT NULL DEFAULT 0,
    tier VARCHAR(20) NOT NULL DEFAULT 'UNVERIFIED',
    breakdown JSONB NOT NULL DEFAULT '{}',
    last_updated TIMESTAMP NOT NULL DEFAULT NOW()
);
```

---

## Bookmaker Registry

```dart
// shared/constants/bookmakers.dart
const kBookmakers = [
  // Nigeria
  Bookmaker('bet9ja', 'Bet9ja', '🇳🇬', affiliateUrl: 'https://...'),
  Bookmaker('sportybet', 'SportyBet', '🇳🇬', affiliateUrl: 'https://...'),
  Bookmaker('betking', 'BetKing', '🇳🇬', affiliateUrl: 'https://...'),
  Bookmaker('1xbet', '1xBet', '🌍', affiliateUrl: 'https://...'),
  Bookmaker('msport', 'MSport', '🇳🇬'),
  Bookmaker('nairabet', 'NairaBet', '🇳🇬'),

  // International
  Bookmaker('bet365', 'Bet365', '🌍'),
  Bookmaker('draftkings', 'DraftKings', '🇺🇸'),
  Bookmaker('fanduel', 'FanDuel', '🇺🇸'),
  Bookmaker('williamhill', 'William Hill', '🇬🇧'),
  Bookmaker('betway', 'Betway', '🌍'),
  Bookmaker('paddy_power', 'Paddy Power', '🇬🇧'),

  // Custom
  Bookmaker('other', 'Other', '🌍'),
];
```
