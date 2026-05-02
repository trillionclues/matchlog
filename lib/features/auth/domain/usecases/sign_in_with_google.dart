library;

import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../failures/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository _repository;

  const SignInWithGoogle(this._repository);

  Future<Either<AuthFailure, AppUser>> call() {
    return _repository.signInWithGoogle();
  }
}
