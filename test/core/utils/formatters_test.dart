import 'package:flutter_test/flutter_test.dart';
import 'package:matchlog/core/utils/formatters.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats NGN correctly', () {
      expect(CurrencyFormatter.format(1000.0, 'NGN'), '₦1,000.00');
      expect(CurrencyFormatter.format(1500.50, 'NGN'), '₦1,500.50');
      expect(CurrencyFormatter.format(0.0, 'NGN'), '₦0.00');
    });

    test('formats USD correctly', () {
      expect(CurrencyFormatter.format(99.99, 'USD'), '\$99.99');
      expect(CurrencyFormatter.format(1000.0, 'USD'), '\$1,000.00');
    });

    test('formats GBP correctly', () {
      expect(CurrencyFormatter.format(50.0, 'GBP'), '£50.00');
    });

    test('formats EUR correctly', () {
      expect(CurrencyFormatter.format(200.0, 'EUR'), '€200.00');
    });

    test('uses currency code as prefix for unknown currencies', () {
      expect(CurrencyFormatter.format(100.0, 'XYZ'), 'XYZ 100.00');
    });

    test('handles large amounts with comma separators', () {
      expect(CurrencyFormatter.format(1000000.0, 'NGN'), '₦1,000,000.00');
    });
  });

  group('OddsFormatter', () {
    test('formats to exactly 2 decimal places', () {
      expect(OddsFormatter.format(2.1), '2.10');
      expect(OddsFormatter.format(1.5), '1.50');
      expect(OddsFormatter.format(10.0), '10.00');
      expect(OddsFormatter.format(1.85), '1.85');
    });

    test('rounds to 2 decimal places', () {
      // Note: Dart floating point — 2.105 is stored as ~2.1049999...
      // so toStringAsFixed(2) gives '2.10', not '2.11'
      expect(OddsFormatter.format(1.994), '1.99');
      expect(OddsFormatter.format(2.999), '3.00');
    });

    test('formatWithSign adds + prefix', () {
      expect(OddsFormatter.formatWithSign(2.10), '+2.10');
    });
  });

  group('DateFormatter', () {
    test('formatRelative returns Today for current date', () {
      expect(DateFormatter.formatRelative(DateTime.now()), 'Today');
    });

    test('formatRelative returns Yesterday for previous day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateFormatter.formatRelative(yesterday), 'Yesterday');
    });

    test('formatRelative returns formatted date for older dates', () {
      final oldDate = DateTime(2025, 4, 15);
      expect(DateFormatter.formatRelative(oldDate), 'Apr 15, 2025');
    });

    test('formatFull returns Apr 15, 2025 format', () {
      expect(DateFormatter.formatFull(DateTime(2025, 4, 15)), 'Apr 15, 2025');
    });

    test('formatShort returns 15 Apr format', () {
      expect(DateFormatter.formatShort(DateTime(2025, 4, 15)), '15 Apr');
    });

    test('formatTime returns HH:mm format', () {
      final time = DateTime(2025, 4, 15, 20, 45);
      expect(DateFormatter.formatTime(time), '20:45');
    });
  });
}
