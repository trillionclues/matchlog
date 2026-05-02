library;

import 'package:fpdart/fpdart.dart';
import '../entities/match_entry.dart';
import '../failures/diary_failure.dart';
import '../repositories/diary_repository.dart';

class LogMatch {
  final DiaryRepository _repository;

  const LogMatch(this._repository);

  Future<Either<DiaryFailure, Unit>> call(MatchEntry entry) =>
      _repository.logMatch(entry);
}
