library;

import 'package:fpdart/fpdart.dart';
import '../entities/app_user.dart';
import '../failures/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository _repository;

  const SignUpWithEmail(this._repository);

  Future<Either<AuthFailure, AppUser>> call(
    String email,
    String password,
    String displayName,
  ) {
    return _repository.signUpWithEmail(email, password, displayName);
  }
}
