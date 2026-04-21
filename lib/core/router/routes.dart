// Named route string constants.

library;

abstract class Routes {
  Routes._();
  static const String home = '/';

  static const String diary = '/diary';

  static const String logMatch = '/diary/log';

  static const String matchDetail = '/diary/:id';

  static const String betting = '/betting';

  static const String logBet = '/betting/log';

  // ROI charts, win rate, breakdowns
  static const String stats = '/stats';

  static const String profile = '/profile';

  // (notifications, privacy, account)
  static const String settings = '/settings';

  static const String feed = '/feed';

  static const String userProfile = '/profile/:userId';

  // Bookie Groups
  static const String groups = '/groups';

  static const String groupDetail = '/groups/:groupId';

  static const String createGroup = '/groups/create';

  // Join group via invite code (deep link landing)
  static const String joinGroup = '/groups/join/:code';

 static const String aiInsights = '/insights';

  static const String yearInReview = '/review';

  static const String subscription = '/subscription';

  
  // Build [matchDetail] path with a specific entry ID.
  static String matchDetailPath(String id) => '/diary/$id';

  // Build [userProfile] path with a specific user ID.
  static String userProfilePath(String userId) => '/profile/$userId';

  // Build [groupDetail] path with a specific group ID.
  static String groupDetailPath(String groupId) => '/groups/$groupId';

  // Build [joinGroup] path with an invite code.
  static String joinGroupPath(String code) => '/groups/join/$code';
}
