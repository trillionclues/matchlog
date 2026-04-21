// MatchLog local SQLite database.
// All writes go here (offline-first), then sync to Firebase when connectivity is available.

// Tables:
//   1.  MatchEntries      — match diary entries
//   2.  BetEntries        — bet tracking records
//   3.  BookieGroups      — social prediction groups
//   4.  GroupMembers      — group membership + stats
//   5.  Predictions       — pre-match predictions
//   6.  Follows           — user follow relationships
//   7.  UserProfiles      — cached user profile data
//   8.  SyncQueue         — pending offline operations
//   9.  FixtureCache      — cached API fixture responses
//   10. ScannedBetSlips   — OCR-scanned bet slip data (Phase 2)
//   11. TruthScores       — computed tipster verification scores (Phase 3)

// After editing this file, run:
//   dart run build_runner build --delete-conflicting-outputs
library;

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'type_converters.dart';
import 'daos/match_dao.dart';
import 'daos/bet_dao.dart';
import 'daos/group_dao.dart';
import 'daos/prediction_dao.dart';

part 'app_database.g.dart';

// Every match the user watches is logged here.
@DataClassName('MatchEntry')
class MatchEntries extends Table {
  
  TextColumn get id => text()();

  TextColumn get userId => text()();

  // stored as int via intEnum
  IntColumn get sport => intEnum<Sport>()();

  // TheSportsDB or API-Football event ID
  TextColumn get fixtureId => text()();

  TextColumn get homeTeam => text()();

  // Nullable for individual sports (F1, MMA, Tennis)
  TextColumn get awayTeam => text().nullable()();

  // Score string: "2-1" (football), "110-98" (NBA), "P1: VER" (F1)
  TextColumn get score => text()();

  TextColumn get league => text()();

  IntColumn get watchType => intEnum<WatchType>()();

  // 1–5 star rating — enforced by CHECK constraint
  IntColumn get rating => integer()();

  TextColumn get review => text().nullable()();

  // JSON list of Firebase Storage URLs
  TextColumn get photos =>
      text().map(const JsonListConverter()).withDefault(const Constant('[]'))();

  TextColumn get venue => text().nullable()();

  // Sport-specific extra data (halfTimeScore, redCards, circuit, etc.)
  TextColumn get sportMetadata =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();

  // True when GPS-verified stadium check-in
  BoolColumn get geoVerified =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // False until successfully synced to Firebase
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Bet tracking entries
@DataClassName('BetEntry')
class BetEntries extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get sport => intEnum<Sport>()();
  TextColumn get fixtureId => text()();

  // Human-readable match description: "Arsenal vs Chelsea"
  TextColumn get matchDescription => text()();

  IntColumn get betType => intEnum<BetType>()();

  TextColumn get prediction => text()();

  RealColumn get odds => real()();

  // Stake amount in [currency]
  RealColumn get stake => real()();

  // ISO 4217 currency code — defaults to NGN for African market
  TextColumn get currency => text().withDefault(const Constant('NGN'))();

  TextColumn get bookmaker => text()();

  BoolColumn get settled => boolean().withDefault(const Constant(false))();

  // Null until settled
  BoolColumn get won => boolean().nullable()();

  // Actual payout received — null until settled
  RealColumn get payout => real().nullable()();

  DateTimeColumn get settledAt => dateTime().nullable()();

  IntColumn get visibility => intEnum<BetVisibility>()();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Bookie Groups — social prediction groups
@DataClassName('BookieGroup')
class BookieGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get adminId => text()();
  IntColumn get privacy => intEnum<GroupPrivacy>()();

  // Auto-generated 6-char alphanumeric invite code (e.g., "MNC25X")
  TextColumn get inviteCode => text().unique()();

  // Optional league filter: ["premier_league", "champions_league"]
  TextColumn get leagueFocus =>
      text().map(const JsonListConverter()).nullable()();

  // Optional sport filter — null means all sports
  IntColumn get sportFocus => intEnum<Sport>().nullable()();

  // Denormalized member count for efficient list queries
  IntColumn get memberCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Group membership records — composite PK.
@DataClassName('GroupMember')
class GroupMembers extends Table {
  TextColumn get groupId =>
      text().references(BookieGroups, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();
  IntColumn get role => intEnum<GroupRole>()();
  IntColumn get totalPredictions =>
      integer().withDefault(const Constant(0))();
  IntColumn get correctPredictions =>
      integer().withDefault(const Constant(0))();
  RealColumn get winRate => real().withDefault(const Constant(0.0))();
  DateTimeColumn get joinedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {groupId, userId};
}

// Pre-match predictions
@DataClassName('Prediction')
class Predictions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  // Null for standalone predictions (not in a group)
  TextColumn get groupId =>
      text().nullable().references(BookieGroups, #id, onDelete: KeyAction.setNull)();

  TextColumn get fixtureId => text()();
  TextColumn get matchDescription => text()();
  TextColumn get prediction => text()();
  IntColumn get confidence => intEnum<PredictionConfidence>()();

  BoolColumn get settled => boolean().withDefault(const Constant(false))();
  BoolColumn get correct => boolean().nullable()();
  IntColumn get points => integer().nullable()();

  // Hard deadline — predictions after kickoff are rejected
  DateTimeColumn get kickoffAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// User follow relationships — composite PK.
@DataClassName('Follow')
class Follows extends Table {
  TextColumn get followerId => text()();
  TextColumn get followingId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {followerId, followingId};
}

// Cached user profile data — PK is userId.
@DataClassName('UserProfile')
class UserProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get displayName => text()();
  TextColumn get email => text()();
  TextColumn get photoUrl => text().nullable()();
  
  // Always true for Google/Apple (set by Firebase automatically).
  // Email/Password users start false; updated after sendEmailVerification() completes.
  BoolColumn get emailVerified =>
      boolean().withDefault(const Constant(false))();
  IntColumn get tier => intEnum<UserTier>()();
  IntColumn get favoriteSport => intEnum<Sport>().nullable()();
  TextColumn get favoriteTeam => text().nullable()();
  IntColumn get followerCount => integer().withDefault(const Constant(0))();
  IntColumn get followingCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

// Offline sync queue — stores pending create/update/delete operations.
// Replayed in order when connectivity is restored.
@DataClassName('SyncOperation')
class SyncQueue extends Table {
  // Auto-increment — determines replay order
  IntColumn get id => integer().autoIncrement()();

  // "create", "update", or "delete"
  TextColumn get operation => text()();

  // Firestore collection name: "match_entries", "bet_entries", etc.
  TextColumn get collection => text()();

  // Document ID of the affected record
  TextColumn get documentId => text()();

  // Full JSON payload of the operation
  TextColumn get payload => text()();

  // Number of failed sync attempts (max 3 before marking failed)
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get failed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
}

// Fixture API response cache — TTL-based invalidation via expiresAt.
@DataClassName('CachedFixture')
class FixtureCache extends Table {
  // TheSportsDB or API-Football event ID
  TextColumn get fixtureId => text()();

  // Team ID used to fetch this fixture (for cache lookup by team)
  TextColumn get teamId => text().nullable()();

  // Full JSON response from the API
  TextColumn get data => text()();

  DateTimeColumn get cachedAt => dateTime()();

  // Cache expires after 6 hours for upcoming fixtures
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {fixtureId};
}

// OCR-scanned bet slip records
@DataClassName('ScannedBetSlip')
class ScannedBetSlips extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  // Firebase Storage URL of the uploaded slip image
  TextColumn get imageUrl => text().nullable()();

  // Local file path before upload completes
  TextColumn get localImagePath => text().nullable()();

  TextColumn get bookmaker => text()();
  TextColumn get slipCode => text().nullable()();

  // JSON list of ExtractedBet objects
  TextColumn get extractedBets =>
      text().map(const JsonListConverter()).withDefault(const Constant('[]'))();

  RealColumn get totalOdds => real().nullable()();
  RealColumn get stake => real()();
  RealColumn get potentialPayout => real()();
  TextColumn get currency => text().withDefault(const Constant('NGN'))();

  IntColumn get status => intEnum<VerificationStatus>()();

  DateTimeColumn get verifiedAt => dateTime().nullable()();
  BoolColumn get won => boolean().nullable()();
  RealColumn get actualPayout => real().nullable()();

  // BetEntry auto-created from this scan
  TextColumn get linkedBetEntryId => text().nullable()();

  // ML Kit OCR confidence score (0.0–1.0)
  RealColumn get ocrConfidence => real()();

  // Full raw OCR text for debugging and re-parsing
  TextColumn get rawOcrText => text()();

  // JSON list of FraudFlag enum values
  TextColumn get fraudFlags =>
      text().map(const JsonListConverter()).withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Computed Truth Score per user
// PK is userId — one row per user, updated when new slips are verified.
@DataClassName('TruthScore')
class TruthScores extends Table {
  TextColumn get userId => text()();
  IntColumn get totalScannedSlips =>
      integer().withDefault(const Constant(0))();
  IntColumn get verifiedSlips => integer().withDefault(const Constant(0))();
  IntColumn get rejectedSlips => integer().withDefault(const Constant(0))();
  IntColumn get flaggedSlips => integer().withDefault(const Constant(0))();
  IntColumn get verifiedWins => integer().withDefault(const Constant(0))();
  IntColumn get verifiedLosses => integer().withDefault(const Constant(0))();
  RealColumn get verifiedWinRate =>
      real().withDefault(const Constant(0.0))();
  RealColumn get verifiedRoi => real().withDefault(const Constant(0.0))();

  // Composite score 0–100
  IntColumn get truthScore => integer().withDefault(const Constant(0))();

  IntColumn get tier => intEnum<TruthTier>()();

  // JSON map: { scanConsistency, volumeScore, recencyScore, flagPenalty }
  TextColumn get breakdown =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();

  DateTimeColumn get lastUpdated => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    MatchEntries,
    BetEntries,
    BookieGroups,
    GroupMembers,
    Predictions,
    Follows,
    UserProfiles,
    SyncQueue,
    FixtureCache,
    ScannedBetSlips,
    TruthScores,
  ],
  daos: [
    MatchDao,
    BetDao,
    GroupDao,
    PredictionDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  // In-memory constructor for tests.
  AppDatabase.forTesting(super.executor) : super();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
      );
}

// Opens SQLite database file in the app's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'matchlog.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
