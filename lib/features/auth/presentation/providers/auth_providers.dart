library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/di/providers.dart';
import '../../data/auth_repository_impl.dart';
import '../../data/firebase_auth_source.dart';
import '../../data/onboarding_store.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_email_verified.dart';
import '../../domain/usecases/send_email_verification.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn(),
);

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => const OnboardingStore(),
);

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  return ref.watch(onboardingStoreProvider).hasCompletedOnboarding();
});

final firebaseAuthSourceProvider = Provider<FirebaseAuthSource>((ref) {
  return FirebaseAuthSource(
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final repository = AuthRepositoryImpl(
    source: ref.watch(firebaseAuthSourceProvider),
    database: database,
  );

  ref.onDispose(() {
    repository.dispose();
  });
  return repository;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

final signInWithEmailProvider = Provider<SignInWithEmail>((ref) {
  return SignInWithEmail(ref.watch(authRepositoryProvider));
});

final signUpWithEmailProvider = Provider<SignUpWithEmail>((ref) {
  return SignUpWithEmail(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

final sendEmailVerificationProvider = Provider<SendEmailVerification>((ref) {
  return SendEmailVerification(ref.watch(authRepositoryProvider));
});

final checkEmailVerifiedProvider = Provider<CheckEmailVerified>((ref) {
  return CheckEmailVerified(ref.watch(authRepositoryProvider));
});

final authControllerProvider =
    StateNotifierProvider.autoDispose<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

@immutable
class AuthActionResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? message;

  const AuthActionResult._({
    required this.isSuccess,
    required this.isCancelled,
    this.message,
  });

  const AuthActionResult.success()
      : this._(isSuccess: true, isCancelled: false);
  const AuthActionResult.cancelled()
      : this._(isSuccess: false, isCancelled: true);
  const AuthActionResult.failure(String message)
      : this._(isSuccess: false, isCancelled: false, message: message);
}

class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncData(null));

  Future<AuthActionResult> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await _ref.read(signInWithGoogleProvider).call();
    state = const AsyncData(null);
    return result.match(_mapFailure, (_) => const AuthActionResult.success());
  }

  Future<AuthActionResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result =
        await _ref.read(signInWithEmailProvider).call(email, password);
    state = const AsyncData(null);
    return result.match(_mapFailure, (_) => const AuthActionResult.success());
  }

  Future<AuthActionResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final result = await _ref.read(signUpWithEmailProvider).call(
          email,
          password,
          displayName,
        );
    state = const AsyncData(null);
    return result.match(_mapFailure, (_) => const AuthActionResult.success());
  }

  Future<AuthActionResult> signOut() async {
    state = const AsyncLoading();
    final result = await _ref.read(signOutProvider).call();
    state = const AsyncData(null);
    return result.match(_mapFailure, (_) => const AuthActionResult.success());
  }

  Future<AuthActionResult> resendVerificationEmail() async {
    state = const AsyncLoading();
    final result = await _ref.read(sendEmailVerificationProvider).call();
    state = const AsyncData(null);
    return result.match(_mapFailure, (_) => const AuthActionResult.success());
  }

  Future<void> completeOnboarding() async {
    state = const AsyncLoading();
    await _ref.read(onboardingStoreProvider).markCompleted();
    _ref.invalidate(onboardingCompletedProvider);
    state = const AsyncData(null);
  }

  Future<void> resetOnboarding() async {
    state = const AsyncLoading();
    await _ref.read(onboardingStoreProvider).reset();
    _ref.invalidate(onboardingCompletedProvider);
    state = const AsyncData(null);
  }

  AuthActionResult _mapFailure(AuthFailure failure) {
    return failure.map(
      cancelled: (_) => const AuthActionResult.cancelled(),
      invalidCredentials: (_) =>
          const AuthActionResult.failure('Incorrect email or password.'),
      emailAlreadyInUse: (_) => const AuthActionResult.failure(
        'An account with this email already exists.',
      ),
      network: (_) => const AuthActionResult.failure(
        'A network error occurred. Check your connection and try again.',
      ),
      server: (_) => const AuthActionResult.failure(
          'Authentication failed. Please try again.'),
      unknown: (value) => AuthActionResult.failure(
        value.message ?? 'Something went wrong. Please try again.',
      ),
    );
  }
}
