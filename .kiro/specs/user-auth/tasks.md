# Implementation Tasks: User Auth

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/user-auth/` as the canonical auth spec for implementation
  - [ ] 1.2 Update `pubspec.yaml` to add `google_sign_in`, `shared_preferences`, `fpdart`, and `firebase_auth_mocks`
  - [ ] 1.3 Run dependency resolution and code generation after adding new packages

- [ ] 2. Router and app bootstrap updates
  - [ ] 2.1 Update `lib/core/router/routes.dart` to add `/onboarding`, `/login`, and `/register`
  - [ ] 2.2 Refactor `lib/core/router/app_router.dart` to use a Riverpod-backed `GoRouter` so redirects can react to auth state
  - [ ] 2.3 Update `lib/app.dart` to consume the router from Riverpod instead of a static singleton
  - [ ] 2.4 Add onboarding-aware and auth-aware redirect rules for protected routes and social-gated routes

- [ ] 3. Auth domain layer
  - [ ] 3.1 Implement `lib/features/auth/domain/entities/app_user.dart` as a Freezed model with JSON support
  - [ ] 3.2 Implement `lib/features/auth/domain/failures/auth_failure.dart`
  - [ ] 3.3 Implement `lib/features/auth/domain/repositories/auth_repository.dart`
  - [ ] 3.4 Implement use cases for Google sign-in, email sign-in, email sign-up, sign-out, send verification email, and check verification status

- [ ] 4. Auth data layer
  - [ ] 4.1 Implement `lib/features/auth/data/firebase_auth_source.dart` for Firebase Auth and Google Sign-In operations
  - [ ] 4.2 Implement `lib/features/auth/data/onboarding_store.dart` for the onboarding-complete flag in SharedPreferences
  - [ ] 4.3 Implement `lib/features/auth/data/auth_repository_impl.dart` to map Firebase users into `AppUser` and upsert the Drift `UserProfiles` cache
  - [ ] 4.4 Implement failure mapping from Firebase exception codes to domain-level `AuthFailure`
  - [ ] 4.5 Implement email verification refresh logic that updates the local cache after app resume

- [ ] 5. Presentation providers and controllers
  - [ ] 5.1 Implement `lib/features/auth/presentation/providers/auth_providers.dart`
  - [ ] 5.2 Expose `authStateProvider` as a `StreamProvider<AppUser?>`
  - [ ] 5.3 Add controller logic for login, registration, sign-out, resend verification, and onboarding completion

- [ ] 6. Auth screens and widgets
  - [ ] 6.1 Implement `lib/features/auth/presentation/screens/onboarding_screen.dart` with exactly 3 slides
  - [ ] 6.2 Implement `lib/features/auth/presentation/screens/login_screen.dart`
  - [ ] 6.3 Implement `lib/features/auth/presentation/screens/register_screen.dart`
  - [ ] 6.4 Implement `lib/features/auth/presentation/widgets/social_login_button.dart`
  - [ ] 6.5 Implement `lib/features/auth/presentation/widgets/auth_form.dart`
  - [ ] 6.6 Implement `lib/features/auth/presentation/widgets/email_verification_banner.dart`

- [ ] 7. Shared validation and UX refinements
  - [ ] 7.1 Extend validation support for auth-only cases such as password length and confirm-password matching
  - [ ] 7.2 Ensure loading states disable all relevant controls during network submission
  - [ ] 7.3 Ensure cancelled Google sign-in returns to idle without surfacing an error
  - [ ] 7.4 Ensure Firebase auth errors are converted into human-readable messages required by the spec

- [ ] 8. Session persistence and offline behavior
  - [ ] 8.1 Restore authenticated sessions from `FirebaseAuth.instance.authStateChanges()`
  - [ ] 8.2 Merge Firebase user data with cached Drift `UserProfiles` data when building `AppUser`
  - [ ] 8.3 Insert a local profile row when a persisted Firebase session exists without a cached profile
  - [ ] 8.4 Serve cached profile state while offline when a valid persisted session exists

- [ ] 9. Testing
  - [ ] 9.1 Add unit tests for `AppUser` JSON round-trip
  - [ ] 9.2 Add unit tests for all auth use cases using a mocked `AuthRepository`
  - [ ] 9.3 Add repository tests covering Google sign-in, email sign-in, offline cache reads, and email verification updates
  - [ ] 9.4 Add widget tests for `LoginScreen` validation and loading behavior
  - [ ] 9.5 Add widget tests for `RegisterScreen` validation and success flow
  - [ ] 9.6 Add widget tests for onboarding completion and email verification banner behavior

- [ ] 10. Verification and cleanup
  - [ ] 10.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 10.2 Run `flutter test`
  - [ ] 10.3 Run `flutter analyze`
  - [ ] 10.4 Confirm the app boots into onboarding or login correctly on a clean install and into diary correctly with a persisted session
