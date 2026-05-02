library;

import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/type_converters.dart';
import '../domain/entities/app_user.dart';
import '../domain/failures/auth_failure.dart';
import '../domain/repositories/auth_repository.dart';
import 'firebase_auth_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthSource _source;
  final AppDatabase _database;
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  StreamSubscription<User?>? _authSubscription;
  AppUser? _currentUser;
  bool _initialized = false;

  AuthRepositoryImpl({
    required FirebaseAuthSource source,
    required AppDatabase database,
  })  : _source = source,
        _database = database {
    _authSubscription = _source.authStateChanges.listen(
      (firebaseUser) async {
        try {
          await _handleAuthStateChanged(firebaseUser);
        } catch (error, stackTrace) {
          _controller.addError(_mapError(error), stackTrace);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _controller.addError(_mapError(error), stackTrace);
      },
    );
  }

  @override
  Stream<AppUser?> get authStateChanges => Stream.multi((multi) {
        if (_initialized) {
          multi.add(_currentUser);
        }

        final subscription = _controller.stream.listen(
          multi.add,
          onError: multi.addError,
          onDone: multi.close,
        );
        multi.onCancel = subscription.cancel;
      });

  @override
  Future<Either<AuthFailure, AppUser>> signInWithGoogle() async {
    try {
      final credential = await _source.signInWithGoogle();
      if (credential == null || credential.user == null) {
        return const Left(AuthFailure.cancelled());
      }

      final appUser = await _upsertAndMapUser(
        credential.user!,
        forceEmailVerified: true,
      );
      _emit(appUser);
      return Right(appUser);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<AuthFailure, AppUser>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final credential = await _source.signInWithEmail(email, password);
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure.unknown());
      }

      final appUser = await _upsertAndMapUser(user);
      _emit(appUser);
      return Right(appUser);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<AuthFailure, AppUser>> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final normalizedEmail = email.trim();
      final signInMethods =
          await _source.fetchSignInMethodsForEmail(normalizedEmail);

      if (signInMethods.contains('google.com') &&
          !signInMethods.contains('password')) {
        return const Left(
          AuthFailure.unknown(
            'This email already uses Google sign-in. Continue with Google, then add a password later from account settings.',
          ),
        );
      }

      final credential = await _source.signUpWithEmail(
        normalizedEmail,
        password,
        displayName,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure.unknown());
      }

      final appUser = await _upsertAndMapUser(
        user,
        forceDisplayName: displayName,
        forceEmailVerified: false,
      );
      _emit(appUser);
      return Right(appUser);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await _source.signOut();
    } catch (_) {
      // Treat device sign-out as complete even if a provider-specific sign-out fails.
    }

    _emit(null);
    return const Right(unit);
  }

  @override
  Future<Either<AuthFailure, Unit>> sendEmailVerification() async {
    try {
      await _source.sendEmailVerification();
      return const Right(unit);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  @override
  Future<Either<AuthFailure, bool>> checkEmailVerified() async {
    try {
      final firebaseUser = await _source.reloadCurrentUser();
      if (firebaseUser == null) {
        _emit(null);
        return const Right(false);
      }

      final appUser = await _upsertAndMapUser(firebaseUser);
      _emit(appUser);
      return Right(appUser.emailVerified);
    } catch (error) {
      return Left(_mapError(error));
    }
  }

  Future<void> _handleAuthStateChanged(User? firebaseUser) async {
    _initialized = true;
    if (firebaseUser == null) {
      _emit(null);
      return;
    }

    final appUser = await _upsertAndMapUser(firebaseUser);
    _emit(appUser);
  }

  Future<AppUser> _upsertAndMapUser(
    User firebaseUser, {
    bool? forceEmailVerified,
    String? forceDisplayName,
  }) async {
    final cachedProfile = await _getCachedProfile(firebaseUser.uid);
    final resolvedDisplayName = forceDisplayName ??
        firebaseUser.displayName ??
        cachedProfile?.displayName ??
        firebaseUser.email?.split('@').first ??
        'MatchLog User';

    final resolvedCreatedAt = cachedProfile?.createdAt ??
        firebaseUser.metadata.creationTime ??
        DateTime.now();

    final emailVerified = forceEmailVerified ??
        (_isGoogleUser(firebaseUser) ||
            firebaseUser.emailVerified ||
            (cachedProfile?.emailVerified ?? false));

    final companion = UserProfilesCompanion(
      userId: Value(firebaseUser.uid),
      displayName: Value(resolvedDisplayName),
      email: Value(firebaseUser.email ?? cachedProfile?.email ?? ''),
      photoUrl: Value(firebaseUser.photoURL ?? cachedProfile?.photoUrl),
      emailVerified: Value(emailVerified),
      tier: Value(cachedProfile?.tier ?? UserTier.free),
      favoriteSport: Value(cachedProfile?.favoriteSport),
      favoriteTeam: Value(cachedProfile?.favoriteTeam),
      followerCount: Value(cachedProfile?.followerCount ?? 0),
      followingCount: Value(cachedProfile?.followingCount ?? 0),
      createdAt: Value(resolvedCreatedAt),
    );

    await _database.into(_database.userProfiles).insertOnConflictUpdate(
          companion,
        );

    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? cachedProfile?.email ?? '',
      displayName: resolvedDisplayName,
      photoUrl: firebaseUser.photoURL ?? cachedProfile?.photoUrl,
      emailVerified: emailVerified,
      tier: cachedProfile?.tier ?? UserTier.free,
      createdAt: resolvedCreatedAt,
    );
  }

  Future<UserProfile?> _getCachedProfile(String userId) {
    return (_database.select(_database.userProfiles)
          ..where((table) => table.userId.equals(userId)))
        .getSingleOrNull();
  }

  bool _isGoogleUser(User user) {
    return user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
  }

  void _emit(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  AuthFailure _mapError(Object error) {
    if (error is AuthFailure) {
      return error;
    }

    if (error is SocketException) {
      return const AuthFailure.network();
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return const AuthFailure.unknown(
            'This email already belongs to another sign-in method. Sign in with that method first, then link the other one later.',
          );
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-credential':
        case 'invalid-email':
          return const AuthFailure.invalidCredentials();
        case 'email-already-in-use':
          return const AuthFailure.emailAlreadyInUse();
        case 'network-request-failed':
          return const AuthFailure.network();
        default:
          return AuthFailure.server(error.code);
      }
    }

    return AuthFailure.unknown(error.toString());
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _controller.close();
  }
}
