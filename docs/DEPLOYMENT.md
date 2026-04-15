# MatchLog — Deployment Plan

> Firebase setup, app store distribution, CI/CD pipeline, and Phase 4+ Spring Boot deployment.

---

## Deployment Environments

| Environment | Purpose | Backend | Distribution |
|-------------|---------|---------|-------------|
| **Development** | Local dev, rapid iteration | Firebase Emulator Suite | Direct USB / `flutter run` |
| **Staging** | Pre-release testing | Firebase project (staging) | Firebase App Distribution |
| **Production** | Live users | Firebase project (prod) → Spring Boot (Phase 4) | Google Play + Apple App Store |

---

## Phase 1-3: Firebase Deployment

### Firebase Project Setup

```bash
# Create two Firebase projects
firebase projects:create matchlog-staging
firebase projects:create matchlog-prod

# Configure Flutter for both
flutterfire configure --project=matchlog-staging --out=lib/firebase_options_staging.dart
flutterfire configure --project=matchlog-prod --out=lib/firebase_options_prod.dart
```

### Environment Switching

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // Initialize Firebase based on environment
  switch (env) {
    case 'prod':
      await Firebase.initializeApp(
        options: DefaultFirebaseOptionsProd.currentPlatform,
      );
      break;
    default:
      await Firebase.initializeApp(
        options: DefaultFirebaseOptionsStaging.currentPlatform,
      );
  }

  runApp(const ProviderScope(child: MatchLogApp()));
}
```

```bash
# Run staging
flutter run --dart-define=ENV=staging

# Build production
flutter build appbundle --release --dart-define=ENV=prod
flutter build ipa --release --dart-define=ENV=prod
```

### Firebase Emulator Suite (Local Development)

```bash
# Install and start emulators
firebase emulators:start --project=matchlog-staging

# Emulator ports:
# Auth:       http://localhost:9099
# Firestore:  http://localhost:8080
# Storage:    http://localhost:9199
# Functions:  http://localhost:5001
```

```dart
// Connect Flutter app to emulators during development
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

### Firestore Indexes

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "match_entries",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "match_entries",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "sport", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "bet_entries",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "settled", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "predictions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "kickoffAt", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "activity_feed",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "targetUserIds", "arrayConfig": "CONTAINS" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

```bash
# Deploy indexes
firebase deploy --only firestore:indexes --project=matchlog-prod
```

### Cloud Functions Deployment

```bash
# Deploy all functions
firebase deploy --only functions --project=matchlog-prod

# Deploy specific function
firebase deploy --only functions:onBetSettled --project=matchlog-prod
```

### Firebase Security Rules Deployment

```bash
firebase deploy --only firestore:rules --project=matchlog-prod
firebase deploy --only storage --project=matchlog-prod
```

---

## App Distribution (Testing)

### Firebase App Distribution (Pre-Release)

```bash
# Build debug APK for testers
flutter build apk --debug

# Upload to Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-debug.apk \
  --app YOUR_APP_ID \
  --groups "beta-testers" \
  --release-notes "Phase 1: Match diary + betting tracker"
```

### TestFlight (iOS)

```bash
# Build IPA
flutter build ipa --release --dart-define=ENV=staging

# Upload to App Store Connect via Xcode or Transporter
# Then distribute via TestFlight
```

---

## Google Play Store

### Pre-Launch Checklist

| Item | Status | Notes |
|------|--------|-------|
| **Developer Account** | Required ($25 one-time) | console.play.google.com |
| **App Signing** | Use Play App Signing | Upload key → Play manages signing |
| **Content Rating** | ESRB/PEGI questionnaire | Declare simulated gambling (tracker, not facilitator) |
| **Data Safety** | Required declaration | List all data collected (email, photos, location, betting history) |
| **Privacy Policy** | Required URL | Host on matchlog.app/privacy |
| **App Bundle** | `.aab` format required | `flutter build appbundle --release` |
| **Store Listing** | Screenshots, description, icon | Use `flutter_launcher_icons` for icon |
| **Target API** | Latest Android API level | Check `build.gradle` targetSdk |

### Build & Upload

```bash
# Build release app bundle
flutter build appbundle --release \
  --dart-define=ENV=prod \
  --dart-define=FOOTBALL_API_KEY=$FOOTBALL_API_KEY

# Output: build/app/outputs/bundle/release/app-release.aab

# Upload via Google Play Console or CLI
# Internal testing → Closed testing → Open testing → Production
```

### Signing Configuration

```groovy
// android/app/build.gradle
android {
    signingConfigs {
        release {
            keyAlias = System.getenv('KEY_ALIAS') ?: keystoreProperties['keyAlias']
            keyPassword = System.getenv('KEY_PASSWORD') ?: keystoreProperties['keyPassword']
            storeFile = file(System.getenv('KEYSTORE_PATH') ?: keystoreProperties['storeFile'])
            storePassword = System.getenv('STORE_PASSWORD') ?: keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## Apple App Store

### Pre-Launch Checklist

| Item | Status | Notes |
|------|--------|-------|
| **Developer Account** | Required ($99/year) | developer.apple.com |
| **App ID + Provisioning** | Xcode managed | Bundle ID: `com.matchlog.app` |
| **Apple Sign-In** | Required (if other social logins exist) | `sign_in_with_apple` plugin |
| **App Tracking Transparency** | Required if tracking | Likely not needed — no third-party ads |
| **Screenshots** | iPhone 6.5", 5.5", iPad | 3+ screenshots per device size |
| **Privacy Policy** | Required URL | matchlog.app/privacy |
| **Age Rating** | 17+ (contains gambling references) | Mark "Simulated Gambling: Frequent/Intense" |
| **Review Notes** | Explain betting tracker is NOT gambling | Include demo account credentials |

### Build & Upload

```bash
# Build iOS release
flutter build ipa --release \
  --dart-define=ENV=prod \
  --dart-define=FOOTBALL_API_KEY=$FOOTBALL_API_KEY

# Output: build/ios/ipa/matchlog.ipa

# Upload via Xcode (Product → Archive → Upload)
# Or via xcrun:
xcrun altool --upload-app -f build/ios/ipa/matchlog.ipa \
  -t ios -u $APPLE_ID -p $APP_SPECIFIC_PASSWORD
```

---

## CI/CD Pipeline (GitHub Actions)

### Test Workflow

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [develop]
  pull_request:
    branches: [develop, main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Analyze code
        run: flutter analyze

      - name: Check formatting
        run: dart format --set-exit-if-changed lib/ test/

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
```

### Build & Deploy Workflow

```yaml
# .github/workflows/build.yml
name: Build & Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks

      - name: Build APK
        run: |
          flutter build appbundle --release \
            --dart-define=ENV=prod \
            --dart-define=FOOTBALL_API_KEY=${{ secrets.FOOTBALL_API_KEY }}
        env:
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          KEYSTORE_PATH: upload-keystore.jks
          STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}

      - name: Upload to Play Console
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
          packageName: com.matchlog.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Build iOS
        run: |
          flutter build ipa --release \
            --dart-define=ENV=prod \
            --dart-define=FOOTBALL_API_KEY=${{ secrets.FOOTBALL_API_KEY }} \
            --export-options-plist=ios/ExportOptions.plist

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/ipa/matchlog.ipa
          issuer-id: ${{ secrets.APPLE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPLE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPLE_API_PRIVATE_KEY }}
```

### Required GitHub Secrets

| Secret | Purpose |
|--------|---------|
| `FOOTBALL_API_KEY` | TheSportsDB / API-Football key |
| `GEMINI_API_KEY` | Gemini Flash API key |
| `KEYSTORE_BASE64` | Android signing keystore (base64 encoded) |
| `KEY_ALIAS` | Keystore alias |
| `KEY_PASSWORD` | Key password |
| `STORE_PASSWORD` | Keystore password |
| `PLAY_SERVICE_ACCOUNT_JSON` | Google Play upload service account |
| `APPLE_ISSUER_ID` | App Store Connect API issuer |
| `APPLE_API_KEY_ID` | App Store Connect API key ID |
| `APPLE_API_PRIVATE_KEY` | App Store Connect API private key |

---

## Phase 4+: Spring Boot Deployment

### Docker Compose (Development)

```yaml
# matchlog-api/docker-compose.yml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - DATABASE_URL=jdbc:postgresql://db:5432/matchlog_dev
      - DATABASE_USERNAME=matchlog
      - DATABASE_PASSWORD=matchlog_dev_pass
      - REDIS_HOST=cache
      - REDIS_PORT=6379
      - JWT_SECRET=${JWT_SECRET}
      - FOOTBALL_API_KEY=${FOOTBALL_API_KEY}
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
    volumes:
      - ./firebase-credentials.json:/app/firebase-credentials.json:ro
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started

  match-updater:
    build:
      context: .
      dockerfile: Dockerfile
    command: java -jar app.jar --spring.profiles.active=worker
    environment:
      - SPRING_PROFILES_ACTIVE=worker
      - DATABASE_URL=jdbc:postgresql://db:5432/matchlog_dev
      - DATABASE_USERNAME=matchlog
      - DATABASE_PASSWORD=matchlog_dev_pass
      - FOOTBALL_API_KEY=${FOOTBALL_API_KEY}
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_DB=matchlog_dev
      - POSTGRES_USER=matchlog
      - POSTGRES_PASSWORD=matchlog_dev_pass
    ports:
      - "5433:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U matchlog"]
      interval: 5s
      timeout: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    ports:
      - "6380:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Spring Boot Dockerfile

```dockerfile
# Build stage
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Production Deployment (VPS)

```bash
# Similar to Mockline deployment pattern
# 1. SSH into VPS
ssh user@matchlog-vps

# 2. Pull latest code
cd /opt/matchlog-api
git pull origin main

# 3. Build and deploy
docker compose -f docker-compose.prod.yml up -d --build

# 4. Run migrations
docker compose exec api java -jar app.jar --spring.flyway.migrate

# 5. Health check
curl -f http://localhost:8080/api/health || echo "UNHEALTHY"
```

---

## Domain & SSL (Deep Links)

### Domain Setup

| Subdomain | Purpose | Hosting |
|-----------|---------|---------|
| `matchlog.app` | Landing page (if ever needed) | Vercel / Cloudflare Pages |
| `api.matchlog.app` | Spring Boot API (Phase 4+) | VPS |
| `matchlog.app/.well-known/` | App Links + Universal Links | Vercel / Cloudflare |

### Deep Link Files

```bash
# Serve from matchlog.app or a subdomain

# Android: /.well-known/assetlinks.json
# iOS: /.well-known/apple-app-site-association

# These files make deep links open the app directly
# instead of the browser.
#
# Content defined in SECURITY.md
```

---

## Monitoring & Alerts

### Phase 1-3: Firebase Console

| Metric | Where | Alert |
|--------|-------|-------|
| **Crash reports** | Firebase Crashlytics | Auto-enabled |
| **Performance** | Firebase Performance | Slow screen traces |
| **Auth failures** | Firebase Console → Auth | Manual check |
| **Firestore usage** | Firebase Console → Usage | Approach free tier limits |

### Phase 4+: Spring Boot

| Tool | Purpose |
|------|---------|
| **Spring Boot Actuator** | `/actuator/health`, `/actuator/metrics` |
| **Docker healthcheck** | Container-level health monitoring |
| **UptimeRobot** | External ping monitoring (free) |
| **Sentry** | Error tracking (Flutter + Spring Boot) |

---

## Rollback Plan

### Flutter App (Can't Roll Back App Store Immediately)

- **Google Play**: Upload previous version as new release. 1-3 hour review.
- **Apple App Store**: "Remove from Sale" immediately, submit previous version. 24-48h review.
- **Mitigation**: Use remote feature flags (Firebase Remote Config) to disable broken features instantly without app update.

### Spring Boot API (Phase 4+)

```bash
# Immediate rollback via Docker
docker compose -f docker-compose.prod.yml down
docker tag matchlog-api:latest matchlog-api:broken
docker tag matchlog-api:previous matchlog-api:latest
docker compose -f docker-compose.prod.yml up -d

# Database rollback (if Flyway migration caused issues)
# Flyway doesn't auto-rollback — manually apply reverse migration
docker compose exec api java -jar app.jar --spring.flyway.repair
```

---

## Release Schedule

| Phase | Target | Store Track |
|-------|--------|------------|
| **Phase 1** | Week 6 | Internal testing → Closed alpha (10 users) |
| **Phase 1.5** | Week 8 | Open beta (100 users) |
| **Phase 2** | Week 12 | Production release (public) |
| **Phase 3** | Week 16 | Production update (monetization enabled) |
| **Phase 4** | Week 24 | Backend migration (transparent to users) |
