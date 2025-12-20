import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if an email is already in use by another user
  /// Note: This will fail with permission denied for unauthenticated users
  /// We handle this in the UI by catching the error during actual signup
  static Future<bool> isEmailAvailable(String email) async {
    try {
      // Normalize email for comparison (lowercase)
      final normalizedEmail = email.toLowerCase().trim();

      // Query users collection for existing email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .get();

      // If any documents are found, the email is already in use
      return querySnapshot
          .docs.isEmpty; // true if no documents found (email available)
    } on FirebaseException catch (e) {
      // Handle permission denied or other Firebase errors gracefully
      if (e.code == 'permission-denied') {
        // If we can't check due to permissions, we assume it might be available
        // The actual duplicate check will happen during signup
        print(
            'Permission denied when checking email availability - will check during signup');
        return true;
      }
      print('Error checking email availability: $e');
      return false; // Return false on other errors to be safe
    } catch (e) {
      print('Error checking email availability: $e');
      return false; // Return false on error to be safe
    }
  }

  /// Check if email is available for a specific user (useful for updates)
  static Future<bool> isEmailAvailableForUser(
      String email, String userId) async {
    try {
      // Normalize email for comparison (lowercase)
      final normalizedEmail = email.toLowerCase().trim();

      // Query users collection for existing email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .get();

      // Check if any user (other than the specified user) has this email
      for (final doc in querySnapshot.docs) {
        if (doc.id != userId) {
          return false; // Email is already in use
        }
      }

      return true; // Email is available
    } catch (e) {
      print('Error checking email availability: $e');
      return false; // Return false on error to be safe
    }
  }

  /// Validate email format and availability
  static Future<String?> validateEmail(String? value,
      {String? currentUserId}) async {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim().toLowerCase();

    // Basic email format validation
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Check email availability
    final isAvailable = currentUserId != null
        ? await isEmailAvailableForUser(email, currentUserId)
        : await isEmailAvailable(email);

    if (!isAvailable) {
      return 'This email is already registered';
    }

    return null;
  }
}
