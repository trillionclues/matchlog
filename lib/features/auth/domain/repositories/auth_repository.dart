library;

import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../failures/auth_failure.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<Either<AuthFailure, AppUser>> signInWithGoogle();

  Future<Either<AuthFailure, AppUser>> signInWithEmail(
    String email,
    String password,
  );

  Future<Either<AuthFailure, AppUser>> signUpWithEmail(
    String email,
    String password,
    String displayName,
  );

  Future<Either<AuthFailure, Unit>> signOut();

  Future<Either<AuthFailure, Unit>> sendEmailVerification();

  Future<Either<AuthFailure, bool>> checkEmailVerified();
}
