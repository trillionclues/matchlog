library;

import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../failures/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository _repository;

  const SignInWithEmail(this._repository);

  Future<Either<AuthFailure, AppUser>> call(
    String email,
    String password,
  ) {
    return _repository.signInWithEmail(email, password);
  }
}
