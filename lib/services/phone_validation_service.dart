import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if a phone number is already in use by another user
  /// Note: This will fail with permission denied for unauthenticated users
  /// We handle this in the UI by catching the error during actual signup
  static Future<bool> isPhoneNumberAvailable(String phoneNumber) async {
    try {
      // Normalize phone number for comparison
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      // First check the dedicated phoneNumbers collection for faster lookup
      final phoneDoc = await _firestore
          .collection('phoneNumbers')
          .doc(normalizedPhone)
          .get();

      if (phoneDoc.exists) {
        return false; // Phone number is already in use
      }

      // Fallback: Query users collection for existing phone number
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .get();

      // If any documents are found, the phone number is already in use
      return querySnapshot
          .docs.isEmpty; // true if no documents found (phone number available)
    } on FirebaseException catch (e) {
      // Handle permission denied or other Firebase errors gracefully
      if (e.code == 'permission-denied') {
        // If we can't check due to permissions, we assume it might be available
        // The actual duplicate check will happen during signup
        print(
            'Permission denied when checking phone number availability - will check during signup');
        return true;
      }
      print('Error checking phone number availability: $e');
      return false; // Return false on other errors to be safe
    } catch (e) {
      print('Error checking phone number availability: $e');
      return false; // Return false on error to be safe
    }
  }

  /// Check if phone number is available for a specific user (useful for updates)
  static Future<bool> isPhoneNumberAvailableForUser(
      String phoneNumber, String userId) async {
    try {
      // Normalize phone number for comparison
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      // First check the dedicated phoneNumbers collection for faster lookup
      final phoneDoc = await _firestore
          .collection('phoneNumbers')
          .doc(normalizedPhone)
          .get();

      if (phoneDoc.exists) {
        final phoneData = phoneDoc.data();
        if (phoneData != null && phoneData['userId'] != userId) {
          return false; // Phone number is already in use by another user
        }
      }

      // Fallback: Query users collection for existing phone number
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .get();

      // Check if any user (other than the specified user) has this phone number
      for (final doc in querySnapshot.docs) {
        if (doc.id != userId) {
          return false; // Phone number is already in use
        }
      }

      return true; // Phone number is available
    } catch (e) {
      print('Error checking phone number availability: $e');
      return false; // Return false on error to be safe
    }
  }

  /// Normalize phone number for consistent comparison
  static String _normalizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Convert to standard format
    if (digitsOnly.startsWith('92') && digitsOnly.length == 12) {
      // +92 format: +92XXXXXXXXXX -> 03XXXXXXXXX
      return '0${digitsOnly.substring(2)}';
    } else if (digitsOnly.startsWith('03') && digitsOnly.length == 11) {
      // Already in 03XXXXXXXXX format
      return digitsOnly;
    } else if (digitsOnly.length == 10) {
      // XXXXXXXXXX format -> 03XXXXXXXXX
      return '03$digitsOnly';
    }

    // Return as is if format is not recognized
    return phoneNumber.trim();
  }

  /// Format phone number for Firebase authentication
  static String _formatPhoneNumberForFirebase(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure proper format for Pakistan phone numbers
    if (digitsOnly.startsWith('92') && digitsOnly.length == 12) {
      // +92 format: +92XXXXXXXXXX -> +92XXXXXXXXXX
      return '+$digitsOnly';
    } else if (digitsOnly.startsWith('03') && digitsOnly.length == 11) {
      // 03XXXXXXXXX format -> +923XXXXXXXXX
      return '+92${digitsOnly.substring(1)}';
    } else if (digitsOnly.length == 10 && digitsOnly.startsWith('3')) {
      // XXXXXXXXXX format (starting with 3) -> +923XXXXXXXXX
      return '+92$digitsOnly';
    }

    // If format is not recognized, return as is
    return phoneNumber;
  }

  /// Validate phone number format and availability
  static Future<String?> validatePhoneNumber(String? value,
      {String? currentUserId}) async {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim();

    // Basic format validation
    if (phone.length < 3) {
      return null; // Don't show error for very short input
    }

    // Check for Pakistan phone numbers
    if (phone.startsWith('+92')) {
      if (phone.length > 13) {
        return 'Phone number too long';
      }
      if (phone.length < 13) {
        return 'Phone number incomplete';
      }
      if (!RegExp(r'^\+92[0-9]{10}$').hasMatch(phone)) {
        return 'Invalid Pakistan phone number format';
      }
    } else if (phone.startsWith('03')) {
      if (phone.length > 11) {
        return 'Phone number too long';
      }
      if (phone.length < 11) {
        return 'Phone number incomplete';
      }
      if (!RegExp(r'^03[0-9]{9}$').hasMatch(phone)) {
        return 'Invalid Pakistan phone number format';
      }
    } else if (phone.length >= 3) {
      return 'Phone number must start with +92 or 03';
    }

    // Check availability only for complete phone numbers
    if ((phone.startsWith('+92') && phone.length == 13) ||
        (phone.startsWith('03') && phone.length == 11)) {
      final isAvailable = currentUserId != null
          ? await isPhoneNumberAvailableForUser(phone, currentUserId)
          : await isPhoneNumberAvailable(phone);

      if (!isAvailable) {
        return 'This phone number is already registered';
      }
    }

    return null;
  }

  /// Update phone number in the dedicated collection for faster lookups
  static Future<void> updatePhoneNumberRecord(
      String userId, String phoneNumber) async {
    try {
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      if (normalizedPhone.isNotEmpty) {
        await _firestore.collection('phoneNumbers').doc(normalizedPhone).set({
          'userId': userId,
          'phoneNumber': normalizedPhone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating phone number record: $e');
    }
  }

  /// Remove phone number from the dedicated collection
  static Future<void> removePhoneNumberRecord(String phoneNumber) async {
    try {
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);

      if (normalizedPhone.isNotEmpty) {
        await _firestore
            .collection('phoneNumbers')
            .doc(normalizedPhone)
            .delete();
      }
    } catch (e) {
      print('Error removing phone number record: $e');
    }
  }
}
