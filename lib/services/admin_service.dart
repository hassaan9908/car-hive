import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/ad_model.dart';
import '../models/admin_stats_model.dart';
import '../models/activity_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final userData = doc.data();
      return userData?['role'] == 'admin' || userData?['role'] == 'super_admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get admin dashboard statistics
  Future<AdminStatsModel> getDashboardStats() async {
    try {
      print('AdminService: Getting dashboard stats...');
      
      // Get total users
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      print('AdminService: Total users: $totalUsers');

      // Get ads statistics
      final adsSnapshot = await _firestore.collection('ads').get();
      int totalAds = 0;
      int pendingAds = 0;
      int activeAds = 0;
      int rejectedAds = 0;

      for (var doc in adsSnapshot.docs) {
        final data = doc.data();
        totalAds++;
        final status = data['status'];
        final title = data['title'] ?? 'No title';
        print('AdminService: Ad status check - $title: $status');
        
        if (status == null || status == '') {
          print('AdminService: Ad without status found - $title, counting as pending');
          pendingAds++;
        } else {
          switch (status) {
            case 'pending':
              pendingAds++;
              break;
            case 'active':
              activeAds++;
              break;
            case 'rejected':
              rejectedAds++;
              break;
            default:
              print('AdminService: Unknown status for ad $title: $status');
              // Count unknown statuses as pending for now
              pendingAds++;
              break;
          }
        }
      }

      print('AdminService: Dashboard stats - Total: $totalAds, Pending: $pendingAds, Active: $activeAds, Rejected: $rejectedAds');

      return AdminStatsModel(
        totalUsers: totalUsers,
        totalAds: totalAds,
        pendingAds: pendingAds,
        activeAds: activeAds,
        rejectedAds: rejectedAds,
        totalRevenue: 0, // TODO: Implement revenue tracking
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('AdminService: Error getting dashboard stats: $e');
      rethrow;
    }
  }

  // Get recent activities
  Future<List<ActivityModel>> getRecentActivities({int limit = 10}) async {
    try {
      print('AdminService: Getting recent activities...');
      
      // Try to get activities with orderBy first
      try {
        final snapshot = await _firestore
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        print('AdminService: Found ${snapshot.docs.length} activities with orderBy');
        final activities = snapshot.docs
            .map((doc) => ActivityModel.fromFirestore(doc.data(), doc.id))
            .toList();
        
        for (var activity in activities) {
          print('AdminService: Activity - ${activity.title} (${activity.type})');
        }
        
        return activities;
      } catch (orderByError) {
        print('AdminService: OrderBy failed, trying without orderBy: $orderByError');
        
        // Fallback: get all activities and sort in memory
        final snapshot = await _firestore.collection('activities').get();
        final allActivities = snapshot.docs
            .map((doc) => ActivityModel.fromFirestore(doc.data(), doc.id))
            .toList();
        
        // Sort by createdAt descending (most recent first)
        allActivities.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        
        final limitedActivities = allActivities.take(limit).toList();
        print('AdminService: Found ${allActivities.length} activities total, returning ${limitedActivities.length}');
        
        for (var activity in limitedActivities) {
          print('AdminService: Activity - ${activity.title} (${activity.type})');
        }
        
        return limitedActivities;
      }
    } catch (e) {
      print('AdminService: Error getting recent activities: $e');
      rethrow;
    }
  }

  // Get all users with pagination
  Future<List<UserModel>> getUsers({int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      print('AdminService: Getting users...');
      
      // Get all users and sort in memory to avoid index requirements
      final snapshot = await _firestore.collection('users').get();
      final allUsers = snapshot.docs.map((doc) => UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
      
      // Sort by createdAt descending (most recent first)
      allUsers.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      // Apply pagination
      final startIndex = lastDocument != null ? allUsers.indexWhere((user) => user.id == lastDocument.id) + 1 : 0;
      final endIndex = startIndex + limit;
      final paginatedUsers = allUsers.sublist(startIndex, endIndex > allUsers.length ? allUsers.length : endIndex);
      
      print('AdminService: Found ${allUsers.length} users, returning ${paginatedUsers.length}');
      return paginatedUsers;
    } catch (e) {
      print('AdminService: Error getting users: $e');
      rethrow;
    }
  }

  // Get pending ads for moderation
  Future<List<AdModel>> getPendingAds({int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      print('AdminService: Getting pending ads from Firestore...');
      
      // First, let's check all ads to see what's in the database
      final allAdsSnapshot = await _firestore.collection('ads').get();
      print('AdminService: Total ads in database: ${allAdsSnapshot.docs.length}');
      
      // Filter ads manually to avoid index requirements
      final pendingAds = <AdModel>[];
      
      for (var doc in allAdsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        final title = data['title'] ?? 'No title';
        print('AdminService: Checking ad - $title (${doc.id}) - status: $status');
        
        if (status == 'pending' || status == null || status == '') {
          print('AdminService: Found pending ad - $title (${doc.id})');
          pendingAds.add(AdModel.fromFirestore(data as Map<String, dynamic>, doc.id));
        }
      }
      
      // Sort by createdAt descending (most recent first)
      pendingAds.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      
      // Apply limit
      final limitedAds = pendingAds.take(limit).toList();
      
      print('AdminService: Found ${pendingAds.length} pending ads, returning ${limitedAds.length}');
      return limitedAds;
    } catch (e) {
      print('AdminService: Error getting pending ads: $e');
      rethrow;
    }
  }

  // Approve an ad
  Future<void> approveAd(String adId) async {
    try {
      // Get ad details first
      final adDoc = await _firestore.collection('ads').doc(adId).get();
      final adData = adDoc.data();
      
      if (adData == null) {
        throw Exception('Ad not found');
      }

      // Check if ad already has an expiration date
      final existingExpiresAt = adData['expiresAt'];
      final DateTime expirationDate;
      
      if (existingExpiresAt != null && existingExpiresAt is Timestamp) {
        // Use existing expiration date if it exists
        expirationDate = existingExpiresAt.toDate();
      } else {
        // Set expiration to 30 days from approval date
        expirationDate = DateTime.now().add(const Duration(days: 30));
      }

      await _firestore.collection('ads').doc(adId).update({
        'status': 'active',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'expiresAt': Timestamp.fromDate(expirationDate),
      });

      // Update user's ad count
      if (adData['userId'] != null) {
        await _firestore.collection('users').doc(adData['userId']).update({
          'activeAdsCount': FieldValue.increment(1),
        });
      }

      // Create activity log
      await _createActivityLog(
        type: 'adApproved',
        title: 'Ad approved',
        description: '${adData['title']} - ${adData['price']}',
        userId: adData['userId'],
        adId: adId,
        adminId: _auth.currentUser?.uid,
        metadata: {
          'adTitle': adData['title'],
          'adPrice': adData['price'],
          'adLocation': adData['location'],
        },
      );
    } catch (e) {
      print('Error approving ad: $e');
      rethrow;
    }
  }

  // Reject an ad
  Future<void> rejectAd(String adId, String reason) async {
    try {
      // Get ad details first
      final adDoc = await _firestore.collection('ads').doc(adId).get();
      final adData = adDoc.data();
      
      if (adData == null) {
        throw Exception('Ad not found');
      }

      await _firestore.collection('ads').doc(adId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectionReason': reason,
      });

      // Update user's ad count
      if (adData['userId'] != null) {
        await _firestore.collection('users').doc(adData['userId']).update({
          'rejectedAdsCount': FieldValue.increment(1),
        });
      }

      // Create activity log
      await _createActivityLog(
        type: 'adRejected',
        title: 'Ad rejected',
        description: '${adData['title']} - ${adData['price']}',
        userId: adData['userId'],
        adId: adId,
        adminId: _auth.currentUser?.uid,
        metadata: {
          'adTitle': adData['title'],
          'adPrice': adData['price'],
          'adLocation': adData['location'],
          'rejectionReason': reason,
        },
      );
    } catch (e) {
      print('Error rejecting ad: $e');
      rethrow;
    }
  }

  // Create activity log
  Future<void> _createActivityLog({
    required String type,
    required String title,
    required String description,
    String? userId,
    String? adId,
    String? adminId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('AdminService: Creating activity log - $type: $title');
      await _firestore.collection('activities').add({
        'type': type,
        'title': title,
        'description': description,
        'userId': userId,
        'adId': adId,
        'adminId': adminId,
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('AdminService: Activity log created successfully');
    } catch (e) {
      print('AdminService: Failed to create activity log: $e');
      // Don't rethrow - activity logging shouldn't break the main functionality
    }
  }

  // Debug method to check and fix ad statuses
  Future<void> debugAndFixAdStatuses() async {
    try {
      print('AdminService: Debugging ad statuses...');
      final allAdsSnapshot = await _firestore.collection('ads').get();
      
      print('AdminService: Total ads found: ${allAdsSnapshot.docs.length}');
      
      for (var doc in allAdsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        final title = data['title'] ?? 'No title';
        final userId = data['userId'] ?? 'No user ID';
        
        print('AdminService: Ad "${title}" (${doc.id}) - User: $userId - Status: $status');
        
        if (status == null || status == '') {
          print('AdminService: Found ad without status - "${title}" (${doc.id}), fixing...');
          try {
            await _firestore.collection('ads').doc(doc.id).update({
              'status': 'pending',
            });
            print('AdminService: Successfully updated status to pending for "${title}"');
          } catch (updateError) {
            print('AdminService: Error updating status for "${title}": $updateError');
          }
        } else if (status != 'pending' && status != 'active' && status != 'rejected') {
          print('AdminService: Found ad with invalid status - "${title}" (${doc.id}) - Status: $status, fixing...');
          try {
            await _firestore.collection('ads').doc(doc.id).update({
              'status': 'pending',
            });
            print('AdminService: Successfully updated invalid status to pending for "${title}"');
          } catch (updateError) {
            print('AdminService: Error updating invalid status for "${title}": $updateError');
          }
        }
      }
      
      print('AdminService: Ad status debugging complete');
    } catch (e) {
      print('AdminService: Error debugging ad statuses: $e');
    }
  }

  // Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      // Get user details first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        throw Exception('User not found');
      }

      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      // Create activity log
      await _createActivityLog(
        type: 'userRoleChanged',
        title: 'User role updated',
        description: '${userData['email']} - ${newRole}',
        userId: userId,
        adminId: _auth.currentUser?.uid,
        metadata: {
          'userEmail': userData['email'],
          'oldRole': userData['role'],
          'newRole': newRole,
        },
      );
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Deactivate/Activate user
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      // Get user details first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        throw Exception('User not found');
      }

      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });

      // Create activity log
      await _createActivityLog(
        type: 'userStatusChanged',
        title: isActive ? 'User activated' : 'User deactivated',
        description: '${userData['email']}',
        userId: userId,
        adminId: _auth.currentUser?.uid,
        metadata: {
          'userEmail': userData['email'],
          'newStatus': isActive,
        },
      );
    } catch (e) {
      print('Error toggling user status: $e');
      rethrow;
    }
  }

  // Get user details with ads
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data()!;
      final allAds = await _firestore.collection('ads').get();
      
      // Filter for user's ads and sort in memory
      final userAds = allAds.docs
          .where((doc) => doc.data()['userId'] == userId)
          .map((doc) => AdModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      userAds.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));

      return {
        'user': UserModel.fromFirestore(userData as Map<String, dynamic>, userId),
        'ads': userAds,
      };
    } catch (e) {
      print('Error getting user details: $e');
      rethrow;
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  // Search ads
  Future<List<AdModel>> searchAds(String query) async {
    try {
      final snapshot = await _firestore
          .collection('ads')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) => AdModel.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error searching ads: $e');
      rethrow;
    }
  }
}
