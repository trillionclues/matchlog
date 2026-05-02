library;

import 'package:fpdart/fpdart.dart';
import '../failures/diary_failure.dart';
import '../repositories/diary_repository.dart';

class DeleteEntry {
  final DiaryRepository _repository;

  const DeleteEntry(this._repository);

  Future<Either<DiaryFailure, Unit>> call({
    required String userId,
    required String entryId,
  }) =>
      _repository.deleteEntry(userId: userId, entryId: entryId);
}
