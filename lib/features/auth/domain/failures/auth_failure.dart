library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_failure.freezed.dart';

@freezed
class AuthFailure with _$AuthFailure {
  const factory AuthFailure.cancelled() = _Cancelled;
  const factory AuthFailure.invalidCredentials() = _InvalidCredentials;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.network() = _Network;
  const factory AuthFailure.server([String? code]) = _Server;
  const factory AuthFailure.unknown([String? message]) = _Unknown;
}

extension AuthFailureMessage on AuthFailure {
  String get message {
    return map(
      cancelled: (_) => '',
      invalidCredentials: (_) => 'Incorrect email or password.',
      emailAlreadyInUse: (_) => 'An account with this email already exists.',
      network: (_) =>
          'A network error occurred. Check your connection and try again.',
      server: (_) => 'Authentication failed. Please try again.',
      unknown: (failure) =>
          failure.message ?? 'Something went wrong. Please try again.',
    );
  }
}
