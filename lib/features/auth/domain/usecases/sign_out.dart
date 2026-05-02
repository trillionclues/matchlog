library;

import 'package:fpdart/fpdart.dart';
import '../failures/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repository;

  const SignOut(this._repository);

  Future<Either<AuthFailure, Unit>> call() {
    return _repository.signOut();
  }
}
