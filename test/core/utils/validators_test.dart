import 'package:flutter_test/flutter_test.dart';
import 'package:matchlog/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('returns error for null', () {
      expect(Validators.required(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.required(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(Validators.required('   '), isNotNull);
    });

    test('returns null for valid string', () {
      expect(Validators.required('hello'), isNull);
    });

    test('returns null for string with spaces', () {
      expect(Validators.required('Arsenal FC'), isNull);
    });
  });

  group('Validators.email', () {
    test('returns error for null', () {
      expect(Validators.email(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(Validators.email(''), isNotNull);
    });

    test('returns error for invalid email', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@nodomain.com'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user+tag@domain.co.uk'), isNull);
    });
  });

  group('Validators.odds', () {
    test('returns error for null', () {
      expect(Validators.odds(null), isNotNull);
    });

    test('returns error for non-numeric string', () {
      expect(Validators.odds('abc'), isNotNull);
    });

    test('returns error for odds equal to 1.0', () {
      expect(Validators.odds('1.0'), isNotNull);
    });

    test('returns error for odds less than 1.0', () {
      expect(Validators.odds('0.9'), isNotNull);
      expect(Validators.odds('0.5'), isNotNull);
    });

    test('returns null for valid odds greater than 1.0', () {
      expect(Validators.odds('1.01'), isNull);
      expect(Validators.odds('2.10'), isNull);
      expect(Validators.odds('10.0'), isNull);
    });
  });

  group('Validators.stake', () {
    test('returns error for null', () {
      expect(Validators.stake(null), isNotNull);
    });

    test('returns error for zero', () {
      expect(Validators.stake('0'), isNotNull);
    });

    test('returns error for negative amount', () {
      expect(Validators.stake('-100'), isNotNull);
    });

    test('returns error for non-numeric string', () {
      expect(Validators.stake('abc'), isNotNull);
    });

    test('returns null for valid positive stake', () {
      expect(Validators.stake('100'), isNull);
      expect(Validators.stake('1000.50'), isNull);
      expect(Validators.stake('0.01'), isNull);
    });

    test('handles comma-formatted amounts', () {
      expect(Validators.stake('1,000'), isNull);
    });
  });

  group('Validators.rating', () {
    test('returns error for null', () {
      expect(Validators.rating(null), isNotNull);
    });

    test('returns error for 0', () {
      expect(Validators.rating(0), isNotNull);
    });

    test('returns error for 6', () {
      expect(Validators.rating(6), isNotNull);
    });

    test('returns error for negative values', () {
      expect(Validators.rating(-1), isNotNull);
    });

    test('returns null for valid ratings 1-5', () {
      for (int i = 1; i <= 5; i++) {
        expect(Validators.rating(i), isNull, reason: 'Rating $i should be valid');
      }
    });
  });

  group('Validators.inviteCode', () {
    test('returns error for null', () {
      expect(Validators.inviteCode(null), isNotNull);
    });

    test('returns error for wrong length', () {
      expect(Validators.inviteCode('ABC'), isNotNull);
      expect(Validators.inviteCode('ABCDEFG'), isNotNull);
    });

    test('returns error for special characters', () {
      expect(Validators.inviteCode('ABC!@#'), isNotNull);
    });

    test('returns null for valid 6-char alphanumeric code', () {
      expect(Validators.inviteCode('MNC25X'), isNull);
      expect(Validators.inviteCode('abc123'), isNull); // lowercase accepted
    });
  });
}
