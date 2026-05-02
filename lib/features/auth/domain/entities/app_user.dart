library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/database/type_converters.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
    required bool emailVerified,
    required UserTier tier,
    required DateTime createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
