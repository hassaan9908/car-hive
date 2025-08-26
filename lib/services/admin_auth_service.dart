import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin login
  Future<UserCredential> adminLogin(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify admin role
      final isAdmin = await _verifyAdminRole(credential.user!.uid);
      if (!isAdmin) {
        await _auth.signOut();
        throw Exception('Access denied. Admin privileges required.');
      }

      return credential;
    } catch (e) {
      print('Admin login error: $e');
      rethrow;
    }
  }

  // Verify admin role
  Future<bool> _verifyAdminRole(String userId) async {
    try {
      print('AdminAuthService: Verifying role for user ID: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        print('AdminAuthService: User document does not exist');
        return false;
      }

      final userData = doc.data();
      final role = userData?['role'];
      print('AdminAuthService: User role found: $role');
      
      final isAdmin = role == 'admin' || role == 'super_admin';
      print('AdminAuthService: Is admin: $isAdmin');
      
      return isAdmin;
    } catch (e) {
      print('AdminAuthService: Error verifying admin role: $e');
      return false;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      print('AdminAuthService: Checking admin status for user: ${user?.email}');
      
      if (user == null) {
        print('AdminAuthService: No current user found');
        return false;
      }

      final result = await _verifyAdminRole(user.uid);
      print('AdminAuthService: Role verification result: $result');
      return result;
    } catch (e) {
      print('AdminAuthService: Error checking current user admin status: $e');
      return false;
    }
  }

  // Get current admin user data
  Future<Map<String, dynamic>?> getCurrentAdminData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('AdminAuthService: No current user found in getCurrentAdminData');
        return null;
      }

      print('AdminAuthService: Getting admin data for user: ${user.email} (${user.uid})');
      
      final isAdmin = await _verifyAdminRole(user.uid);
      if (!isAdmin) {
        print('AdminAuthService: User does not have admin role');
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('AdminAuthService: User document does not exist in Firestore');
        return null;
      }

      final data = doc.data();
      print('AdminAuthService: Successfully retrieved admin data. Role: ${data?['role']}');
      return data;
    } catch (e) {
      print('AdminAuthService: Error getting current admin data: $e');
      return null;
    }
  }

  // Admin logout
  Future<void> adminLogout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Admin logout error: $e');
      rethrow;
    }
  }

  // Create admin user (for super admin only)
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String displayName,
    required String role, // 'admin' or 'super_admin'
  }) async {
    try {
      // Check if current user is super admin
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists || currentUserDoc.data()?['role'] != 'super_admin') {
        throw Exception('Insufficient privileges. Super admin required.');
      }

      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'totalAdsPosted': 0,
        'activeAdsCount': 0,
        'rejectedAdsCount': 0,
        'createdBy': currentUser.uid,
      });
    } catch (e) {
      print('Error creating admin user: $e');
      rethrow;
    }
  }

  // Change admin password
  Future<void> changeAdminPassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
    } catch (e) {
      print('Error changing admin password: $e');
      rethrow;
    }
  }
}
