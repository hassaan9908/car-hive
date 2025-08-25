import 'package:carhive/models/ad_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalAdStore {
  static final GlobalAdStore _instance = GlobalAdStore._internal();
  factory GlobalAdStore() => _instance;
  GlobalAdStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all active ads for the used cars tab (simplified query to avoid index issues)
  Stream<List<AdModel>> getAllActiveAds() {
    return _firestore
        .collection('ads')
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs
              .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
              .toList();
          
          // Filter for active ads only
          final activeAds = ads.where((ad) => ad.status == 'active').toList();
          
          // Sort in memory instead of in Firestore to avoid index requirements
          activeAds.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return activeAds;
        });
  }

  // Get all ads regardless of status
  Stream<List<AdModel>> getAllAds() {
    return _firestore
        .collection('ads')
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs
              .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
              .toList();
          
          // Filter out ads without status (they should be pending)
          final validAds = ads.where((ad) => ad.status != null && ad.status.isNotEmpty && ad.status != '').toList();
          
          validAds.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return validAds;
        });
  }

  // Get ads for a specific user (simplified query)
  Stream<List<AdModel>> getUserAds(String userId) {
    return _firestore
        .collection('ads')
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs
              .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
              .toList();
          
          // Filter for user's ads only
          final userAds = ads.where((ad) => ad.userId == userId).toList();
          
          // Sort in memory
          userAds.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return userAds;
        });
  }

  // Get ads by status for a specific user (simplified query)
  Stream<List<AdModel>> getUserAdsByStatus(String userId, String status) {
    return _firestore
        .collection('ads')
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs
              .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
              .toList();
          
          // Filter for user's ads with specific status
          final userAdsByStatus = ads.where((ad) => 
              ad.userId == userId && ad.status == status).toList();
          
          // Sort in memory
          userAdsByStatus.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return userAdsByStatus;
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
      adData['status'] = 'pending'; // Set initial status as pending for admin review
      adData['createdAt'] = Timestamp.now();

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
}
