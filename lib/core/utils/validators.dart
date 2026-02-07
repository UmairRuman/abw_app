// lib/core/utils/validators.dart

import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? validatePakistaniPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Pattern 1: 03001234567 (11 digits, starts with 03)
    final pattern1 = RegExp(r'^03[0-9]{9}$');

    // Pattern 2: +923001234567 (starts with +92, then 10 digits)
    final pattern2 = RegExp(r'^\+923[0-9]{9}$');

    // Pattern 3: 923001234567 (starts with 92, then 10 digits)
    final pattern3 = RegExp(r'^923[0-9]{9}$');

    if (pattern1.hasMatch(cleaned) ||
        pattern2.hasMatch(cleaned) ||
        pattern3.hasMatch(cleaned)) {
      return null; // Valid
    }

    return 'Enter valid Pakistani number (e.g., 03001234567)';
  }

  /// Format Pakistani phone number for display
  static String formatPakistaniPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.startsWith('+92')) {
      // +92 300 1234567
      return '+92 ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    } else if (cleaned.startsWith('92')) {
      // +92 300 1234567
      return '+92 ${cleaned.substring(2, 5)} ${cleaned.substring(5)}';
    } else if (cleaned.startsWith('03')) {
      // 0300 1234567
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
    }

    return phone;
  }

  /// Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    if (!AppConstants.emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must not exceed ${AppConstants.maxPasswordLength} characters';
    }

    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    if (!AppConstants.phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < AppConstants.minUsernameLength) {
      return 'Username must be at least ${AppConstants.minUsernameLength} characters';
    }

    if (value.length > AppConstants.maxUsernameLength) {
      return 'Username must not exceed ${AppConstants.maxUsernameLength} characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  /// Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name must not exceed 50 characters';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  /// Required field validation
  static String? validateRequired(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }

    if (!AppConstants.urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Number validation
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Min length validation
  static String? validateMinLength(
    String? value,
    int minLength, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  /// Max length validation
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }

  /// Date validation (not in future)
  static String? validatePastDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }

    if (value.isAfter(DateTime.now())) {
      return 'Date cannot be in the future';
    }

    return null;
  }

  /// Date validation (not in past)
  static String? validateFutureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }

    if (value.isBefore(DateTime.now())) {
      return 'Date cannot be in the past';
    }

    return null;
  }

  /// Age validation (18+)
  static String? validateAge(DateTime? birthDate, {int minAge = 18}) {
    if (birthDate == null) {
      return 'Birth date is required';
    }

    final today = DateTime.now();
    final age = today.year - birthDate.year;

    if (age < minAge) {
      return 'You must be at least $minAge years old';
    }

    return null;
  }

  /// Credit card number validation (basic)
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final cardNumber = value.replaceAll(' ', '');

    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return 'Invalid card number';
    }

    if (!RegExp(r'^\d+$').hasMatch(cardNumber)) {
      return 'Card number can only contain digits';
    }

    return null;
  }

  /// CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3 or 4 digits';
    }

    return null;
  }
}
