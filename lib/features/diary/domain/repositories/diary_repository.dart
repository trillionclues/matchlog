library;

import 'package:fpdart/fpdart.dart';
import '../entities/match_entry.dart';
import '../entities/user_stats.dart';
import '../failures/diary_failure.dart';

enum DiaryFilter { all, stadium, tv, streaming, radio }

abstract interface class DiaryRepository {
  Future<Either<DiaryFailure, Unit>> logMatch(MatchEntry entry);

  Future<List<MatchEntry>> getEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  });

  Stream<List<MatchEntry>> watchEntries({
    required String userId,
    DiaryFilter filter = DiaryFilter.all,
  });

  Future<MatchEntry?> getEntryById({
    required String userId,
    required String entryId,
  });

  Future<Either<DiaryFailure, Unit>> deleteEntry({
    required String userId,
    required String entryId,
  });

  Future<UserStats> calculateStats({required String userId});
}
