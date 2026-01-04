// import 'package:carhive/models/ad_model.dart';

// class GlobalAdStore {
//   static final GlobalAdStore _instance = GlobalAdStore._internal();
//   factory GlobalAdStore() => _instance;
//   GlobalAdStore._internal();

//   final List<AdModel> ads = [];

//   void addAd(AdModel ad) {
//     ads.add(ad);
//   }

//   List<AdModel> getByStatus(String status) =>
//       ads.where((ad) => ad.status == status).toList();

//   void updateStatus(String id, String s) {}
// }
//  new change 18 aug=-=-=-=-=
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/trust_rank_service.dart';

class GlobalAdStore {
  static final GlobalAdStore _instance = GlobalAdStore._internal();
  factory GlobalAdStore() => _instance;
  GlobalAdStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all active ads for the used cars tab (simplified query to avoid index issues)
  Stream<List<AdModel>> getAllActiveAds() {
    return _firestore.collection('ads').snapshots().map((snapshot) {
      final ads = snapshot.docs
          .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();

      // Filter for active ads that are not expired
      final activeAds = ads.where((ad) {
        if (ad.status != 'active') return false;
        // Check if ad is expired
        if (ad.expiresAt != null &&
            ad.expiresAt!.isBefore(now) &&
            ad.id != null) {
          // Mark as expired in background (async, don't block)
          unawaited(_markAdAsExpired(ad.id).catchError((e) {
            // Silently handle errors in background operation
            print('Error marking ad as expired: $e');
          }));
          return false;
        }
        return true;
      }).toList();

      // Sort in memory instead of in Firestore to avoid index requirements
      activeAds.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return activeAds;
    });
  }

  // Get all ads regardless of status
  Stream<List<AdModel>> getAllAds() {
    return _firestore.collection('ads').snapshots().map((snapshot) {
      final ads = snapshot.docs
          .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();

      // Filter out ads without status (they should be pending)
      // Also check and mark expired ads
      final validAds = ads.where((ad) {
        if (ad.status.isEmpty) return false;
        // Check if active ad is expired
        if (ad.status == 'active' &&
            ad.expiresAt != null &&
            ad.expiresAt!.isBefore(now) &&
            ad.id != null) {
          // Mark as expired in background (async, don't block)
          unawaited(_markAdAsExpired(ad.id).catchError((e) {
            // Silently handle errors in background operation
            print('Error marking ad as expired: $e');
          }));
          return true; // Still include in results for admin view
        }
        return true;
      }).toList();

      validAds.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return validAds;
    });
  }

  // Get ads for a specific user (simplified query)
  Stream<List<AdModel>> getUserAds(String userId) {
    return _firestore.collection('ads').snapshots().map((snapshot) {
      final ads = snapshot.docs
          .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();

      // Filter for user's ads only and check expiration
      final userAds = ads.where((ad) {
        if (ad.userId != userId) return false;
        // Check if ad is expired
        if (ad.expiresAt != null &&
            ad.expiresAt!.isBefore(now) &&
            ad.status == 'active' &&
            ad.id != null) {
          // Mark as expired in background (async, don't block)
          unawaited(_markAdAsExpired(ad.id).catchError((e) {
            // Silently handle errors in background operation
            print('Error marking ad as expired: $e');
          }));
          return true; // Still show expired ads to user so they know it expired
        }
        return true;
      }).toList();

      // Sort in memory
      userAds.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return userAds;
    });
  }

  // Get ads by status for a specific user (simplified query)
  Stream<List<AdModel>> getUserAdsByStatus(String userId, String status) {
    return _firestore.collection('ads').snapshots().map((snapshot) {
      final ads = snapshot.docs
          .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();

      // Filter for user's ads with specific status and check expiration
      final userAdsByStatus = ads.where((ad) {
        if (ad.userId != userId || ad.status != status) return false;
        // Check if ad is expired (only for active ads)
        if (status == 'active' &&
            ad.expiresAt != null &&
            ad.expiresAt!.isBefore(now) &&
            ad.id != null) {
          // Mark as expired in background (async, don't block)
          unawaited(_markAdAsExpired(ad.id).catchError((e) {
            // Silently handle errors in background operation
            print('Error marking ad as expired: $e');
          }));
          return true; // Still show expired ads to user
        }
        return true;
      }).toList();

      // Sort in memory
      userAdsByStatus.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return userAdsByStatus;
    });
  }

  // Get ads by multiple statuses for a specific user (e.g., removed + sold)
  Stream<List<AdModel>> getUserAdsByStatuses(
      String userId, List<String> statuses) {
    return _firestore.collection('ads').snapshots().map((snapshot) {
      final ads = snapshot.docs
          .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
          .toList();

      final now = DateTime.now();

      final userAds = ads.where((ad) {
        if (ad.userId != userId || !statuses.contains(ad.status)) return false;
        // Check if active ad is expired
        if (ad.status == 'active' &&
            ad.expiresAt != null &&
            ad.expiresAt!.isBefore(now) &&
            ad.id != null) {
          // Mark as expired in background (async, don't block)
          unawaited(_markAdAsExpired(ad.id).catchError((e) {
            // Silently handle errors in background operation
            print('Error marking ad as expired: $e');
          }));
          return true; // Still show expired ads to user
        }
        return true;
      }).toList();

      userAds.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return userAds;
    });
  }

  // Add a new ad
  Future<void> addAd(AdModel ad) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final adData = ad.toFirestore();
      adData['userId'] = currentUser.uid;
      adData['status'] =
          'pending'; // Set initial status as pending for admin review
      adData['createdAt'] = Timestamp.now();
      // Set expiration date to 30 days from now
      adData['expiresAt'] = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      );

      final docRef = await _firestore.collection('ads').add(adData);

      // Create activity log for new ad
      await _createActivityLog(
        type: 'adPosted',
        title: 'New ad pending review',
        description: '${ad.title} - ${ad.price}',
        userId: currentUser.uid,
        adId: docRef.id,
        metadata: {
          'adTitle': ad.title,
          'adPrice': ad.price,
          'adLocation': ad.location,
        },
      );
    } catch (e) {
      throw Exception('Failed to add ad: $e');
    }
  }

  // Add a new ad with vehicle verification (auto-approved)
  Future<void> addAdWithVerification(
      AdModel ad, Map<String, dynamic> encryptedVehicleData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check for duplicate registration number
      // Get the plain registration number (stored temporarily for hashing)
      final plainRegistrationNo =
          encryptedVehicleData['_plainRegistrationNo'] as String?;
      if (plainRegistrationNo != null && plainRegistrationNo.isNotEmpty) {
        // Normalize the registration number for consistent hashing
        final normalizedRegNo = plainRegistrationNo
            .trim()
            .toUpperCase()
            .replaceAll('*', '')
            .replaceAll(' ', '')
            .replaceAll(RegExp(r'[^\w\-]'), '');

        // Generate hash of registration number for duplicate checking
        final registrationHash = _hashRegistrationNo(normalizedRegNo);

        print(
            'Checking for duplicate registration number: $normalizedRegNo (hash: ${registrationHash.substring(0, 16)}...)');

        // Check if an ad with this registration number already exists
        // Only check active and pending ads - sold ads can be reposted
        try {
          final existingAdsQuery = await _firestore
              .collection('ads')
              .where('registrationNoHash', isEqualTo: registrationHash)
              .where('status', whereIn: [
                'active',
                'pending'
              ]) // Only check active and pending ads
              .limit(1)
              .get();

          if (existingAdsQuery.docs.isNotEmpty) {
            final existingAd = existingAdsQuery.docs.first;
            final existingAdData = existingAd.data();
            print(
                'Found existing ad with same registration number: ${existingAd.id}, status: ${existingAdData['status']}');
            throw Exception(
                'An ad with registration number "$normalizedRegNo" already exists. Each vehicle can only be listed once. Please check your existing ads or contact support if you believe this is an error.');
          }
        } catch (e) {
          // If the query fails (e.g., missing index), fall back to checking all ads
          if (e.toString().contains('index') ||
              e.toString().contains('indexes')) {
            print('Index error, falling back to broader query: $e');
            // Fallback: Check all ads and filter by status
            final fallbackQuery = await _firestore
                .collection('ads')
                .where('registrationNoHash', isEqualTo: registrationHash)
                .limit(10) // Get more to filter by status
                .get();

            // Filter to only check active and pending ads (sold ads can be reposted)
            final blockingAds = fallbackQuery.docs.where((doc) {
              final adData = doc.data();
              final status = adData['status'] as String? ?? 'unknown';
              return ['active', 'pending'].contains(status);
            }).toList();

            if (blockingAds.isNotEmpty) {
              final existingAd = blockingAds.first;
              final existingAdData = existingAd.data();
              final existingStatus =
                  existingAdData['status'] as String? ?? 'unknown';
              print(
                  'Found existing ad with same registration number: ${existingAd.id}, status: $existingStatus');
              throw Exception(
                  'An ad with registration number "$normalizedRegNo" already exists. Each vehicle can only be listed once. Please check your existing ads or contact support if you believe this is an error.');
            }
          } else {
            // Re-throw if it's not an index error
            rethrow;
          }
        }

        print('No duplicate found, proceeding with ad creation');
      }

      final adData = ad.toFirestore();
      adData['userId'] = currentUser.uid;
      adData['status'] = 'active'; // Auto-approved after verification
      adData['createdAt'] = Timestamp.now();
      adData['verifiedAt'] = Timestamp.now(); // Mark as verified
      adData['isVerified'] = true; // Flag to indicate automatic verification
      // Set expiration date to 30 days from now
      adData['expiresAt'] = Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      );

      // Remove temporary plain registration number before storing
      final vehicleDataToStore =
          Map<String, dynamic>.from(encryptedVehicleData);
      vehicleDataToStore.remove('_plainRegistrationNo');

      // Add encrypted vehicle verification data
      adData['vehicleVerification'] = vehicleDataToStore;

      // Add hash of registration number for duplicate checking (one-way hash for security)
      if (plainRegistrationNo != null && plainRegistrationNo.isNotEmpty) {
        // Normalize before hashing to ensure consistency
        final normalizedRegNo = plainRegistrationNo
            .trim()
            .toUpperCase()
            .replaceAll('*', '')
            .replaceAll(' ', '')
            .replaceAll(RegExp(r'[^\w\-]'), '');
        adData['registrationNoHash'] = _hashRegistrationNo(normalizedRegNo);
        print('Storing registration hash for: $normalizedRegNo');
      }

      final docRef = await _firestore.collection('ads').add(adData);

      // Create activity log for verified ad
      await _createActivityLog(
        type: 'adPosted',
        title: 'New ad posted (auto-verified)',
        description:
            '${ad.title} - ${ad.price} - Vehicle verified automatically',
        userId: currentUser.uid,
        adId: docRef.id,
        metadata: {
          'adTitle': ad.title,
          'adPrice': ad.price,
          'adLocation': ad.location,
          'verified': true,
        },
      );
    } catch (e) {
      throw Exception('Failed to add verified ad: $e');
    }
  }

  // Create activity log
  Future<void> _createActivityLog({
    required String type,
    required String title,
    required String description,
    String? userId,
    String? adId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('activities').add({
        'type': type,
        'title': title,
        'description': description,
        'userId': userId,
        'adId': adId,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to create activity log: $e');
    }
  }

  // Update ad status
  Future<void> updateAdStatus(String adId, String status) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update ad status: $e');
    }
  }

  /// Update an existing ad
  Future<void> updateAd(String adId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(adId).update(data);
    } catch (e) {
      throw Exception('Failed to update ad: $e');
    }
  }

  // Mark ad as removed and store previousStatus for reactivation
  Future<void> markRemoved(String adId,
      {required String previousStatus}) async {
    try {
      await _firestore.collection('ads').doc(adId).update({
        'status': 'removed',
        'previousStatus': previousStatus,
      });
      try {
        final adDoc = await _firestore.collection('ads').doc(adId).get();
        final ownerId = adDoc.data()?['userId'];
        if (ownerId is String && ownerId.isNotEmpty) {
          await _firestore.collection('users').doc(ownerId).set({
            'trustUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to mark removed: $e');
    }
  }

  // Mark ad as sold (clears previousStatus)
  Future<void> markSold(String adId) async {
    try {
      // First get the ad to find the owner
      final adDoc = await _firestore.collection('ads').doc(adId).get();
      final adData = adDoc.data();
      final ownerId = adData?['userId'] as String?;

      if (ownerId == null || ownerId.isEmpty) {
        throw Exception('Ad owner not found');
      }

      // Update ad status to sold
      await _firestore.collection('ads').doc(adId).update({
        'status': 'sold',
        'previousStatus': null,
        'soldAt': FieldValue.serverTimestamp(),
      });

      // Update user's sales count and trigger trust rank recompute
      await _updateUserSalesCount(ownerId);
    } catch (e) {
      throw Exception('Failed to mark sold: $e');
    }
  }

  // Helper method to update user's sales count and trust rank
  Future<void> _updateUserSalesCount(String userId) async {
    try {
      // Count current sales
      final soldAdsQuery = await _firestore
          .collection('ads')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'sold')
          .get();

      final totalSales = soldAdsQuery.docs.length;

      // Update user document with sales count and trigger trust rank recompute
      await _firestore.collection('users').doc(userId).set({
        'totalSales': totalSales,
        'trustUpdatedAt': FieldValue.serverTimestamp(),
        'lastSaleAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Trigger trust rank recomputation
      try {
        final trustRankService = TrustRankService();
        await trustRankService.recomputeAndSave(userId);
      } catch (e) {
        print('Error recomputing trust rank: $e');
      }
    } catch (e) {
      print('Error updating user sales count: $e');
    }
  }

  // Reactivate a removed ad to its previousStatus (defaults to 'active' if missing)
  Future<void> reactivateAd(String adId,
      {required String previousStatus}) async {
    try {
      // Set new expiration date to 30 days from reactivation
      final newExpirationDate = DateTime.now().add(const Duration(days: 30));

      await _firestore.collection('ads').doc(adId).update({
        'status': previousStatus.isNotEmpty ? previousStatus : 'active',
        'previousStatus': null,
        'expiresAt': Timestamp.fromDate(newExpirationDate),
      });
      try {
        final adDoc = await _firestore.collection('ads').doc(adId).get();
        final ownerId = adDoc.data()?['userId'];
        if (ownerId is String && ownerId.isNotEmpty) {
          await _firestore.collection('users').doc(ownerId).set({
            'trustUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to reactivate ad: $e');
    }
  }

  // Delete an ad
  Future<void> deleteAd(String adId) async {
    try {
      await _firestore.collection('ads').doc(adId).delete();
    } catch (e) {
      throw Exception('Failed to delete ad: $e');
    }
  }

  // Legacy methods for backward compatibility
  final List<AdModel> ads = [];

  void addAdLegacy(AdModel ad) {
    ads.add(ad);
  }

  List<AdModel> getByStatus(String status) =>
      ads.where((ad) => ad.status == status).toList();

  /// Generates a one-way hash of the registration number for duplicate checking
  ///
  /// This hash is used to check for duplicate ads without exposing the actual
  /// registration number. The hash is one-way, so the original value cannot
  /// be recovered from it.
  ///
  /// [registrationNo] - The registration number to hash (can be encrypted or plain)
  ///
  /// Returns a SHA-256 hash as a hex string
  String _hashRegistrationNo(String registrationNo) {
    if (registrationNo.isEmpty) return '';

    // Normalize the registration number consistently:
    // - Trim whitespace
    // - Convert to uppercase
    // - Remove asterisk (API sometimes returns with *)
    // - Remove all spaces
    // - Keep hyphens (they're part of the registration format like "LEN-310")
    // - Remove other special characters except hyphens
    var normalized = registrationNo
        .trim()
        .toUpperCase()
        .replaceAll('*', '')
        .replaceAll(' ', '') // Remove all spaces
        .replaceAll(
            RegExp(r'[^\w\-]'), ''); // Keep only alphanumeric and hyphens

    // If it's encrypted (base64), we still hash the encrypted value
    // This ensures consistent hashing regardless of encryption state
    final bytes = utf8.encode(normalized);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Marks an ad as expired (removed) if it has passed its expiration date
  ///
  /// This is called automatically when expired ads are detected during queries.
  ///
  /// [adId] - The ID of the ad to mark as expired
  Future<void> _markAdAsExpired(String? adId) async {
    if (adId == null || adId.isEmpty) return;

    try {
      final adDoc = await _firestore.collection('ads').doc(adId).get();
      if (!adDoc.exists) return;

      final adData = adDoc.data();
      final currentStatus = adData?['status'] as String?;

      // Only mark as expired if currently active
      if (currentStatus == 'active') {
        await _firestore.collection('ads').doc(adId).update({
          'status': 'removed',
          'previousStatus': 'active',
          'expiredAt': Timestamp.now(),
          'expirationReason': 'Ad expired after 30 days',
        });
      }
    } catch (e) {
      // Silently fail - this is a background operation
      print('Error marking ad as expired: $e');
    }
  }

  /// Cleanup expired ads - can be called periodically or on app start
  ///
  /// This method finds all active ads that have expired and marks them as removed.
  Future<void> cleanupExpiredAds() async {
    try {
      final now = Timestamp.now();
      final expiredAdsQuery = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'active')
          .where('expiresAt', isLessThan: now)
          .limit(100) // Process in batches
          .get();

      final batch = _firestore.batch();
      int batchCount = 0;

      for (final doc in expiredAdsQuery.docs) {
        batch.update(doc.reference, {
          'status': 'removed',
          'previousStatus': 'active',
          'expiredAt': Timestamp.now(),
          'expirationReason': 'Ad expired after 30 days',
        });
        batchCount++;

        // Firestore batch limit is 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Error cleaning up expired ads: $e');
    }
  }
}
