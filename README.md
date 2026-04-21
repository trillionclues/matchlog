# MatchLog

MatchLog is a mobile-first social sports diary and betting tracker built with Flutter. The product combines personal match logging, betting performance tracking, group predictions, and offline-first data handling into a single app experience.

The project is designed as a long-term portfolio-grade build: Phase 1 focuses on a strong foundation for mobile product engineering, while later phases expand the social, AI, and backend capabilities.

## What It Is

- Log matches you watched, rated, and reviewed
- Track bets, outcomes, and ROI across bookmakers
- Support prediction groups and social sports activity
- Work offline first, then sync to cloud services when connectivity returns
- Start with football while keeping the data model sport-agnostic

## Current Scope

The current codebase is in **Phase 1: Foundation**.

Implemented so far:

- Core app architecture and project scaffolding
- Design system and shared UI building blocks
- App configuration, routing, and dependency injection
- Drift-powered local database with 11 tables and typed DAOs
- Networking and backend integration foundations
- Firebase integration and iOS CocoaPods/FlutterFire compatibility fixes
- Initial tests for utilities and database access layers

## Tech Stack

- **Frontend:** Flutter, Dart
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **Local Database:** Drift + SQLite
- **Networking:** Dio
- **Backend (current):** Firebase Auth, Firestore, Storage, Messaging
- **Target Backend (later phase):** Spring Boot
- **Platform Focus:** iOS and Android

## Architecture

MatchLog follows a modular, clean architecture approach with an offline-first strategy.

- `core/` contains shared configuration, theme, routing, DI, database, and utilities
- `shared/` contains reusable widgets and constants
- Drift acts as the local source of truth for writes
- Firebase is the sync and cloud services layer in early phases
- The backend boundary is structured to allow a future migration to Spring Boot without rewriting the presentation layer

High-level flow:

`Flutter UI -> Riverpod providers -> local database / repositories -> Firebase APIs`

## Running The Project

### Prerequisites

- Flutter stable
- Dart SDK
- Xcode and CocoaPods for iOS
- Android Studio or VS Code

### Setup

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

Environment values are provided with `--dart-define` and are used for app environment and API configuration.

## Documentation

- [Project Overview](docs/PROJECT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Development Guide](docs/DEVELOPMENT.md)
- [Design System](docs/DESIGN.md)
- [Data Models](docs/DATA_MODELS.md)
- [API Integrations](docs/API_INTEGRATIONS.md)
- [Testing Strategy](docs/TESTING.md)
- [Security](docs/SECURITY.md)

## Roadmap

- **Phase 1:** Foundation and core infrastructure
- **Phase 1.5:** Notifications, heatmap, stadium check-in
- **Phase 2:** Social layer, prediction groups, bet slip workflows
- **Phase 3:** AI insights, monetization, advanced trust systems
- **Phase 4+:** Spring Boot backend migration and platform scaling

## Status

MatchLog is actively under development!
