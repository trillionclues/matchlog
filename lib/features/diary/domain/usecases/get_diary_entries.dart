library;

import '../entities/match_entry.dart';
import '../repositories/diary_repository.dart';

class GetDiaryEntries {
  final DiaryRepository _repository;

  const GetDiaryEntries(this._repository);

  Future<List<MatchEntry>> call({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  }) =>
      _repository.getEntries(userId: userId, filter: filter);

  Stream<List<MatchEntry>> watch({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  }) =>
      _repository.watchEntries(userId: userId, filter: filter);
}
