// Dart extension methods on common types.
// Usage:
//   'hello world'.capitalize()     → 'Hello world'
//   '  '.isNullOrEmpty             → true
//   1500.0.toCurrency('NGN')       → '₦1,500.00'
//   DateTime.now().isToday         → true
//   someDate.toRelativeString()    → 'Yesterday'

library;

import 'formatters.dart';

// String Extensions
extension StringExtensions on String {
  // True when the string is empty after trimming.
  bool get isBlank => trim().isEmpty;

  // True when the string has content after trimming.
  bool get isNotBlank => trim().isNotEmpty;

  // Returns the string with the first character uppercased.
  // 'hello world' → 'Hello world'
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Returns string with each word capitalized.
  // 'hello world' → 'Hello World'
  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Truncates string to [maxLength] and appends '...' if truncated.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

extension NullableStringExtensions on String? {
  // True when the string is null or empty after trimming.
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  // True when the string is not null and has content after trimming.
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  // Returns the string or a fallback if null/empty.
  String orDefault(String fallback) =>
      isNullOrEmpty ? fallback : this!;
}

// Num Extensions
extension NumExtensions on num {
  // Format as currency string.
  // 1500.0.toCurrency('NGN') → '₦1,500.00'
  String toCurrency(String currency) =>
      CurrencyFormatter.format(toDouble(), currency);

  // Format as decimal odds string.
  // 2.1.toOdds() → '2.10'
  String toOdds() => OddsFormatter.format(toDouble());

  // True when this number represents a positive ROI.
  bool get isPositiveRoi => this > 0;

  // True when this number represents a negative ROI.
  bool get isNegativeRoi => this < 0;
}

// DateTime Extensions
extension DateTimeExtensions on DateTime {
  // True when this date is today (ignores time component).
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // True when this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  // True when this date is in the future.
  bool get isFuture => isAfter(DateTime.now());

  // True when this date is in the past.
  bool get isPast => isBefore(DateTime.now());

  // Returns 'Today', 'Yesterday', or 'Apr 15, 2025'.
  String toRelativeString() => DateFormatter.formatRelative(this);

  // Returns 'Apr 15, 2025'.
  String toFullString() => DateFormatter.formatFull(this);

  // Returns '15 Apr'.
  String toShortString() => DateFormatter.formatShort(this);

  // Returns 'Sat 15:00' — for fixture kickoff display.
  String toKickoffString() => DateFormatter.formatKickoff(this);

  // Returns start of the day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  // Returns end of the day (23:59:59).
  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);
}
