// Form validation utilities.
// Usage with TextFormField:
//   TextFormField(validator: Validators.required)
//   TextFormField(validator: Validators.email)
//   TextFormField(validator: Validators.odds)

library;

class Validators {
  Validators._();

  // Validates that [value] is not null or empty after trimming.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  // Validates that [value] is a valid email address.
  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Validates that [value] is a decimal odds value greater than 1.0.
  // Odds of 1.0 or less are invalid (no profit possible).
  static String? odds(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid number (e.g., 2.10)';
    if (parsed <= 1.0) return 'Odds must be greater than 1.00';
    return null;
  }

  // Validates that [value] is a positive stake amount.
  static String? stake(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final parsed = double.tryParse(value!.trim().replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid amount';
    if (parsed <= 0) return 'Stake must be greater than 0';
    return null;
  }

  // Validates that [value] is a rating between 1 and 5 inclusive.
  static String? rating(int? value) {
    if (value == null) return 'Please select a rating';
    if (value < 1 || value > 5) return 'Rating must be between 1 and 5';
    return null;
  }

  // Validates that [value] has at least 8 characters.
  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Validates that [value] matches [otherValue].
  static String? confirmPassword(String? value, String otherValue) {
    final passwordError = password(value);
    if (passwordError != null) return passwordError;
    if (value!.trim() != otherValue.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Validates that [value] is a non-empty display name.
  static String? displayName(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name must be 50 characters or less';
    return null;
  }

  // Validates a 6-character alphanumeric Bookie Group invite code.
  static String? inviteCode(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;

    final code = value!.trim().toUpperCase();
    if (code.length != 6) return 'Invite code must be 6 characters';
    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      return 'Invite code must contain only letters and numbers';
    }
    return null;
  }

  // Validates a review text — optional but has a max length.
  static String? review(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    if (value.trim().length > 1000) {
      return 'Review must be 1000 characters or less';
    }
    return null;
  }
}
