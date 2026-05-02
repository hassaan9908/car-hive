// In lib/auth/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/trust_rank_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? fullName,
    String? username,
    String? birthday,
    String? gender,
    String? phoneNumber, // Add phoneNumber parameter
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Normalize phone number for consistent storage
      final normalizedPhoneNumber =
          phoneNumber != null && phoneNumber.isNotEmpty
              ? _normalizePhoneNumber(phoneNumber)
              : null;

      // Create user document in Firestore with all the new fields
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'displayName': fullName ?? cred.user!.displayName ?? 'User',
        'fullName': fullName,
        'username': username?.toLowerCase(),
        'phoneNumber':
            normalizedPhoneNumber, // Store normalized phone number here
        'birthday': birthday, // Keep original birthday if provided
        'gender': gender, // Keep original gender if provided
        'role': 'user', // Default role
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'totalAdsPosted': 0,
        'activeAdsCount': 0,
        'rejectedAdsCount': 0,
      });

      // Create username document for availability checking
      if (username != null && username.isNotEmpty) {
        await _firestore
            .collection('usernames')
            .doc(username.toLowerCase())
            .set({
          'userId': cred.user!.uid,
          'username': username.toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Create phone number document for availability checking
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Normalize phone number for consistent storage
        final normalizedPhone = _normalizePhoneNumber(phoneNumber);
        if (normalizedPhone.isNotEmpty) {
          await _firestore.collection('phoneNumbers').doc(normalizedPhone).set({
            'userId': cred.user!.uid,
            'phoneNumber': normalizedPhone,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Compute initial trust rank for new user
      try {
        await TrustRankService().recomputeAndSave(cred.user!.uid);
      } catch (e) {
        print('Error computing initial trust rank: $e');
      }

      // Create activity log for new user registration
      await _createActivityLog(
        type: 'userRegistered',
        title: 'New user registered',
        description: email,
        userId: cred.user!.uid,
        metadata: {
          'userEmail': email,
          'displayName': fullName ?? cred.user!.displayName ?? 'User',
          'username': username,
          'phoneNumber':
              normalizedPhoneNumber, // Include normalized phone number in activity log
        },
      );

      return cred.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'email-already-in-use') {
        // Re-throw with a more user-friendly message
        throw Exception(
            'This email is already registered. Please use a different email or login instead.');
      } else if (e.code == 'invalid-email') {
        throw Exception(
            'The email address is invalid. Please check and try again.');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception('Email/password accounts are not enabled.');
      } else if (e.code == 'weak-password') {
        throw Exception(
            'The password is too weak. Please use a stronger password.');
      }
      // Re-throw other Firebase Auth errors
      rethrow;
    } catch (e) {
      print("Registration error: $e");
      rethrow;
    }
  }

  // Create activity log
  Future<void> _createActivityLog({
    required String type,
    required String title,
    required String description,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('activities').add({
        'type': type,
        'title': title,
        'description': description,
        'userId': userId,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to create activity log: $e');
    }
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Check if user document exists, create it if it doesn't
      final userDoc =
          await _firestore.collection('users').doc(cred.user!.uid).get();
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'displayName': cred.user!.displayName ?? 'User',
          'fullName': cred.user!.displayName,
          'username': null, // Will be set later when user completes profile
          'phoneNumber': null, // Will be set later when user completes profile
          'birthday': null, // Not collecting anymore
          'gender': null, // Not collecting anymore
          'role': 'user', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'totalAdsPosted': 0,
          'activeAdsCount': 0,
          'rejectedAdsCount': 0,
        });
      } else {
        // Update last login time if document exists
        await _firestore.collection('users').doc(cred.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      return cred.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'user-not-found') {
        throw Exception(
            'No user found with this email. Please check your email or sign up.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please try again.');
      } else if (e.code == 'invalid-email') {
        throw Exception(
            'The email address is invalid. Please check and try again.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled.');
      }
      // Re-throw other Firebase Auth errors
      rethrow;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Sign out error: $e");
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email address.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is invalid.');
      }
      rethrow;
    } catch (e) {
      print("Password reset error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
    } catch (e) {
      print('Error getting user document: $e');
    }
    return null;
  }

  /// Normalize phone number for consistent storage
  String _normalizePhoneNumber(String phoneNumber) {
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

  signInWithGoogle() async {
    try {
      // Configure GoogleSignIn with minimal scopes to avoid People API
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? gUser = await googleSignIn.signIn();

      if (gUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      // Create or update user document in Firestore
      if (result.user != null) {
        final userDoc =
            await _firestore.collection('users').doc(result.user!.uid).get();
        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          await _firestore.collection('users').doc(result.user!.uid).set({
            'email': result.user!.email,
            'displayName': result.user!.displayName ?? 'User',
            'fullName': result.user!.displayName,
            'username': null, // Will be set later when user completes profile
            'phoneNumber':
                null, // Will be set later when user completes profile
            'birthday': null, // Not collecting anymore
            'gender': null, // Not collecting anymore
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'totalAdsPosted': 0,
            'activeAdsCount': 0,
            'rejectedAdsCount': 0,
          });
        } else {
          // Update last login time if document exists
          await _firestore.collection('users').doc(result.user!.uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }

        // Compute trust rank for user (new or existing)
        try {
          await TrustRankService().recomputeAndSave(result.user!.uid);
        } catch (e) {
          print('Error computing trust rank: $e');
        }
      }

      return result;
    } catch (e) {
      print("Google sign-in error: $e");
      rethrow;
    }
  }
}
