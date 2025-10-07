import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if username is available
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final docSnapshot = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      return !docSnapshot.exists;
    } catch (e) {
      print('Error checking username availability: $e');
      return false; // Return false on error to be safe
    }
  }

  // Check username availability and return validation message
  static Future<String?> validateUsernameAvailability(String username) async {
    if (username.isEmpty) {
      return 'Username is required';
    }

    final isAvailable = await isUsernameAvailable(username);
    if (!isAvailable) {
      return 'Username is already taken';
    }

    return null;
  }
}
