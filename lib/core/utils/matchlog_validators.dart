library;

class MatchLogValidators {
  MatchLogValidators._();

  // Covers: 2-1, 2:1, 110-98, 6-4 7-5, P1: VER (F1 custom)
  static final _scorePattern = RegExp(r'^[\w\s][\w\s:–\-]+$');

  static String? teamName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Required';
    if (s.length < 2) return 'Too short';
    if (s.length > 60) return 'Too long';
    if (RegExp(r'^\d+$').hasMatch(s)) return 'Enter a team name';
    return null;
  }

  static String? optionalTeamName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    if (s.length < 2) return 'Too short';
    if (s.length > 60) return 'Too long';
    if (RegExp(r'^\d+$').hasMatch(s)) return 'Enter a team name';
    return null;
  }

  static String? score(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Required';
    if (s.length > 30) return 'Too long';
    if (!_scorePattern.hasMatch(s)) return 'Use a format like 2-1 or 6-4 7-5';
    return null;
  }

  static String? league(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Required';
    if (s.length < 2) return 'Too short';
    if (s.length > 80) return 'Too long';
    return null;
  }

  static String? optionalVenue(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    if (s.length > 100) return 'Too long';
    return null;
  }

  static String? optionalReview(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    if (s.length > 1000) return 'Keep it under 1000 characters';
    return null;
  }
}