library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_entry.freezed.dart';
part 'match_entry.g.dart';

@freezed
class MatchEntry with _$MatchEntry {
  const factory MatchEntry({
    required String id,
    required String userId,
    required String sport,
    required String fixtureId,
    required String homeTeam,
    String? awayTeam,
    required String score,
    required String league,
    required String watchType,
    required int rating,
    String? review,
    @Default([]) List<String> photos,
    String? venue,
    @Default({}) Map<String, dynamic> sportMetadata,
    @Default(false) bool geoVerified,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MatchEntry;

  factory MatchEntry.fromJson(Map<String, dynamic> json) =>
      _$MatchEntryFromJson(json);
}
