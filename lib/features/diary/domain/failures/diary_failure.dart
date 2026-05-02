library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_failure.freezed.dart';

@freezed
sealed class DiaryFailure with _$DiaryFailure {
  const factory DiaryFailure.validation([String? message]) = _Validation;
  const factory DiaryFailure.network([String? message]) = _Network;
  const factory DiaryFailure.storage([String? message]) = _Storage;
  const factory DiaryFailure.notFound([String? message]) = _NotFound;
  const factory DiaryFailure.permission([String? message]) = _Permission;
  const factory DiaryFailure.unknown([String? message]) = _Unknown;
}

extension DiaryFailureX on DiaryFailure {
  String get displayMessage => when(
        validation: (m) => m ?? 'Invalid input.',
        network: (m) => m ?? 'Network error. Check your connection.',
        storage: (m) => m ?? 'Could not save data.',
        notFound: (m) => m ?? 'Entry not found.',
        permission: (m) => m ?? 'You don\'t have permission.',
        unknown: (m) => m ?? 'Something went wrong.',
      );
}
