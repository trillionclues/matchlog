# MatchLog — API Integrations

> External data sources for fixtures, results, odds, and AI insights. Rate limits, caching strategies, and failover plans.

---

## API Overview

| API | Purpose | Free Tier | Phase |
|-----|---------|-----------|-------|
| **TheSportsDB** | Fixtures, results, team data, league info | 30 req/min, unlimited | Phase 1 (Primary) |
| **API-Football** | Fixtures, live scores, standings (800+ leagues) | 100 req/day | Phase 1 (Secondary/Premium) |
| **Firebase Auth** | Authentication (Google, Email) | 50K MAU | Phase 1 |
| **Firebase Cloud Firestore** | Database | 50K reads/day free | Phase 1 |
| **Firebase Cloud Messaging** | Push notifications | Unlimited | Phase 1.5 |
| **Firebase Storage** | Image uploads | 5GB free | Phase 1 |
| **Google ML Kit** | On-device OCR for bet slip scanning | Free (on-device) | Phase 2 |
| **Gemini 2.5 Flash** | AI betting insights, notification copy, OCR assist | Free tier generous | Phase 3 |
| **The Odds API** | Pre-match odds, 20+ bookmakers | 500 req/month | Phase 3+ (optional) |
| **API-Basketball** | NBA/EuroLeague fixtures | 100 req/day | Phase 4+ |
| **Ergast / OpenF1** | F1 race data | Free, unlimited | Phase 4+ |

---

## TheSportsDB (Primary Fixture Source)

### Why Primary

- **Free**: No API key required for basic endpoints. Key required for premium features ($5/mo Patreon).
- **Rate Limit**: 30 requests/minute (free) — far more generous than API-Football.
- **Coverage**: Football, basketball, motorsport, fighting, cricket, tennis — multi-sport ready.
- **Data**: Fixtures, results, team info, league info, event thumbnails.

### Key Endpoints

```
Base URL: https://www.thesportsdb.com/api/v1/json/{api_key}

# Search for teams
GET /searchteams.php?t=Arsenal

# List all leagues
GET /all_leagues.php

# Events in a specific round
GET /eventsround.php?id={leagueId}&r={round}&s={season}

# Next 15 events by team
GET /eventsnext.php?id={teamId}

# Last 5 events by team
GET /eventslast.php?id={teamId}

# Events on a specific day
GET /eventsday.php?d=2025-04-15

# Event details by ID
GET /lookupevent.php?id={eventId}

# League standings
GET /lookuptable.php?l={leagueId}&s={season}
```

### Dart Implementation

```dart
class TheSportsDbSource implements FixtureDataSource {
  final Dio _dio;
  final String _apiKey; // "1" for free tier, or Patreon key

  TheSportsDbSource(this._dio, this._apiKey);

  static const _baseUrl = 'https://www.thesportsdb.com/api/v1/json';

  @override
  Future<List<Fixture>> getUpcoming({required String teamId}) async {
    final response = await _dio.get(
      '$_baseUrl/$_apiKey/eventsnext.php',
      queryParameters: {'id': teamId},
    );

    final events = response.data['events'] as List?;
    if (events == null) return [];

    return events.map((e) => Fixture(
      id: e['idEvent'],
      homeTeam: e['strHomeTeam'],
      awayTeam: e['strAwayTeam'],
      league: e['strLeague'],
      date: DateTime.parse(e['dateEvent']),
      time: e['strTime'],
      venue: e['strVenue'],
      homeTeamBadge: e['strHomeTeamBadge'],
      awayTeamBadge: e['strAwayTeamBadge'],
      sport: Sport.football,
    )).toList();
  }

  @override
  Future<List<Fixture>> searchFixtures({required String query}) async {
    // Search events by name
    final response = await _dio.get(
      '$_baseUrl/$_apiKey/searchevents.php',
      queryParameters: {'e': query},
    );

    final events = response.data['event'] as List?;
    if (events == null) return [];

    return events.map((e) => _mapToFixture(e)).toList();
  }

  @override
  Future<MatchResult?> getResult({required String fixtureId}) async {
    final response = await _dio.get(
      '$_baseUrl/$_apiKey/lookupevent.php',
      queryParameters: {'id': fixtureId},
    );

    final events = response.data['events'] as List?;
    if (events == null || events.isEmpty) return null;

    final event = events.first;
    if (event['intHomeScore'] == null) return null; // Not played yet

    return MatchResult(
      fixtureId: fixtureId,
      homeScore: int.parse(event['intHomeScore']),
      awayScore: int.parse(event['intAwayScore']),
      status: 'FT',
    );
  }
}
```

### Caching Strategy

```dart
// Cache fixtures in Drift to minimize API calls
class FixtureCacheDao extends DatabaseAccessor<AppDatabase> {
  FixtureCacheDao(super.db);

  // Cache upcoming fixtures for 6 hours
  Future<void> cacheFixtures(List<Fixture> fixtures) async {
    final batch = this.batch();
    for (final f in fixtures) {
      batch.insert(
        fixtureCache,
        FixtureCacheCompanion.insert(
          fixtureId: f.id,
          data: jsonEncode(f.toJson()),
          cachedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 6)),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
    await batch.commit();
  }

  // Check cache before hitting API
  Future<List<Fixture>?> getCachedFixtures(String teamId) async {
    final cached = await (select(fixtureCache)
      ..where((t) => t.teamId.equals(teamId))
      ..where((t) => t.expiresAt.isBiggerThanValue(DateTime.now()))
    ).get();

    if (cached.isEmpty) return null;
    return cached.map((c) => Fixture.fromJson(jsonDecode(c.data))).toList();
  }
}
```

### Daily Pre-Fetch Strategy

```dart
// Background: fetch today's fixtures once per day
// Triggered by WorkManager at 6AM local time
Future<void> prefetchDailyFixtures() async {
  final today = DateTime.now();
  final dateStr = DateFormat('yyyy-MM-dd').format(today);

  final response = await dio.get(
    '$baseUrl/$apiKey/eventsday.php',
    queryParameters: {'d': dateStr},
  );

  // Cache all today's fixtures locally
  final fixtures = parseFixtures(response.data);
  await fixtureCacheDao.cacheFixtures(fixtures);
}
```

---

## API-Football (Secondary / Premium)

### When to Use

- Primary when user has Pro/Crew tier (we proxy through our backend)
- Fallback when TheSportsDB data is incomplete
- Required for: live scores, minute-by-minute events, head-to-head stats

### Rate Limit Management

```
Free tier: 100 requests/day
Pro tier: 7,500 requests/day ($9.99/mo)

Strategy:
- Free tier for development and testing
- TheSportsDB for user-facing queries (30 req/min free)
- API-Football reserved for:
  - Live score updates during matches (backend worker)
  - Detailed match statistics (on-demand, cached)
  - Auto-settling bets (backend cron job)
```

### Key Endpoints

```
Base URL: https://v3.football.api-sports.io
Header: x-rapidapi-key: {API_KEY}

# Fixtures by date
GET /fixtures?date=2025-04-15

# Fixtures by team
GET /fixtures?team={teamId}&next=10

# Live fixtures
GET /fixtures?live=all

# Match statistics
GET /fixtures/statistics?fixture={fixtureId}

# Standings
GET /standings?league={leagueId}&season=2025
```

---

## Gemini 2.5 Flash (AI Insights)

### Use Cases

| Feature | Prompt Pattern | Phase |
|---------|---------------|-------|
| **Betting Pattern Analysis** | User's bet history → "Analyze this betting history and identify profitable patterns" | Phase 3 |
| **AI-Moderated Notifications** | User context + trigger → "Generate a personalized push notification" | Phase 1.5 |
| **Match Recommendations** | User's watch history → "Which upcoming matches would this user enjoy?" | Phase 3 |
| **Year in Review Copy** | User's annual stats → "Write a fun, engaging summary paragraph" | Phase 1.5 |
| **OCR Assist (Bet Slip)** | Raw OCR text → "Extract structured bet details from this text" | Phase 2-3 |
| **Fraud Analysis** | Scan history + patterns → "Flag statistically anomalous betting histories" | Phase 3 |

### Implementation

```dart
class AiInsightService {
  final Dio _dio;
  final String _apiKey;

  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const _model = 'models/gemini-2.5-flash';

  Future<BettingInsight> analyzeBettingPattern({
    required List<BetEntry> recentBets,
    required UserStats stats,
  }) async {
    final prompt = '''
    Analyze this user's betting history and provide actionable insights.

    Recent bets (last 30):
    ${recentBets.map((b) => '${b.prediction} @ ${b.odds} on ${b.bookmaker} → ${b.result?.won == true ? "WON" : "LOST"}').join('\n')}

    Overall stats:
    - Win rate: ${stats.winRate}%
    - ROI: ${stats.roi}%
    - Most profitable league: ${stats.topLeague}
    - Most profitable bet type: ${stats.topBetType}
    - Least profitable bookmaker: ${stats.worstBookmaker}

    Provide:
    1. One key strength (max 20 words)
    2. One pattern to avoid (max 20 words)
    3. One actionable suggestion (max 20 words)

    Respond in JSON format:
    { "strength": "", "warning": "", "suggestion": "" }
    ''';

    final response = await _dio.post(
      '$_baseUrl/$_model:generateContent?key=$_apiKey',
      data: {
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 200,
          'responseMimeType': 'application/json',
        },
      },
    );

    final text = response.data['candidates'][0]['content']['parts'][0]['text'];
    return BettingInsight.fromJson(jsonDecode(text));
  }

  Future<String> generateNotificationCopy({
    required String notificationType,
    required Map<String, dynamic> context,
  }) async {
    final prompt = '''
    Generate a short, engaging push notification for a sports diary app.

    Type: $notificationType
    Context: ${jsonEncode(context)}

    Rules:
    - Maximum 100 characters
    - Use 1-2 relevant emojis
    - Be conversational and fun, not robotic
    - Include a specific stat if available

    Return only the notification text, nothing else.
    ''';

    final response = await _dio.post(
      '$_baseUrl/$_model:generateContent?key=$_apiKey',
      data: {
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {
          'temperature': 0.9,
          'maxOutputTokens': 50,
        },
      },
    );

    return response.data['candidates'][0]['content']['parts'][0]['text'].trim();
  }
}
```

### Cost Estimation

| User Count | AI Calls/Day | Monthly Cost |
|-----------|-------------|-------------|
| 1,000 | ~500 (notifications + insights) | ~$0.50 |
| 10,000 | ~5,000 | ~$5 |
| 50,000 | ~25,000 | ~$25 |

Negligible cost at any scale we'd realistically reach.

---

## Google ML Kit (On-Device OCR)

### Purpose

On-device text recognition for scanning physical and digital bet slips. **No network required** — OCR runs entirely on the user's device via Google ML Kit's text recognition v2.

### Why On-Device

| Consideration | On-Device (ML Kit) | Cloud OCR |
|--------------|-------------------|-----------|
| **Cost** | Free | Per-request pricing |
| **Latency** | ~200ms | 1-3 seconds |
| **Offline** | ✅ Works offline | ❌ Requires network |
| **Privacy** | Images never leave device | Images uploaded to cloud |
| **Accuracy** | Good for printed text | Slightly better for handwriting |

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  google_mlkit_text_recognition: ^0.13.0  # On-device OCR
  image_picker: ^1.1.0                    # Camera/gallery capture
  image_cropper: ^8.0.0                   # Manual crop adjustment
  image: ^4.2.0                           # Image processing utilities
```

### Implementation

```dart
// features/verification/data/ocr_service.dart

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Process an image and return structured OCR results
  Future<OcrResult> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);

    // Calculate overall confidence
    final allElements = recognizedText.blocks
        .expand((b) => b.lines)
        .expand((l) => l.elements);
    final avgConfidence = allElements.isEmpty
        ? 0.0
        : allElements.map((e) => e.confidence ?? 0).reduce((a, b) => a + b) /
            allElements.length;

    return OcrResult(
      fullText: recognizedText.text,
      blocks: recognizedText.blocks.map((b) => OcrBlock(
        text: b.text,
        boundingBox: b.boundingBox,
        lines: b.lines.map((l) => l.text).toList(),
      )).toList(),
      confidence: avgConfidence,
    );
  }

  /// Detect which bookmaker this slip belongs to
  String? detectBookmaker(String rawText) {
    final lower = rawText.toLowerCase();
    if (lower.contains('bet9ja') || RegExp(r'b9j', caseSensitive: false).hasMatch(lower)) {
      return 'bet9ja';
    }
    if (lower.contains('sportybet') || lower.contains('sporty bet')) return 'sportybet';
    if (lower.contains('betking') || lower.contains('bet king')) return 'betking';
    if (lower.contains('1xbet')) return '1xbet';
    if (lower.contains('msport')) return 'msport';
    if (lower.contains('bet365')) return 'bet365';
    if (lower.contains('betway')) return 'betway';
    return null; // Unknown — user selects manually
  }

  void dispose() {
    _recognizer.close();
  }
}
```

### Gemini-Assisted Extraction (Fallback)

When ML Kit OCR produces ambiguous results, Gemini 2.5 Flash is used to extract structured data from the raw text:

```dart
/// Fallback: use Gemini to parse messy OCR output into structured bets
Future<ParsedBetSlip> geminiAssistedParse(String rawOcrText) async {
  final prompt = '''
  Extract structured bet slip data from this OCR text.
  The text was scanned from a betting slip photo and may have OCR errors.

  Raw OCR text:
  $rawOcrText

  Extract and return as JSON:
  {
    "bookmaker": "detected bookmaker name or null",
    "slipCode": "booking/ticket code or null",
    "bets": [
      {
        "matchDescription": "Team A vs Team B",
        "prediction": "Home Win / Over 2.5 / BTTS etc",
        "odds": 1.50
      }
    ],
    "totalOdds": 5.25,
    "stake": 1000,
    "currency": "NGN",
    "potentialPayout": 5250
  }

  Rules:
  - Fix obvious OCR errors in team names (e.g. "Arsenai" → "Arsenal")
  - If odds look like "l.50", interpret as "1.50"
  - Return null for fields you cannot determine
  ''';

  final response = await _geminiService.generateContent(prompt,
    responseMimeType: 'application/json',
  );
  return ParsedBetSlip.fromJson(jsonDecode(response));
}
```

### Processing Pipeline

```
Image Captured
    │
    ▼
ML Kit OCR → Raw Text (confidence score)
    │
    ├─── confidence ≥ 0.75 ───→ BetSlipParser (bookmaker-specific)
    │                                │
    │                                ▼
    │                           Structured Data → User Review Screen
    │
    └─── confidence < 0.75 ───→ Gemini Flash (AI-assisted extraction)
                                     │
                                     ▼
                                Structured Data → User Review Screen
```

---

## The Odds API (Optional, Phase 3+)

### Purpose

Real-time odds from 20+ bookmakers. Used for:
- Showing current odds alongside manual bet entry (convenience)
- Comparing user's logged odds vs market average
- Pre-filling odds when user selects a match

### Rate Limits

- Free: 500 requests/month
- Paid: $40/mo for 10K req/mo

### Key Endpoints

```
Base URL: https://api.the-odds-api.com/v4

# List upcoming odds
GET /sports/{sport}/odds?apiKey={key}&regions=uk,eu&markets=h2h

# List available sports
GET /sports?apiKey={key}
```

---

## API Error Handling & Failover

```dart
class FixtureRepository {
  final TheSportsDbSource _primary;
  final ApiFootballSource? _secondary;
  final FixtureCacheDao _cache;

  Future<List<Fixture>> getUpcoming({required String teamId}) async {
    // 1. Check local cache first
    final cached = await _cache.getCachedFixtures(teamId);
    if (cached != null && cached.isNotEmpty) return cached;

    // 2. Try primary API (TheSportsDB)
    try {
      final fixtures = await _primary.getUpcoming(teamId: teamId);
      await _cache.cacheFixtures(fixtures);
      return fixtures;
    } on DioException catch (e) {
      // 3. Failover to secondary (API-Football)
      if (_secondary != null) {
        try {
          final fixtures = await _secondary!.getUpcoming(teamId: teamId);
          await _cache.cacheFixtures(fixtures);
          return fixtures;
        } catch (_) {
          // Both APIs failed
        }
      }

      // 4. Return stale cache if available
      final staleCache = await _cache.getCachedFixtures(teamId, includeExpired: true);
      if (staleCache != null) return staleCache;

      // 5. Throw if nothing available
      rethrow;
    }
  }
}
```

---

## API Key Management

### Development

```bash
# Use --dart-define for build-time injection
flutter run \
  --dart-define=FOOTBALL_API_KEY=your_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key \
  --dart-define=ODDS_API_KEY=your_odds_key
```

### Production

- API keys are compiled into the binary via `--dart-define` (not in source)
- For sensitive operations (AI, odds), proxy through Firebase Cloud Functions or Spring Boot backend
- Rate limiting happens at the backend level, not in the client

### Firebase Cloud Functions (API Proxy)

```typescript
// functions/src/index.ts
// Proxy API calls through Cloud Functions to protect API keys

export const getFixtures = onCall(async (request) => {
  const teamId = request.data.teamId;

  const response = await fetch(
    `https://www.thesportsdb.com/api/v1/json/${API_KEY}/eventsnext.php?id=${teamId}`
  );

  return response.json();
});
```
