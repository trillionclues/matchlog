// single entry point for flipping geoVerified to true on a MatchEntry.
// Always passes geoVerified: true — this use case is only ever called
// after explicit user confirmation in the Stadium Check-In flow.

library;

import 'package:fpdart/fpdart.dart';
import '../failures/diary_failure.dart';
import '../repositories/diary_repository.dart';

class UpdateGeoVerified {
  final DiaryRepository _repository;

  const UpdateGeoVerified(this._repository);

  // Marks entry identified by [entryId] as geo-verified.
  Future<Either<DiaryFailure, Unit>> call({
    required String userId,
    required String entryId,
  }) {
    return _repository.updateGeoVerified(
      userId: userId,
      entryId: entryId,
      geoVerified: true,
    );
  }
}
