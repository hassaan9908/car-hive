import 'package:flutter/material.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation with specific requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for at least one alphabet
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }

    // Check for at least one numerical number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    // Check for at least one symbol (dot, hyphen, etc.)
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(value)) {
      return 'Password must contain at least one symbol (e.g., ., -, @, #, etc.)';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }

    return null;
  }

  // General required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(
      String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    return null;
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (value.length > 20) {
      return 'Username cannot exceed 20 characters';
    }

    // Only allow alphanumeric characters and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    // Must start with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
      return 'Username must start with a letter';
    }

    return null;
  }

  // Pakistan phone number validation
  static String? validatePakistanPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Pakistan phone numbers should be 11 digits starting with 03
    if (digitsOnly.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }

    if (!digitsOnly.startsWith('03')) {
      return 'Phone number must start with 03 (Pakistan format)';
    }

    return null;
  }

  // Password strength calculation
  static PasswordStrength calculatePasswordStrength(String password) {
    int score = 0;
    List<String> feedback = [];

    if (password.length >= 8) {
      score += 1;
    } else {
      feedback.add('At least 8 characters');
    }

    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Lowercase letter');
    }

    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Uppercase letter');
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Number');
    }

    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(password)) {
      score += 1;
    } else {
      feedback.add('Special character');
    }

    if (password.length >= 12) {
      score += 1;
    }

    String strength;
    Color color;

    if (score <= 2) {
      strength = 'Weak';
      color = Colors.red;
    } else if (score <= 4) {
      strength = 'Medium';
      color = Colors.orange;
    } else {
      strength = 'Strong';
      color = Colors.green;
    }

    return PasswordStrength(
      score: score,
      strength: strength,
      color: color,
      feedback: feedback,
    );
  }
}

// Password strength data class
class PasswordStrength {
  final int score;
  final String strength;
  final Color color;
  final List<String> feedback;

  PasswordStrength({
    required this.score,
    required this.strength,
    required this.color,
    required this.feedback,
  });
}
