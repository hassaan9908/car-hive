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
      final isAdmin = await _verifyAdminRoleForUser(credential.user);
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

  String _normalizeRole(dynamic role) {
    final normalized = role?.toString().trim().toLowerCase() ?? '';
    final underscored = normalized.replaceAll('-', '_').replaceAll(' ', '_');

    if (underscored == 'superadmin') {
      return 'super_admin';
    }

    return underscored;
  }

  bool _isAdminRole(dynamic role) {
    final normalizedRole = _normalizeRole(role);
    return normalizedRole == 'admin' || normalizedRole == 'super_admin';
  }

  Future<Map<String, dynamic>?> _resolveUserData(User user) async {
    try {
      print(
        'AdminAuthService: Resolving user data for UID: ${user.uid}, email: ${user.email}',
      );

      final uidDoc = await _firestore.collection('users').doc(user.uid).get();
      if (uidDoc.exists) {
        final userData = Map<String, dynamic>.from(uidDoc.data() ?? {});
        userData['role'] = _normalizeRole(userData['role']);
        print(
          'AdminAuthService: Found user document by UID. Role: ${userData['role']}',
        );
        return userData;
      }

      print(
        'AdminAuthService: No user document found by UID. Trying email lookup...',
      );

      final email = user.email?.trim();
      if (email == null || email.isEmpty) {
        print(
            'AdminAuthService: Cannot do email fallback because email is empty');
        return null;
      }

      final exactEmailSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (exactEmailSnapshot.docs.isNotEmpty) {
        final userData = Map<String, dynamic>.from(
          exactEmailSnapshot.docs.first.data(),
        );
        userData['role'] = _normalizeRole(userData['role']);
        print(
          'AdminAuthService: Found user document by exact email. Role: ${userData['role']}',
        );
        return userData;
      }

      final lowerEmail = email.toLowerCase();
      if (lowerEmail != email) {
        final lowerEmailSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: lowerEmail)
            .limit(1)
            .get();

        if (lowerEmailSnapshot.docs.isNotEmpty) {
          final userData = Map<String, dynamic>.from(
            lowerEmailSnapshot.docs.first.data(),
          );
          userData['role'] = _normalizeRole(userData['role']);
          print(
            'AdminAuthService: Found user document by lowercase email. Role: ${userData['role']}',
          );
          return userData;
        }
      }

      print('AdminAuthService: User document could not be resolved');
      return null;
    } catch (e) {
      print('AdminAuthService: Error resolving user data: $e');
      return null;
    }
  }

  // Verify admin role
  Future<bool> _verifyAdminRoleForUser(User? user) async {
    try {
      if (user == null) {
        print(
            'AdminAuthService: _verifyAdminRoleForUser called with null user');
        return false;
      }

      final userData = await _resolveUserData(user);
      if (userData == null) {
        print('AdminAuthService: No user data resolved during role check');
        return false;
      }

      final role = userData['role'];
      print('AdminAuthService: User role found: $role');

      final isAdmin = _isAdminRole(role);
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

      final result = await _verifyAdminRoleForUser(user);
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

      print(
        'AdminAuthService: Getting admin data for user: ${user.email} (${user.uid})',
      );

      final adminData = await _resolveUserData(user);
      if (adminData == null) {
        print('AdminAuthService: User data could not be resolved');
        return null;
      }

      if (!_isAdminRole(adminData['role'])) {
        print('AdminAuthService: User does not have admin role');
        return null;
      }

      print(
        'AdminAuthService: Successfully retrieved admin data. Role: ${adminData['role']}',
      );
      return adminData;
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

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists ||
          currentUserDoc.data()?['role'] != 'super_admin') {
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
  Future<void> changeAdminPassword(
      String currentPassword, String newPassword) async {
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
