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
import 'package:carhive/models/ad_model.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalAdStore {
  static final GlobalAdStore _instance = GlobalAdStore._();
  GlobalAdStore._();
  factory GlobalAdStore() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all active ads for the used cars tab (simplified query to avoid index issues)
  Stream<List<AdModel>> getAllActiveAds() {
    return _firestore
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs
              .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
              .toList();
          // Sort in memory instead of in Firestore to avoid index requirements
          ads.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return ads;
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
          ads.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return ads;
        });
  }

  // Get ads for a specific user (simplified query)
  Stream<List<AdModel>> getUserAds(String userId) {
    return _firestore
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs
              .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
              .toList();
          // Sort in memory
          ads.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return ads;
        });
  }

  // Get ads by status for a specific user (simplified query)
  Stream<List<AdModel>> getUserAdsByStatus(String userId, String status) {
    return _firestore
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          final ads = snapshot.docs
              .map((doc) => AdModel.fromFirestore(doc.data(), doc.id))
              .toList();
          // Sort in memory
          ads.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return ads;
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
      adData['createdAt'] = Timestamp.now();

      await _firestore.collection('ads').add(adData);
    } catch (e) {
      throw Exception('Failed to add ad: $e');
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
      _ads.where((a) => a.status == status).toList();

  // ⟵ Add this:
  void updateStatus(String id, String newStatus) {
    final i = _ads.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final a = _ads[i];
    _ads[i] = AdModel(
      id: a.id,
      photos: a.photos,
      location: a.location,
      carModel: a.carModel,
      brand: a.brand,
      registeredCity: a.registeredCity,
      bodyColor: a.bodyColor,
      kmsDriven: a.kmsDriven,
      price: a.price,
      description: a.description,
      phoneNumber: a.phoneNumber,
      fuel: a.fuel,
      year: a.year,
      status: newStatus,       // ⟵ changed here
      userId: a.userId,
      createdAt: a.createdAt,
    );
  }
}

