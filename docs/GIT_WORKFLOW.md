# MatchLog — Git Workflow

> Branch strategy, commit conventions, PR process, and release management.

---

## Branch Strategy

### Trunk-Based with Feature Branches

```
main (production)
  │
  ├── develop (integration branch)
  │     │
  │     ├── feature/auth-google-signin
  │     ├── feature/diary-match-logging
  │     ├── feature/betting-tracker
  │     ├── feature/stats-dashboard
  │     ├── feature/offline-sync
  │     ├── feature/push-notifications
  │     ├── feature/social-profiles
  │     ├── feature/bookie-groups
  │     ├── feature/predictions
  │     ├── feature/ai-insights
  │     ├── feature/year-review
  │     │
  │     ├── fix/drift-migration-crash
  │     ├── fix/odds-decimal-precision
  │     │
  │     └── chore/update-dependencies
  │
  ├── release/1.0.0
  ├── release/1.1.0
  │
  └── hotfix/critical-auth-bug
```

### Branch Rules

| Branch | Purpose | Merges Into | Protection |
|--------|---------|-------------|-----------|
| `main` | Production-ready code. Tagged releases only. | — | Protected. No direct pushes. Requires PR + CI pass. |
| `develop` | Integration branch. All features merge here first. | `main` (via release branch) | Protected. Requires PR. |
| `feature/*` | New features. One branch per feature. | `develop` | — |
| `fix/*` | Bug fixes (non-critical). | `develop` | — |
| `hotfix/*` | Critical production fixes. | `main` AND `develop` | — |
| `release/*` | Release preparation. Version bump, changelog. | `main` | — |
| `chore/*` | Non-functional changes (deps, CI, docs). | `develop` | — |

---

## Commit Conventions

### Conventional Commits

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | When | Example |
|------|------|---------|
| `feat` | New feature | `feat(diary): add match logging screen` |
| `fix` | Bug fix | `fix(betting): correct odds decimal precision` |
| `refactor` | Code change that doesn't fix a bug or add a feature | `refactor(auth): extract token manager to separate class` |
| `test` | Adding or updating tests | `test(diary): add unit tests for calculate_stats usecase` |
| `docs` | Documentation changes | `docs: update API integration guide` |
| `chore` | Build, CI, dependency updates | `chore: bump flutter_riverpod to 2.5.1` |
| `style` | Code formatting (no logic change) | `style: apply dart format to lib/` |
| `perf` | Performance improvement | `perf(search): add debounce to fixture search` |
| `ci` | CI/CD changes | `ci: add iOS build to GitHub Actions` |

### Scopes

| Scope | Feature Area |
|-------|-------------|
| `auth` | Authentication |
| `diary` | Match diary / logging |
| `betting` | Bet tracking / ROI |
| `search` | Match/fixture search |
| `social` | Profiles, follow, feed |
| `groups` | Bookie Groups |
| `predictions` | Predictions & leagues |
| `notifications` | Push notifications |
| `offline` | Drift / sync queue |
| `stats` | Stats dashboard / charts |
| `review` | Year in Review |
| `design` | Theme, colors, UI components |
| `infra` | Firebase config, CI/CD |
| `api` | External API integrations |

### Examples

```bash
# Good commits
feat(diary): implement match logging form with Riverpod state
feat(betting): add bookmaker selector with affiliate links
fix(offline): prevent duplicate sync operations on reconnect
refactor(auth): migrate to abstract auth repository interface
test(groups): add integration test for invite code generation
chore: upgrade drift to 2.18.0 and regenerate database code
perf(stats): cache ROI calculations in Riverpod provider
docs(api): document TheSportsDB rate limit strategy

# Bad commits
fix: stuff                          # Too vague
update code                         # No type, no scope
feat: added everything              # Too broad
WIP                                 # Never commit WIP to develop/main
```

---

## Feature Development Workflow

### 1. Start a Feature

```bash
# Always branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/diary-match-logging
```

### 2. Develop Incrementally

```bash
# Small, focused commits
git add lib/features/diary/domain/entities/match_entry.dart
git commit -m "feat(diary): define MatchEntry freezed entity"

git add lib/features/diary/domain/repositories/diary_repository.dart
git commit -m "feat(diary): add abstract DiaryRepository interface"

git add lib/features/diary/data/
git commit -m "feat(diary): implement DiaryRepositoryImpl with Drift + Firebase"

git add lib/features/diary/presentation/
git commit -m "feat(diary): build match logging screen and diary feed"

git add test/features/diary/
git commit -m "test(diary): add unit tests for log_match usecase"
```

### 3. Keep Branch Updated

```bash
# Rebase on develop regularly to avoid merge conflicts
git fetch origin
git rebase origin/develop

# If conflicts occur, resolve them file by file
git add .
git rebase --continue
```

### 4. Push & Create PR

```bash
git push origin feature/diary-match-logging
```

### 5. PR Description Template

```markdown
## Summary
Brief description of what this PR does.

## Type
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Chore

## Changes
- Added `MatchEntry` entity with Freezed
- Implemented `DiaryRepository` with offline-first pattern
- Built match logging screen with form validation
- Added Drift DAO for local persistence

## Testing
- [ ] Unit tests pass (`flutter test`)
- [ ] Manual testing on Android emulator
- [ ] Manual testing on iOS simulator
- [ ] Offline scenario tested

## Screenshots
(attach screenshots for UI changes)

## Checklist
- [ ] Code follows project conventions
- [ ] No `print()` statements (use logger)
- [ ] `dart format` applied
- [ ] `flutter analyze` passes
- [ ] Build runner generated code committed
```

---

## Release Process

### Version Scheme

```
MAJOR.MINOR.PATCH+BUILD

1.0.0+1   — Initial release (Phase 1)
1.1.0+5   — Phase 1.5 features (notifications, heatmap)
2.0.0+12  — Phase 2 (social features)
3.0.0+20  — Phase 3 (AI, prediction leagues)
4.0.0+30  — Phase 4 (Spring Boot migration)
```

### Release Flow

```bash
# 1. Create release branch from develop
git checkout develop
git checkout -b release/1.0.0

# 2. Version bump
# Update pubspec.yaml: version: 1.0.0+1
# Update CHANGELOG.md

# 3. Final testing on release branch
flutter test
flutter build apk --release
flutter build ios --release

# 4. Merge to main
git checkout main
git merge release/1.0.0
git tag -a v1.0.0 -m "Release 1.0.0: Core diary + betting tracker"
git push origin main --tags

# 5. Merge back to develop
git checkout develop
git merge release/1.0.0
git push origin develop

# 6. Delete release branch
git branch -d release/1.0.0
```

### Hotfix Flow

```bash
# 1. Branch from main
git checkout main
git checkout -b hotfix/auth-crash-fix

# 2. Fix the issue
git commit -m "fix(auth): handle null user in token refresh"

# 3. Merge to main AND develop
git checkout main
git merge hotfix/auth-crash-fix
git tag -a v1.0.1 -m "Hotfix: auth crash on token refresh"

git checkout develop
git merge hotfix/auth-crash-fix

# 4. Push everything
git push origin main --tags
git push origin develop
```

---

## Phase-Based Branch Planning

### Phase 1 (Weeks 1-6) — Feature Branches

```
feature/project-setup             # Flutter create, Firebase config, dependencies
feature/auth-firebase              # Google + Email + Apple sign-in
feature/drift-database             # Drift setup, tables, DAOs, migrations
feature/diary-match-logging        # Match search, logging form, diary feed
feature/betting-tracker            # Bet logging, bookmaker selector, settlement
feature/stats-dashboard            # ROI charts, match stats, CustomPainter
feature/offline-sync               # SyncQueue, connectivity detection, replay
feature/photo-uploads              # Camera, compression, Firebase Storage
feature/app-theme                  # FPL-inspired design system, colors, typography
```

### Phase 1.5 (Weeks 7-8)

```
feature/push-notifications         # FCM setup, channels, background handler
feature/calendar-heatmap           # GitHub-style contribution graph
feature/stadium-checkin            # Geolocation, geofencing, badge system
feature/year-review                # Data aggregation, Wrapped-style UI, share cards
```

### Phase 2 (Weeks 9-12)

```
feature/user-profiles              # Profile screen, edit profile, privacy settings
feature/follow-system              # Follow/unfollow, follower list, search
feature/activity-feed              # Fan-out-on-write, infinite scroll, real-time
feature/bookie-groups              # Create, join, invite codes, deep links
feature/group-predictions          # Prediction board, auto-settlement, scoring
feature/group-leaderboard          # Ranking, stats, season standings
```

### Phase 3 (Weeks 13-16)

```
feature/ai-betting-insights        # Gemini Flash integration, pattern analysis
feature/ai-notifications           # Personalized notification copy generation
feature/prediction-leagues         # Weekly rounds, scoring system, end-of-season awards
feature/social-sharing             # Deep links, OG previews, share cards
feature/in-app-purchases           # Pro/Crew tiers, Google Play Billing, Apple IAP
feature/affiliate-links            # Bookmaker referral CTAs
feature/onboarding-flow            # First-time user experience
feature/polish                     # Empty states, loading skeletons, micro-animations
```

### Phase 4 (Weeks 17-24)

```
feature/spring-boot-setup          # Project init, Docker Compose, Flyway
feature/spring-security-jwt        # Auth endpoints, JWT provider, filter chain
feature/spring-diary-api           # Match CRUD endpoints
feature/spring-betting-api         # Bet CRUD + settlement endpoints
feature/spring-social-api          # Follow, feed, profiles
feature/spring-groups-api          # Bookie Groups CRUD
feature/spring-predictions-api     # Predictions + leagues
feature/spring-background-workers  # @Scheduled match result updater
feature/flutter-spring-migration   # Swap FirebaseDataSource → SpringDataSource
```

---

## .gitignore

```gitignore
# Flutter
**/Flutter/ephemeral/
**/Pods/
build/
.dart_tool/
.packages
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
*.iml
.vscode/
*.swp
*.swo

# Generated
*.g.dart
*.freezed.dart
*.mocks.dart

# Environment
.env
*.env.local

# Firebase
google-services.json          # Android (add to .gitignore if public repo)
GoogleService-Info.plist      # iOS (add to .gitignore if public repo)
firebase_options.dart         # Generated config

# Build artifacts
*.apk
*.aab
*.ipa
*.app.dSYM.zip

# Coverage
coverage/
*.lcov

# OS
.DS_Store
Thumbs.db
```

> **Note on Firebase configs:** For a private repo, you can commit `google-services.json` and `GoogleService-Info.plist`. For a public repo, add them to `.gitignore` and document how to set them up.

---

## GitHub Repository Settings

| Setting | Value |
|---------|-------|
| **Default branch** | `develop` |
| **Branch protection: main** | Require PR, require CI pass, no direct push |
| **Branch protection: develop** | Require PR, require CI pass |
| **Auto-delete head branches** | Enabled |
| **Squash merging** | Enabled (optional — keeps history clean) |
| **Labels** | `phase-1`, `phase-2`, `phase-3`, `phase-4`, `bug`, `feature`, `chore`, `priority-high` |
