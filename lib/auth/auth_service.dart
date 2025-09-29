// In lib/auth/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'displayName': cred.user!.displayName ?? 'User',
        'role': 'user', // Default role
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'totalAdsPosted': 0,
        'activeAdsCount': 0,
        'rejectedAdsCount': 0,
      });

      // Create activity log for new user registration
      await _createActivityLog(
        type: 'userRegistered',
        title: 'New user registered',
        description: email,
        userId: cred.user!.uid,
        metadata: {
          'userEmail': email,
          'displayName': cred.user!.displayName ?? 'User',
        },
      );
      
      return cred.user;
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

  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Check if user document exists, create it if it doesn't
      final userDoc = await _firestore.collection('users').doc(cred.user!.uid).get();
      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'displayName': cred.user!.displayName ?? 'User',
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

  // ... rest of your existing methods
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
        final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          await _firestore.collection('users').doc(result.user!.uid).set({
            'email': result.user!.email,
            'displayName': result.user!.displayName ?? 'User',
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
      }
      
      return result;
    } catch (e) {
      print("Google sign-in error: $e");
      rethrow;
    }
  }

}