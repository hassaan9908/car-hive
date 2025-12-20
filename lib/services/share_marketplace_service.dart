import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/share_marketplace_model.dart';

class ShareMarketplaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all active share listings
  Stream<List<ShareMarketplaceModel>> getActiveShareListings() {
    return _firestore
        .collection('share_marketplace')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) =>
              ShareMarketplaceModel.fromFirestore(doc.data(), doc.id))
          .where((listing) {
        // Filter out expired listings
        if (listing.expiresAt != null && listing.expiresAt!.isBefore(now)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  // Get share listings for a specific vehicle
  Stream<List<ShareMarketplaceModel>> getShareListingsForVehicle(
      String vehicleInvestmentId) {
    return _firestore
        .collection('share_marketplace')
        .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) =>
              ShareMarketplaceModel.fromFirestore(doc.data(), doc.id))
          .where((listing) {
        if (listing.expiresAt != null && listing.expiresAt!.isBefore(now)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  // Get share listings by seller
  Stream<List<ShareMarketplaceModel>> getShareListingsBySeller(String userId) {
    return _firestore
        .collection('share_marketplace')
        .where('sellerUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ShareMarketplaceModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get share listing by ID
  Future<ShareMarketplaceModel?> getShareListingById(String id) async {
    try {
      final doc = await _firestore.collection('share_marketplace').doc(id).get();
      if (!doc.exists) return null;
      return ShareMarketplaceModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting share listing: $e');
      return null;
    }
  }

  // Create share listing
  Future<String> createShareListing({
    required String investmentId,
    required String vehicleInvestmentId,
    required String sellerUserId,
    required double sharePercentage,
    required double askingPrice,
    required double originalInvestment,
    DateTime? expiresAt,
    String? description,
  }) async {
    try {
      final listing = ShareMarketplaceModel(
        id: '', // Will be set by Firestore
        investmentId: investmentId,
        vehicleInvestmentId: vehicleInvestmentId,
        sellerUserId: sellerUserId,
        sharePercentage: sharePercentage,
        askingPrice: askingPrice,
        originalInvestment: originalInvestment,
        status: 'active',
        listedAt: DateTime.now(),
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
        description: description,
      );

      final docRef = await _firestore
          .collection('share_marketplace')
          .add(listing.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating share listing: $e');
      rethrow;
    }
  }

  // Update share listing
  Future<void> updateShareListing(
      String id, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('share_marketplace').doc(id).update(updates);
    } catch (e) {
      print('Error updating share listing: $e');
      rethrow;
    }
  }

  // Mark share listing as sold
  Future<void> markShareListingSold(
      String id, String buyerUserId, double soldPrice) async {
    try {
      await _firestore.collection('share_marketplace').doc(id).update({
        'status': 'sold',
        'buyerUserId': buyerUserId,
        'soldAt': FieldValue.serverTimestamp(),
        'soldPrice': soldPrice,
      });
    } catch (e) {
      print('Error marking share listing as sold: $e');
      rethrow;
    }
  }

  // Cancel share listing
  Future<void> cancelShareListing(String id) async {
    try {
      await _firestore.collection('share_marketplace').doc(id).update({
        'status': 'cancelled',
      });
    } catch (e) {
      print('Error canceling share listing: $e');
      rethrow;
    }
  }

  // Delete share listing
  Future<void> deleteShareListing(String id) async {
    try {
      await _firestore.collection('share_marketplace').doc(id).delete();
    } catch (e) {
      print('Error deleting share listing: $e');
      rethrow;
    }
  }
}

