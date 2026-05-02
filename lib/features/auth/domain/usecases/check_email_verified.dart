library;

import 'package:fpdart/fpdart.dart';
import '../failures/auth_failure.dart';
import '../repositories/auth_repository.dart';

class CheckEmailVerified {
  final AuthRepository _repository;

  const CheckEmailVerified(this._repository);

  Future<Either<AuthFailure, bool>> call() {
    return _repository.checkEmailVerified();
  }
}
