# Design Document: User Auth

## Overview

This document describes the technical design for the MatchLog auth phase built on
top of the completed Phase 1 foundation. The goal is to add production-ready
authentication without breaking the current architecture decisions:

1. Drift remains the local source of truth for cached user profile state
2. Firebase Auth is the Phase 1-3 auth backend
3. Riverpod drives reactive state into the widget tree
4. GoRouter enforces access control at the navigation layer

The feature covers Google sign-in, email/password sign-in and registration,
email verification, session restoration, first-launch onboarding, and router
guards for protected routes.

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data
                   ^          ^
                   |          |
                 Core      Firebase + Drift + SharedPreferences
```

- `domain/` stays pure Dart and defines entities, failures, repositories, and use cases
- `data/` implements domain contracts with Firebase Auth and the local Drift cache
- `presentation/` owns screens, widgets, and Riverpod-facing controllers/providers
- `core/router/` remains the app-wide router, but becomes auth-aware

### File Structure

```text
lib/
├── core/
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
└── features/
    └── auth/
        ├── data/
        │   ├── auth_repository_impl.dart
        │   ├── firebase_auth_source.dart
        │   └── onboarding_store.dart
        ├── domain/
        │   ├── entities/
        │   │   └── app_user.dart
        │   ├── failures/
        │   │   └── auth_failure.dart
        │   ├── repositories/
        │   │   └── auth_repository.dart
        │   └── usecases/
        │       ├── check_email_verified.dart
        │       ├── send_email_verification.dart
        │       ├── sign_in_with_email.dart
        │       ├── sign_in_with_google.dart
        │       ├── sign_out.dart
        │       └── sign_up_with_email.dart
        └── presentation/
            ├── providers/
            │   └── auth_providers.dart
            ├── screens/
            │   ├── login_screen.dart
            │   ├── onboarding_screen.dart
            │   └── register_screen.dart
            └── widgets/
                ├── auth_form.dart
                ├── email_verification_banner.dart
                └── social_login_button.dart
```

---

## Dependency Additions

The auth phase needs a few packages that are not part of the current foundation:

- `google_sign_in` for Google OAuth
- `shared_preferences` for the onboarding-complete flag
- `fpdart` for `Either<Failure, T>`
- `firebase_auth_mocks` for unit and widget tests

No new navigation or state-management package is required.

---

## Domain Design

### `AppUser`

`AppUser` is a Freezed value object and the single domain representation of the
authenticated user.

```dart
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
    required bool emailVerified,
    required UserTier tier,
    required DateTime createdAt,
  }) = _AppUser;
}
```

Design decisions:

- `UserTier` reuses the existing enum from `core/database/type_converters.dart`
- `emailVerified` is part of the domain entity so router and UI rules stay simple
- JSON support is generated so round-trip tests can be written against `toJson` and `fromJson`

### `AuthFailure`

Auth errors should not leak raw Firebase exceptions into presentation code.
`AuthFailure` is modeled as a sealed union with variants such as:

- `cancelled`
- `invalidCredentials`
- `emailAlreadyInUse`
- `network`
- `server`
- `unknown`

Each variant exposes a user-facing message so screens can render copy without
switching on Firebase exception codes.

### `AuthRepository`

The repository contract returns `Future<Either<AuthFailure, T>>` for mutating
operations and exposes a `Stream<AppUser?> authStateChanges` for reactive session
updates.

The domain API is:

- `signInWithGoogle()`
- `signInWithEmail(String email, String password)`
- `signUpWithEmail(String email, String password, String displayName)`
- `signOut()`
- `sendEmailVerification()`
- `checkEmailVerified()`
- `Stream<AppUser?> authStateChanges`

Use cases are thin wrappers over the repository because the business rules are
small but still need isolated unit tests.

---

## Data Layer Design

### `FirebaseAuthSource`

`FirebaseAuthSource` is the only class that talks directly to Firebase Auth and
Google Sign-In.

Responsibilities:

- start Google OAuth via `GoogleSignIn`
- call `signInWithEmailAndPassword`
- call `createUserWithEmailAndPassword`
- send verification emails
- reload the current Firebase user
- expose `FirebaseAuth.instance.authStateChanges()`
- sign out from both Google and Firebase

This class returns Firebase-native objects internally. It does not know about
Riverpod, widgets, or routing.

### Local Cache Strategy

The repository writes authenticated user data into the existing `UserProfiles`
Drift table. This keeps offline relaunch possible without introducing a second
profile store.

Mapping rules:

- Google sign-in always writes `emailVerified = true`
- email/password registration writes `emailVerified = false`
- sign-in updates existing rows rather than assuming inserts only
- `createdAt` falls back to the existing cached value if present, otherwise the
  Firebase creation time, otherwise `DateTime.now()`

The repository performs direct reads/writes through `AppDatabase.userProfiles`
instead of adding a new core DAO, because this cache is auth-specific and the
queries are narrow.

### `AuthRepositoryImpl`

`AuthRepositoryImpl` composes:

- `FirebaseAuthSource`
- `AppDatabase`
- `Connectivity` signal from the existing provider graph

Responsibilities:

1. map Firebase users to `AppUser`
2. upsert the `UserProfiles` cache on successful auth events
3. serve cached profile data when Firebase has a valid persisted session
4. convert Firebase exceptions into `AuthFailure`
5. update `emailVerified` in Drift after reload confirms verification

#### Auth state flow

```text
FirebaseAuth.authStateChanges()
  -> AuthRepositoryImpl
  -> upsert/read UserProfiles cache
  -> emit AppUser? stream
  -> Riverpod provider
  -> GoRouter redirect + UI
```

The stream remains repository-owned so both the router and presentation layer use
the same source of truth.

---

## Onboarding Design

### Persistence

`OnboardingStore` wraps `SharedPreferences` with a single boolean key:

- `has_completed_onboarding`

API:

- `Future<bool> hasCompletedOnboarding()`
- `Future<void> markCompleted()`

### Screen Behavior

`OnboardingScreen` is a 3-page `PageView` with:

- slide 1: match diary value
- slide 2: betting tracker value
- slide 3: social/groups value

Actions:

- `Skip` marks onboarding complete and routes to `/login`
- `Get Started` on the last slide does the same

The onboarding state is checked during router bootstrap, not after the login
screen loads, so first-launch navigation is deterministic.

---

## Presentation Design

### Providers

`auth_providers.dart` exposes:

- `firebaseAuthSourceProvider`
- `authRepositoryProvider`
- `authStateProvider`
- `signInWithGoogleProvider`
- `signInWithEmailProvider`
- `signUpWithEmailProvider`
- `signOutProvider`
- `sendEmailVerificationProvider`
- `checkEmailVerifiedProvider`
- `onboardingStoreProvider`

`authStateProvider` is a `StreamProvider<AppUser?>`.

Mutating flows are triggered through an `AuthController` implemented as an
`AsyncNotifier<void>` or a small dedicated notifier family. The design goal is:

- one loading state source per screen
- no direct Firebase calls from widgets
- no repository construction inside widgets

### Screens

#### `LoginScreen`

Contains:

- Google sign-in button
- email field
- password field
- sign-in submit button
- CTA to registration

Rules:

- validation uses the existing shared validators where possible
- controls are disabled during submission
- cancelled Google flows return to idle with no error banner

#### `RegisterScreen`

Contains:

- display name field
- email field
- password field
- confirm password field
- register submit button

Rules:

- password must be at least 8 characters
- confirm password must match
- successful registration routes to `/diary`

#### `EmailVerificationBanner`

This banner renders inside authenticated diary-accessible screens for users whose
`emailVerified` is `false`.

Placement:

- shown at the top of diary-safe screens, not on login/register

Behavior:

- includes `Resend email`
- disappears reactively once the cached `AppUser.emailVerified` becomes `true`

---

## Router Design

### Route Additions

The current router must be extended with:

- `/onboarding`
- `/login`
- `/register`

### Router Construction

The current static router in `core/router/app_router.dart` is sufficient for
placeholders, but auth redirects need Riverpod state and refresh triggers.

The router should therefore be refactored into a provider-backed factory:

```dart
final appRouterProvider = Provider<GoRouter>((ref) { ... });
```

`MatchLogApp` becomes a `ConsumerWidget` and reads the router from Riverpod.

### Redirect Rules

Inputs:

- current location
- current `AsyncValue<AppUser?>`
- onboarding-complete flag

Rules:

1. first launch without onboarding complete -> `/onboarding`
2. unauthenticated users can access only `/login`, `/register`, `/onboarding`
3. authenticated users visiting `/login` or `/register` -> `/diary`
4. authenticated but unverified users may access diary-safe routes
5. authenticated but unverified users hitting social-gated routes -> `/diary`

### Refresh Mechanism

The router uses a refresh bridge tied to `authStateProvider` and onboarding state
changes so redirects re-evaluate immediately after sign-in, sign-out, and
onboarding completion.

---

## Email Verification Refresh

Verification state should refresh when the app returns to the foreground.

Implementation approach:

- attach an `AppLifecycleListener` or `WidgetsBindingObserver`
- on `resumed`, call `checkEmailVerified()`
- if Firebase now reports `emailVerified = true`, update `UserProfiles`
- the auth stream emits a fresh `AppUser`, causing the banner to disappear

This avoids polling while still handling the common “opened inbox, clicked
verify, returned to app” flow.

---

## Validation and UX Rules

- reuse `Validators.email` for email fields
- add a password validator in the auth feature or shared validators
- use generic inline validation before any Firebase call
- map `wrong-password` and `user-not-found` to one message:
  `Incorrect email or password.`
- map `email-already-in-use` to:
  `An account with this email already exists.`

Google cancellation is not treated as an error state.

---

## Testing Strategy

### Unit Tests

- `AppUser` JSON round-trip
- each auth use case with a mocked `AuthRepository`
- `AuthRepositoryImpl` success/failure mapping
- onboarding store read/write behavior

### Widget Tests

- `LoginScreen` validation
- loading state disables controls
- Google button triggers controller call
- `RegisterScreen` confirm-password validation
- `EmailVerificationBanner` renders and hides correctly

### Integration Concerns

Mock Firebase auth in unit and widget tests with `firebase_auth_mocks`.
No real Firebase project calls should occur in automated tests.

---

## Open Implementation Notes

- The canonical spec for implementation should be `.kiro/specs/user-auth/`
- The older `.kiro/specs/auth/` folder should not be used as the implementation source of truth
- `pubspec.yaml` and router structure need small preparatory changes before screen work starts
