# MatchLog Learning Plan

A disciplined 5-day study plan for understanding the architecture, data flow, Firebase usage, and native platform boundaries used in MatchLog.

Recommended pace: **60-90 minutes per day**

## How to Use This Plan

Each day has four parts:

1. Read the official docs for the source of truth
2. Read 1-2 external writeups for applied thinking and pitfalls
3. Inspect the matching MatchLog files
4. Write a short note in your own words

Rules for this plan:

- Trust official docs for API behavior and setup details
- Use Medium, dev.to, and blog posts for intuition, tradeoffs, and real-world mistakes
- If an external article conflicts with current docs, prefer the official docs
- Focus on why a layer exists, not just how to call it

---

## Day 1: Offline-First Architecture and Data Flow

### Goal

Understand why MatchLog is local-first and why the data flow matters more than any single package.

### Read: official

- Flutter Offline-First Support  
  https://docs.flutter.dev/app-architecture/design-patterns/offline-first
- Firestore Offline Access  
  https://firebase.google.com/docs/firestore/manage-data/enable-offline
- Firestore Data Model  
  https://firebase.google.com/docs/firestore/data-model

### Read: external

- Starter Architecture for Flutter & Firebase Apps  
  https://dev.to/biz84/starter-architecture-for-flutter-firebase-apps-50bc
- Flutter Clean Architecture with Riverpod  
  https://medium.com/%40romaanofficial/flutter-clean-architecture-with-riverpod-d496775c06f6

### Inspect in MatchLog

- [docs/ARCHITECTURE.md](/Users/user/dev-projects/matchlog/docs/ARCHITECTURE.md)
- [docs/API_INTEGRATIONS.md](/Users/user/dev-projects/matchlog/docs/API_INTEGRATIONS.md)
- [lib/core/network/sync_queue.dart](/Users/user/dev-projects/matchlog/lib/core/network/sync_queue.dart)
- [lib/core/network/connectivity_service.dart](/Users/user/dev-projects/matchlog/lib/core/network/connectivity_service.dart)
- [lib/core/database/app_database.dart](/Users/user/dev-projects/matchlog/lib/core/database/app_database.dart)

### What to Learn

- Why local writes improve reliability
- Why sync queues exist even when Firestore has offline support
- Why Drift and Firestore solve different problems
- Why data ownership should stay clear between local cache, app state, and cloud

### Deliverable

Write 5-8 lines answering:  
`Why is MatchLog using Drift + Firebase instead of Firebase alone?`

---

## Day 2: Drift, Tables, DAOs, and Reactive Queries

### Goal

Understand the database layer deeply, especially what a DAO is and why local persistence needs its own structure.

### Read: official

- Drift Overview  
  https://drift.simonbinder.eu/
- Drift Tables  
  https://drift.simonbinder.eu/dart_api/tables/
- Drift DAOs  
  https://drift.simonbinder.eu/dart_api/daos/
- Drift Rows and Companions  
  https://drift.simonbinder.eu/dart_api/rows/
- Drift Stream Queries  
  https://drift.simonbinder.eu/dart_api/streams/
- Drift Transactions  
  https://drift.simonbinder.eu/dart_api/transactions/

### Read: external

- Flutter + Firestore: You may be using it wrong.  
  https://medium.com/flutter-community/flutter-firestore-you-may-be-using-it-wrong-b56fa689e489
- Top 10 Mistakes Developers Still Make with Firebase in 2025  
  https://dev.to/mridudixit15/top-10-mistakes-developers-still-make-with-firebase-in-2025-53ah

### Inspect in MatchLog

- [lib/core/database/app_database.dart](/Users/user/dev-projects/matchlog/lib/core/database/app_database.dart)
- [lib/core/database/type_converters.dart](/Users/user/dev-projects/matchlog/lib/core/database/type_converters.dart)
- [lib/core/database/daos/match_dao.dart](/Users/user/dev-projects/matchlog/lib/core/database/daos/match_dao.dart)
- [lib/core/database/daos/bet_dao.dart](/Users/user/dev-projects/matchlog/lib/core/database/daos/bet_dao.dart)
- [lib/core/database/daos/group_dao.dart](/Users/user/dev-projects/matchlog/lib/core/database/daos/group_dao.dart)
- [lib/core/database/daos/prediction_dao.dart](/Users/user/dev-projects/matchlog/lib/core/database/daos/prediction_dao.dart)

### What to Learn

- A table defines schema
- A generated row represents stored data
- A companion represents insert and update payloads
- A DAO groups related queries and hides database details from higher layers
- `watch()` queries are part of the reactive contract with the UI
- Transactions matter once multiple writes must succeed together

### Deliverable

Write a short explanation of:

- what a DAO is
- why `watchMatchesByUser()` is different from a one-time query
- why reactive local queries are valuable in an offline-first app

---

## Day 3: Riverpod, Routing, and App Wiring

### Goal

Understand how dependencies are created, exposed, and consumed, and how navigation stays structured as the app grows.

### Read: official

- Riverpod Providers  
  https://docs-v2.riverpod.dev/docs/concepts/providers
- Riverpod Provider Lifecycles  
  https://docs-v2.riverpod.dev/docs/concepts/provider_lifecycles
- `go_router` package docs  
  https://pub.dev/packages/go_router
- `go_router` deep linking docs  
  https://pub.dev/documentation/go_router/latest/topics/Deep%20linking-topic.html

### Read: external

- Flutter Clean Architecture with Riverpod  
  https://medium.com/%40romaanofficial/flutter-clean-architecture-with-riverpod-d496775c06f6
- Flutter Deep Linking article  
  https://dev.to/smartterss/flutter-deep-linking-pathways-to-specific-app-content-4i8d

### Inspect in MatchLog

- [lib/core/di/providers.dart](/Users/user/dev-projects/matchlog/lib/core/di/providers.dart)
- [lib/core/di/service_locator.dart](/Users/user/dev-projects/matchlog/lib/core/di/service_locator.dart)
- [lib/core/router/routes.dart](/Users/user/dev-projects/matchlog/lib/core/router/routes.dart)
- [lib/core/router/app_router.dart](/Users/user/dev-projects/matchlog/lib/core/router/app_router.dart)
- [lib/core/router/deep_link_handler.dart](/Users/user/dev-projects/matchlog/lib/core/router/deep_link_handler.dart)
- [lib/main.dart](/Users/user/dev-projects/matchlog/lib/main.dart)
- [lib/app.dart](/Users/user/dev-projects/matchlog/lib/app.dart)

### What to Learn

- What a provider is and what it should own
- Why lifecycle and disposal matter
- Why app-wide services should not be manually instantiated everywhere
- Why route definitions should stay centralized
- How deep links affect route design before the feature is fully built

### Deliverable

Write 5-8 lines answering:

- `What is the difference between service initialization and provider-based dependency access?`
- `How would a future group invite link move through MatchLog's router?`

---

## Day 4: Firebase Mastery for MatchLog

### Goal

Understand the advanced Firebase parts that matter directly for MatchLog: Auth, Firestore, Storage, Messaging, rules, and the failure modes around them.

### Read: official

- Get Started with Firebase Authentication on Flutter  
  https://firebase.google.com/docs/auth/flutter/start
- Manage Users in Firebase  
  https://firebase.google.com/docs/auth/flutter/manage-users
- Cloud Firestore Data Model  
  https://firebase.google.com/docs/firestore/data-model
- Get Started with Cloud Firestore Security Rules  
  https://firebase.google.com/docs/firestore/security/get-started
- Upload files with Cloud Storage on Flutter  
  https://firebase.google.com/docs/storage/flutter/upload-files
- Receive messages in Flutter apps  
  https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages

### Read: external

- Starter Architecture for Flutter & Firebase Apps  
  https://dev.to/biz84/starter-architecture-for-flutter-firebase-apps-50bc
- Flutter + Firestore: You may be using it wrong.  
  https://medium.com/flutter-community/flutter-firestore-you-may-be-using-it-wrong-b56fa689e489
- Top 10 Mistakes Developers Still Make with Firebase in 2025  
  https://dev.to/mridudixit15/top-10-mistakes-developers-still-make-with-firebase-in-2025-53ah

### Inspect in MatchLog

- [docs/API_INTEGRATIONS.md](/Users/user/dev-projects/matchlog/docs/API_INTEGRATIONS.md)
- [lib/core/notifications/notification_service.dart](/Users/user/dev-projects/matchlog/lib/core/notifications/notification_service.dart)
- [lib/core/notifications/notification_handler.dart](/Users/user/dev-projects/matchlog/lib/core/notifications/notification_handler.dart)
- [lib/core/notifications/notification_queue.dart](/Users/user/dev-projects/matchlog/lib/core/notifications/notification_queue.dart)
- [lib/core/notifications/channels.dart](/Users/user/dev-projects/matchlog/lib/core/notifications/channels.dart)
- [ios/Runner/Info.plist](/Users/user/dev-projects/matchlog/ios/Runner/Info.plist)
- [android/app/src/main/AndroidManifest.xml](/Users/user/dev-projects/matchlog/android/app/src/main/AndroidManifest.xml)

### What to Learn

- `authStateChanges()`, `idTokenChanges()`, and `userChanges()` solve different problems
- Firestore is not relational; document shape affects performance, cost, and rules
- Security rules are part of the backend, not optional config
- Storage should hold files; Firestore should hold metadata and references
- FCM behavior changes across foreground, background, and terminated states
- Android notification channels and iOS permissions are product behavior, not just setup noise
- Push notifications often fail because of app state assumptions, not SDK calls

### MatchLog-Specific Notes

- MatchLog will rely on Firebase for identity, cloud sync, push, and asset storage, but not as the only local source of truth
- The notification files are still light stubs, so this is the right time to learn the model before implementation hardens
- Read this day with a backend mindset, not just a Flutter-plugin mindset

### Deliverable

Write 8-10 lines answering:

- when MatchLog should read from Drift first vs Firestore first
- what data belongs in Firestore vs Storage
- three FCM mistakes you want to avoid when implementation starts

---

## Day 5: Native Boundary, Platform Channels, Pigeon, and Build-System Reality

### Goal

Understand where Flutter stops, where native code begins, and how platform integration issues actually surface in a real app.

### Read: official

- Platform-specific code and platform channels  
  https://docs.flutter.dev/platform-integration/platform-channels
- Pigeon package docs  
  https://pub.dev/packages/pigeon
- Flutter architectural overview  
  https://docs.flutter.dev/resources/architectural-overview

### Read: external

- How to use Flutter platform channels: expert guide  
  https://decode.agency/article/flutter-platform-channels-guide/
- Native Channels in Flutter — A Complete Guide  
  https://dev.to/omar_elsadany_f3e48cab5b9/native-channels-in-flutter-a-complete-guide-52h1

### Inspect in MatchLog

- [ios/Runner/AppDelegate.swift](/Users/user/dev-projects/matchlog/ios/Runner/AppDelegate.swift)
- [android/app/src/main/kotlin/com/matchlog/matchlog/MainActivity.kt](/Users/user/dev-projects/matchlog/android/app/src/main/kotlin/com/matchlog/matchlog/MainActivity.kt)
- [ios/Podfile](/Users/user/dev-projects/matchlog/ios/Podfile)
- [ios/Runner/Runner-Bridging-Header.h](/Users/user/dev-projects/matchlog/ios/Runner/Runner-Bridging-Header.h)
- [lib/core/router/deep_link_handler.dart](/Users/user/dev-projects/matchlog/lib/core/router/deep_link_handler.dart)

### What to Learn

- When to use `MethodChannel`, `EventChannel`, or `BasicMessageChannel`
- Why raw string-based channels become brittle
- Why Pigeon helps when the native boundary gets serious
- Why native integrations usually involve code plus config plus build tooling
- How Podfile, Xcode settings, manifests, and entitlements can break a Flutter app even when Dart code is correct
- Why deep links, push extensions, and custom SDKs often require native changes

### MatchLog-Specific Notes

- Right now MatchLog's native entry points are intentionally minimal
- That makes this the ideal time to understand the boundary before adding custom native features
- The recent Firebase CocoaPods issue is a real example of Flutter apps failing below the Dart layer

### Deliverable

Write 8 lines answering:

- when MatchLog should stay inside Flutter plugins
- when a custom platform channel becomes justified
- why a Podfile or manifest problem can block the whole app

---

## Optional Support Reading

Use these only after the 5 days if you want extra depth:

- Transforming FlutterFire: The Official Firebase SDK for Flutter  
  https://invertase.io/blog/transforming-flutterfire-official-firebase-sdk-flutter
- Multi-Factor Authentication with Flutter and Firebase  
  https://invertase.io/blog/flutterfire-mfa-tutorial

These are useful for understanding how mature FlutterFire is, where the native boundary still matters, and how official plugins evolve.

---

## Compressed 3-Day Version

If you want stricter discipline, merge the days like this:

- **Day 1:** Offline-first architecture, Firestore model, Drift, and sync flow
- **Day 2:** DAOs, Riverpod, routing, deep links, and app wiring
- **Day 3:** Firebase Auth, Firestore, Storage, Messaging, platform channels, and native build realities

---

## Recommended Outcome

By the end of this plan, you should be able to explain:

- what a DAO is and why MatchLog uses them
- why Drift and Firebase are complementary, not redundant
- how Riverpod and routing shape app composition
- how Auth, Firestore, Storage, and Messaging each fit into MatchLog
- what can only be solved at the native boundary
- why build tooling is part of architecture, not a side concern

## Writing Ideas

If you want to turn this learning path into Medium posts, these are strong article directions:

- **Why Firestore Offline Support Is Not Enough for Serious Flutter Apps**  
  Good angle for explaining why apps still need a local database like Drift.
- **What a DAO Actually Solves in Flutter Apps Using Drift**  
  Good for teaching structure, query ownership, and reactive local data access.
- **Firestore Document Modeling for Mobile Apps: What to Flatten, What to Split, What to Avoid**  
  Good for performance, billing, and rules-focused thinking.
- **Firebase Messaging in Flutter: The Foreground, Background, and Terminated-State Mental Model**  
  Good for showing why push notification bugs are often architectural, not just setup issues.
- **When Flutter Plugins Are Enough and When You Need Platform Channels or Pigeon**  
  Good for advanced readers moving from pure Flutter into native integration.

Optional extra topics:

- **Why Drift + Firebase Is a Strong Offline-First Combination**
- **How Riverpod Helps Keep Flutter App Wiring Clean Without Becoming the Architecture Itself**
- **What Recent CocoaPods and Native Build Failures Taught Me About Flutter's Real Architecture**

If you want, the next step can be a second file focused only on **how to build new MatchLog features cleanly**: repositories, use cases, feature modules, sync decisions, and implementation checklists.
