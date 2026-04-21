/// Pure Formatting utilities for currency, odds, and dates.
// Usage:
//   CurrencyFormatter.format(1500.0, 'NGN') → '₦1,500.00'
//   OddsFormatter.format(2.1)               → '2.10'
//   DateFormatter.formatRelative(DateTime.now()) → 'Today'
library;

import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _currencySymbols = <String, String>{
    'NGN': '₦',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'KES': 'KSh',
    'GHS': '₵',  
    'ZAR': 'R',
  };

  // Format [amount] with the appropriate currency symbol.
  // Known currencies use their symbol prefix (e.g., ₦1,000.00).
  // Unknown currencies use the code as prefix (e.g., XYZ 1,000.00).
  static String format(double amount, String currency) {
    final symbol = _currencySymbols[currency.toUpperCase()];
    final formatted = NumberFormat('#,##0.00').format(amount);

    if (symbol != null) {
      return '$symbol$formatted';
    }
    return '${currency.toUpperCase()} $formatted';
  }

  // Format a compact amount (no decimals for whole numbers).
  // e.g., 1500.0 → '₦1,500', 1500.50 → '₦1,500.50'
  static String formatCompact(double amount, String currency) {
    final symbol = _currencySymbols[currency.toUpperCase()] ?? currency;
    if (amount == amount.truncateToDouble()) {
      return '$symbol${NumberFormat('#,##0').format(amount)}';
    }
    return '$symbol${NumberFormat('#,##0.00').format(amount)}';
  }
}

class OddsFormatter {
  OddsFormatter._();

  // Format decimal odds to exactly 2 decimal places.
  // e.g., 2.1 → '2.10', 1.5 → '1.50', 10.0 → '10.00'
  static String format(double odds) => odds.toStringAsFixed(2);

  // Format odds with a + prefix for display in bet cards.
  // e.g., 2.10 → '+2.10'
  static String formatWithSign(double odds) => '+${format(odds)}';
}

class DateFormatter {
  DateFormatter._();

  static final _fullFormat = DateFormat('MMM d, yyyy');   // Apr 15, 2025
  static final _shortFormat = DateFormat('d MMM');         // 15 Apr
  static final _timeFormat = DateFormat('HH:mm');          // 20:45
  static final _kickoffFormat = DateFormat('EEE HH:mm');   // Sat 15:00

  // Returns 'Today', 'Yesterday', or 'Apr 15, 2025' for older dates.
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return _fullFormat.format(date);
  }

  // Returns 'Apr 15, 2025'.
  static String formatFull(DateTime date) => _fullFormat.format(date);

  // Returns '15 Apr'.
  static String formatShort(DateTime date) => _shortFormat.format(date);

  // Returns '20:45'.
  static String formatTime(DateTime date) => _timeFormat.format(date);

  // Returns 'Sat 15:00' — used for fixture kickoff times.
  static String formatKickoff(DateTime date) => _kickoffFormat.format(date);

  // Returns 'Apr 2025' — used for monthly grouping in stats.
  static String formatMonth(DateTime date) =>
      DateFormat('MMM yyyy').format(date);
}
