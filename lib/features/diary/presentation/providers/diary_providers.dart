// Diary feature Riverpod providers.
// Wires the data layer to the presentation layer.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/daos/match_dao.dart';
import '../../../../core/di/providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/diary_firebase_source.dart';
import '../../data/diary_local_source.dart';
import '../../data/diary_repository_impl.dart';
import '../../domain/entities/match_entry.dart' as domain;
import '../../domain/failures/diary_failure.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../domain/usecases/delete_entry.dart';
import '../../domain/usecases/get_diary_entries.dart';
import '../../domain/usecases/log_match.dart';

// Data sources
final matchDaoProvider = Provider<MatchDao>((ref) {
  return ref.watch(appDatabaseProvider).matchDao;
});

final diaryLocalSourceProvider = Provider<DiaryLocalSource>((ref) {
  return DiaryLocalSource(ref.watch(matchDaoProvider));
});

final diaryFirebaseSourceProvider = Provider<DiaryFirebaseSource>((ref) {
  return DiaryFirebaseSource();
});

// Repository
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepositoryImpl(
    local: ref.watch(diaryLocalSourceProvider),
    remote: ref.watch(diaryFirebaseSourceProvider),
    database: ref.watch(appDatabaseProvider),
    isOnline: () => ref.read(isOnlineProvider),
  );
});

// Use cases
final logMatchUseCaseProvider = Provider<LogMatch>((ref) {
  return LogMatch(ref.watch(diaryRepositoryProvider));
});

final getDiaryEntriesUseCaseProvider = Provider<GetDiaryEntries>((ref) {
  return GetDiaryEntries(ref.watch(diaryRepositoryProvider));
});

final deleteEntryUseCaseProvider = Provider<DeleteEntry>((ref) {
  return DeleteEntry(ref.watch(diaryRepositoryProvider));
});

// Filter state
final diaryFilterProvider = StateProvider<DiaryFilter>((ref) {
  return DiaryFilter.all;
});

// Diary entries stream
final diaryEntriesProvider =
    StreamProvider.autoDispose<List<domain.MatchEntry>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();

  final filter = ref.watch(diaryFilterProvider);
  return ref.watch(getDiaryEntriesUseCaseProvider).watch(
        userId: user.id,
        filter: filter,
      );
});

// Single entry detail
final matchEntryDetailProvider = FutureProvider.autoDispose
    .family<domain.MatchEntry?, String>((ref, entryId) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;

  return ref.watch(diaryRepositoryProvider).getEntryById(
        userId: user.id,
        entryId: entryId,
      );
});

// Log match mutation
final logMatchControllerProvider =
    StateNotifierProvider.autoDispose<LogMatchController, AsyncValue<void>>(
        (ref) {
  return LogMatchController(ref);
});

class LogMatchController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  LogMatchController(this._ref) : super(const AsyncData(null));

  Future<LogMatchResult> submit(domain.MatchEntry entry) async {
    state = const AsyncLoading();
    final result = await _ref.read(logMatchUseCaseProvider).call(entry);
    state = const AsyncData(null);

    return result.match(
      (failure) => LogMatchResult.failure(failure.displayMessage),
      (_) => const LogMatchResult.success(),
    );
  }
}

// Delete entry mutation controller
final deleteEntryControllerProvider =
    StateNotifierProvider<DeleteEntryController, AsyncValue<void>>(
        (ref) {
  return DeleteEntryController(ref);
});

class DeleteEntryController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  DeleteEntryController(this._ref) : super(const AsyncData(null));

  Future<DeleteEntryResult> delete(String entryId) async {
    state = const AsyncLoading();
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = const AsyncData(null);
      return const DeleteEntryResult.failure('Not signed in.');
    }

    final result = await _ref.read(deleteEntryUseCaseProvider).call(
          userId: user.id,
          entryId: entryId,
        );
    state = const AsyncData(null);

    return result.match(
      (failure) => DeleteEntryResult.failure(failure.displayMessage),
      (_) => const DeleteEntryResult.success(),
    );
  }
}

sealed class LogMatchResult {
  const LogMatchResult._();
  const factory LogMatchResult.success() = _LogMatchSuccess;
  const factory LogMatchResult.failure(String message) = _LogMatchFailure;

  bool get isSuccess => this is _LogMatchSuccess;
  String? get message => switch (this) {
        _LogMatchFailure(message: final m) => m,
        _ => null,
      };
}

class _LogMatchSuccess extends LogMatchResult {
  const _LogMatchSuccess() : super._();
}

class _LogMatchFailure extends LogMatchResult {
  @override
  final String message;
  const _LogMatchFailure(this.message) : super._();
}

sealed class DeleteEntryResult {
  const DeleteEntryResult._();
  const factory DeleteEntryResult.success() = _DeleteSuccess;
  const factory DeleteEntryResult.failure(String message) = _DeleteFailure;

  bool get isSuccess => this is _DeleteSuccess;
  String? get message => switch (this) {
        _DeleteFailure(message: final m) => m,
        _ => null,
      };
}

class _DeleteSuccess extends DeleteEntryResult {
  const _DeleteSuccess() : super._();
}

class _DeleteFailure extends DeleteEntryResult {
  @override
  final String message;
  const _DeleteFailure(this.message) : super._();
}
