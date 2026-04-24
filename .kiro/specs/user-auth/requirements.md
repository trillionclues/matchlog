# Requirements Document

## Introduction

The Auth feature provides the complete authentication system for MatchLog — a social sports diary and betting tracker. It covers user sign-in via Google OAuth and Email/Password, new account registration, email verification, session persistence across app restarts, and router-level access control via GoRouter redirect guards.

The feature follows Clean Architecture (feature-first): the domain layer is pure Dart with no Firebase or Flutter imports, the data layer implements domain interfaces using Firebase Auth, and the presentation layer uses Riverpod providers. Firebase Auth is the backend for Phase 1–3; the abstract `AuthRepository` interface allows a Spring Boot backend to be swapped in during Phase 4 without touching the presentation layer.

An onboarding carousel is shown on first launch before the login screen. Authenticated users are routed to `/diary`; unauthenticated users are redirected to `/login`. Email/Password users who have not yet verified their email may access core diary routes but see a persistent banner until verification is complete. Auth state is cached locally in the existing `UserProfiles` Drift table so the app works without network on relaunch.

---

## Glossary

- **AppUser**: The domain entity representing an authenticated user. Pure Dart — no Firebase imports. Fields: `id`, `email`, `displayName`, `photoUrl`, `emailVerified`, `tier`, `createdAt`.
- **AuthRepository**: The abstract domain interface declaring all authentication operations. Implemented by `AuthRepositoryImpl` in the data layer.
- **AuthRepositoryImpl**: The data-layer class that wires `FirebaseAuthSource` with the local `UserProfiles` Drift cache to implement `AuthRepository`.
- **FirebaseAuthSource**: The Firebase-backed data source that calls Firebase Auth and `google_sign_in` directly. Lives in the data layer only.
- **UserProfiles**: The existing Drift table (defined in Phase 1) that caches user profile data locally for offline access.
- **AppRouter**: The existing GoRouter instance in `lib/core/router/app_router.dart` that controls all navigation. Auth redirect guards are added to this instance.
- **OnboardingScreen**: A 3-slide carousel shown only on the user's first app launch, before the login screen.
- **LoginScreen**: The screen presenting Google Sign-In and Email/Password sign-in options.
- **RegisterScreen**: The screen for creating a new Email/Password account.
- **EmailVerificationBanner**: A persistent in-app banner shown to Email/Password users whose `emailVerified` is `false`.
- **AuthState**: The Riverpod-managed state representing the current authentication status: `loading`, `authenticated(AppUser)`, `unauthenticated`, or `error(String)`.
- **UserTier**: Enum with values `free`, `pro`, `crew` representing the user's subscription level. New accounts default to `free`.
- **Failure**: A sealed domain class used as the error type in `Either<Failure, T>` return values from `AuthRepository` methods.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want well-defined domain interfaces and entities, so that the auth feature can be tested in isolation and swapped to a different backend in Phase 4 without touching the presentation layer.

#### Acceptance Criteria

1. THE `AppUser` entity SHALL be a Freezed value object with fields: `id` (String), `email` (String), `displayName` (String), `photoUrl` (String?), `emailVerified` (bool), `tier` (UserTier), and `createdAt` (DateTime).
2. THE `AppUser` entity file SHALL contain zero imports from Flutter framework packages, Firebase packages, or Drift — only pure Dart and the `freezed_annotation` package.
3. THE `AuthRepository` interface SHALL declare the following methods: `signInWithGoogle()`, `signInWithEmail(String email, String password)`, `signUpWithEmail(String email, String password, String displayName)`, `signOut()`, `sendEmailVerification()`, `checkEmailVerified()`, and a `Stream<AppUser?> authStateChanges` getter.
4. THE `AuthRepository` methods that perform network operations SHALL return `Future<Either<Failure, T>>` so that callers handle errors without catching exceptions.
5. THE `SignInWithGoogle`, `SignInWithEmail`, `SignUpWithEmail`, `SignOut`, `SendEmailVerification`, and `CheckEmailVerified` use case classes SHALL each accept an `AuthRepository` via constructor injection and expose a single `call()` method.
6. FOR ALL valid `AppUser` instances, serializing to and deserializing from a `Map<String, dynamic>` SHALL produce an equivalent `AppUser` (round-trip property).

---

### Requirement 2: Google Sign-In

**User Story:** As a user, I want to sign in with my Google account, so that I can access MatchLog without creating a separate password.

#### Acceptance Criteria

1. WHEN the user taps the Google Sign-In button on `LoginScreen`, THE `FirebaseAuthSource` SHALL initiate the Google OAuth flow using the `google_sign_in` package.
2. WHEN the Google OAuth flow completes successfully, THE `AuthRepositoryImpl` SHALL upsert the corresponding `UserProfiles` row in the local Drift database with the returned user data and `emailVerified = true`.
3. WHEN Google Sign-In succeeds, THE `AppRouter` SHALL redirect the user to `/diary`.
4. IF the user cancels the Google OAuth flow, THEN THE `LoginScreen` SHALL return to its idle state without displaying an error message.
5. IF the Google Sign-In flow fails due to a network or Firebase error, THEN THE `LoginScreen` SHALL display a human-readable error message derived from the `Failure` type.
6. WHILE a Google Sign-In request is in progress, THE `LoginScreen` SHALL display a loading indicator and disable all interactive controls.

---

### Requirement 3: Email/Password Sign-In

**User Story:** As a user, I want to sign in with my email and password, so that I can access MatchLog using credentials I control.

#### Acceptance Criteria

1. WHEN the user submits the sign-in form on `LoginScreen` with a valid email and non-empty password, THE `FirebaseAuthSource` SHALL call `signInWithEmailAndPassword` on Firebase Auth.
2. WHEN Email/Password sign-in succeeds, THE `AuthRepositoryImpl` SHALL upsert the `UserProfiles` row in the local Drift database with the latest user data.
3. WHEN Email/Password sign-in succeeds, THE `AppRouter` SHALL redirect the user to `/diary`.
4. IF the user submits the sign-in form with an empty email field, THEN THE `LoginScreen` SHALL display a field-level validation error before making any network call.
5. IF the user submits the sign-in form with an invalid email format, THEN THE `LoginScreen` SHALL display a field-level validation error before making any network call.
6. IF the user submits the sign-in form with an empty password field, THEN THE `LoginScreen` SHALL display a field-level validation error before making any network call.
7. IF Firebase Auth returns a wrong-password or user-not-found error, THEN THE `LoginScreen` SHALL display the message "Incorrect email or password."
8. WHILE a sign-in network request is in progress, THE `LoginScreen` SHALL display a loading indicator and disable the submit button.

---

### Requirement 4: Email/Password Registration

**User Story:** As a new user, I want to create an account with my email and password, so that I can start using MatchLog.

#### Acceptance Criteria

1. WHEN the user submits the registration form on `RegisterScreen` with a valid email, a display name, and a password of at least 8 characters, THE `FirebaseAuthSource` SHALL call `createUserWithEmailAndPassword` on Firebase Auth.
2. WHEN account creation succeeds, THE `FirebaseAuthSource` SHALL immediately call `sendEmailVerification()` on the newly created Firebase user.
3. WHEN account creation succeeds, THE `AuthRepositoryImpl` SHALL insert a new `UserProfiles` row in the local Drift database with `emailVerified = false` and `tier = UserTier.free`.
4. WHEN registration succeeds, THE `AppRouter` SHALL redirect the user to `/diary`.
5. IF the user submits the registration form with a password shorter than 8 characters, THEN THE `RegisterScreen` SHALL display a field-level validation error before making any network call.
6. IF the user submits the registration form with a password that does not match the confirm-password field, THEN THE `RegisterScreen` SHALL display a field-level validation error before making any network call.
7. IF Firebase Auth returns an email-already-in-use error, THEN THE `RegisterScreen` SHALL display the message "An account with this email already exists."
8. WHILE a registration network request is in progress, THE `RegisterScreen` SHALL display a loading indicator and disable the submit button.

---

### Requirement 5: Email Verification

**User Story:** As an Email/Password user, I want to verify my email address, so that I can unlock social features and confirm my account is legitimate.

#### Acceptance Criteria

1. WHEN an authenticated Email/Password user has `emailVerified == false`, THE `LoginScreen` SHALL display a persistent `EmailVerificationBanner` with a "Resend email" action.
2. WHEN the user taps "Resend email" on the `EmailVerificationBanner`, THE `FirebaseAuthSource` SHALL call `sendEmailVerification()` on the current Firebase user.
3. WHEN the app resumes from background, THE `FirebaseAuthSource` SHALL call `currentUser.reload()` to refresh the email verification status from Firebase.
4. WHEN `currentUser.reload()` returns `emailVerified == true`, THE `AuthRepositoryImpl` SHALL update the `emailVerified` column in the `UserProfiles` Drift table to `true`.
5. WHEN the `UserProfiles` row is updated to `emailVerified == true`, THE `EmailVerificationBanner` SHALL be dismissed reactively without requiring a manual app restart.
6. WHEN a Google-authenticated user signs in, THE `AuthRepositoryImpl` SHALL always write `emailVerified = true` to the `UserProfiles` row, regardless of the Firebase `emailVerified` field value.

---

### Requirement 6: Sign-Out

**User Story:** As an authenticated user, I want to sign out of my account, so that my session is cleared from the device.

#### Acceptance Criteria

1. WHEN the user triggers sign-out, THE `FirebaseAuthSource` SHALL call `GoogleSignIn().signOut()` followed by `FirebaseAuth.instance.signOut()`.
2. WHEN sign-out completes, THE `AppRouter` SHALL redirect the user to `/login`.
3. WHEN sign-out completes, THE `AuthRepositoryImpl` SHALL clear the current user from the in-memory auth state stream.
4. IF sign-out fails due to a network error, THEN THE `AuthRepositoryImpl` SHALL still clear the local auth state and redirect to `/login`, treating the session as terminated on-device.

---

### Requirement 7: Auth State Persistence

**User Story:** As a returning user, I want my session to persist across app restarts, so that I do not have to sign in every time I open the app.

#### Acceptance Criteria

1. THE `FirebaseAuthSource` SHALL expose an `authStateChanges` stream sourced from `FirebaseAuth.instance.authStateChanges()`.
2. WHEN the app starts and Firebase Auth has a persisted session, THE `AuthRepositoryImpl` SHALL emit an authenticated `AppUser` to the auth state stream without requiring the user to sign in again.
3. WHEN the app starts and no persisted session exists, THE `AuthRepositoryImpl` SHALL emit `null` (unauthenticated) to the auth state stream.
4. WHEN the auth state stream emits a non-null Firebase user, THE `AuthRepositoryImpl` SHALL read the corresponding `UserProfiles` row from Drift and merge it with the Firebase user data to construct the `AppUser`.
5. IF no `UserProfiles` row exists for the authenticated Firebase user, THEN THE `AuthRepositoryImpl` SHALL insert a new row using the Firebase user's data before emitting the `AppUser`.

---

### Requirement 8: Offline Profile Access

**User Story:** As a user in an area with no connectivity, I want the app to remember who I am, so that I can still access my diary without re-authenticating.

#### Acceptance Criteria

1. WHILE the device has no network connectivity and a valid Firebase Auth session token exists, THE `AuthRepositoryImpl` SHALL serve the `AppUser` from the local `UserProfiles` Drift cache.
2. WHEN connectivity is restored, THE `AuthRepositoryImpl` SHALL refresh the `UserProfiles` row from Firebase Auth and update the local cache with any changed fields.
3. THE `AppUser` served from the local cache SHALL include the `emailVerified` value last written to the `UserProfiles` table.

---

### Requirement 9: Router Access Control

**User Story:** As the app, I want to enforce authentication at the router level, so that unauthenticated users cannot access protected screens.

#### Acceptance Criteria

1. WHEN an unauthenticated user attempts to navigate to any route other than `/login`, `/register`, or `/onboarding`, THE `AppRouter` SHALL redirect the user to `/login`.
2. WHEN an authenticated user navigates to `/login` or `/register`, THE `AppRouter` SHALL redirect the user to `/diary`.
3. WHEN an authenticated user with `emailVerified == false` navigates to any core diary route (`/diary`, `/diary/log`, `/diary/:id`, `/stats`, `/profile`, `/settings`), THE `AppRouter` SHALL allow navigation.
4. WHEN an authenticated user with `emailVerified == false` navigates to a social-gated route (`/feed`, `/groups`, `/groups/:groupId`, `/groups/join/:code`), THE `AppRouter` SHALL redirect the user to `/diary`.
5. THE `AppRouter` redirect guard SHALL be driven by the Riverpod `authStateChanges` stream so that route changes are reactive to sign-in and sign-out events without requiring a manual refresh.

---

### Requirement 10: Onboarding Flow

**User Story:** As a first-time user, I want to see an onboarding carousel before the login screen, so that I understand what MatchLog offers before creating an account.

#### Acceptance Criteria

1. WHEN the app is launched for the first time (no prior session and no onboarding-complete flag in `shared_preferences`), THE `AppRouter` SHALL route the user to `/onboarding` before `/login`.
2. THE `OnboardingScreen` SHALL display exactly 3 slides with distinct content describing core MatchLog features: match diary, betting tracker, and social/groups.
3. WHEN the user swipes through all 3 slides and taps "Get Started", THE `OnboardingScreen` SHALL navigate to `/login` and persist an onboarding-complete flag so the carousel is not shown again.
4. WHEN the user taps "Skip" on any onboarding slide, THE `OnboardingScreen` SHALL navigate directly to `/login` and persist the onboarding-complete flag.
5. WHEN the app is launched on a device where the onboarding-complete flag is already set, THE `AppRouter` SHALL not route to `/onboarding`.

---

### Requirement 11: Presentation Layer — Auth Providers

**User Story:** As a developer, I want Riverpod providers that expose auth state to the widget tree, so that any screen can reactively respond to sign-in and sign-out without manual subscriptions.

#### Acceptance Criteria

1. THE `authStateProvider` SHALL be a `StreamProvider<AppUser?>` that watches `AuthRepository.authStateChanges` and emits the current user or `null`.
2. THE `authRepositoryProvider` SHALL be a `Provider<AuthRepository>` that returns the active `AuthRepositoryImpl` instance, wired to `FirebaseAuthSource` and the `AppDatabase` from `appDatabaseProvider`.
3. WHEN `authStateProvider` emits a new value, THE `AppRouter` redirect guard SHALL re-evaluate and navigate to the correct route without requiring a widget rebuild trigger.
4. THE `auth_providers.dart` file SHALL expose providers for each use case: `signInWithGoogleProvider`, `signInWithEmailProvider`, `signUpWithEmailProvider`, `signOutProvider`, `sendEmailVerificationProvider`, and `checkEmailVerifiedProvider`.

---

### Requirement 12: Testing

**User Story:** As a developer, I want comprehensive tests for the auth feature, so that regressions are caught before they reach production.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for each use case class: `SignInWithGoogle`, `SignInWithEmail`, `SignUpWithEmail`, `SignOut`, `SendEmailVerification`, and `CheckEmailVerified`, using a mocked `AuthRepository`.
2. THE test suite SHALL include unit tests for `AuthRepositoryImpl` covering: the online Google sign-in path, the online Email/Password sign-in path, the offline cache-read path, and the email verification update path.
3. THE test suite SHALL include widget tests for `LoginScreen` verifying: the screen renders correctly, form validation fires before network calls, and a loading indicator appears during sign-in.
4. ALL tests SHALL mock `FirebaseAuth` using `firebase_auth_mocks` or an equivalent mock package — no real Firebase calls SHALL be made in unit or widget tests.
5. FOR ALL valid `AppUser` instances, serializing to and deserializing from a `Map<String, dynamic>` SHALL produce an equivalent `AppUser` (round-trip property).
