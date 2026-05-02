library;

import 'package:fpdart/fpdart.dart';
import '../failures/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SendEmailVerification {
  final AuthRepository _repository;

  const SendEmailVerification(this._repository);

  Future<Either<AuthFailure, Unit>> call() {
    return _repository.sendEmailVerification();
  }
}
