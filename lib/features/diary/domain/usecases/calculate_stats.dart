library;

import '../entities/user_stats.dart';
import '../repositories/diary_repository.dart';

class CalculateStats {
  final DiaryRepository _repository;

  const CalculateStats(this._repository);

  Future<UserStats> call({required String userId}) =>
      _repository.calculateStats(userId: userId);
}
