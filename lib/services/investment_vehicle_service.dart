import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment_vehicle_model.dart';
import '../models/ad_model.dart';

class InvestmentVehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all investment vehicles
  Stream<List<InvestmentVehicleModel>> getAllInvestmentVehicles() {
    return _firestore
        .collection('investment_vehicles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentVehicleModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get investment vehicles by status
  Stream<List<InvestmentVehicleModel>> getInvestmentVehiclesByStatus(
      String status) {
    return _firestore
        .collection('investment_vehicles')
        .where('investmentStatus', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentVehicleModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get open investment vehicles (available for investment)
  Stream<List<InvestmentVehicleModel>> getOpenInvestmentVehicles() {
    return _firestore
        .collection('investment_vehicles')
        .where('investmentStatus', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) =>
              InvestmentVehicleModel.fromFirestore(doc.data(), doc.id))
          .where((vehicle) {
        // Filter out expired investments
        if (vehicle.expiresAt != null && vehicle.expiresAt!.isBefore(now)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  // Get investment vehicle by ID
  Future<InvestmentVehicleModel?> getInvestmentVehicleById(String id) async {
    try {
      final doc = await _firestore.collection('investment_vehicles').doc(id).get();
      if (!doc.exists) return null;
      return InvestmentVehicleModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting investment vehicle: $e');
      return null;
    }
  }

  // Get investment vehicles by initiator
  Stream<List<InvestmentVehicleModel>> getInvestmentVehiclesByInitiator(
      String userId) {
    return _firestore
        .collection('investment_vehicles')
        .where('initiatorUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentVehicleModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Create investment vehicle from ad
  Future<String> createInvestmentVehicle({
    required String adId,
    required double totalInvestmentGoal,
    required double minimumContribution,
    required DateTime expiresAt,
    String? description,
    double platformFeePercentage = 5.0,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get ad data
      final adDoc = await _firestore.collection('ads').doc(adId).get();
      if (!adDoc.exists) {
        throw Exception('Ad not found');
      }

      final adData = adDoc.data()!;
      final adModel = AdModel.fromFirestore(adData, adId);

      // Create investment vehicle
      final investmentVehicle = InvestmentVehicleModel(
        id: '', // Will be set by Firestore
        adId: adId,
        title: adModel.title,
        price: adModel.price,
        location: adModel.location,
        year: adModel.year,
        mileage: adModel.mileage,
        fuel: adModel.fuel,
        imageUrls: adModel.imageUrls,
        images360Urls: adModel.images360Urls,
        totalInvestmentGoal: totalInvestmentGoal,
        minimumContribution: minimumContribution,
        currentInvestment: 0.0,
        investmentStatus: 'open',
        initiatorUserId: user.uid,
        vehicleOwnerId: adModel.userId,
        profitDistributionMethod: 'proportional',
        platformFeePercentage: platformFeePercentage,
        vehicleStatus: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: expiresAt,
        description: description,
      );

      final docRef = await _firestore
          .collection('investment_vehicles')
          .add(investmentVehicle.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating investment vehicle: $e');
      rethrow;
    }
  }

  // Update investment vehicle
  Future<void> updateInvestmentVehicle(
      String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('investment_vehicles').doc(id).update(updates);
    } catch (e) {
      print('Error updating investment vehicle: $e');
      rethrow;
    }
  }

  // Update current investment amount
  Future<void> updateCurrentInvestment(
      String id, double additionalAmount) async {
    try {
      await _firestore.collection('investment_vehicles').doc(id).update({
        'currentInvestment': FieldValue.increment(additionalAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating current investment: $e');
      rethrow;
    }
  }

  // Check if funding is complete and update status
  Future<bool> checkFundingComplete(String id) async {
    try {
      final doc = await _firestore.collection('investment_vehicles').doc(id).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final currentInvestment = (data['currentInvestment'] as num?)?.toDouble() ?? 0.0;
      final totalGoal = (data['totalInvestmentGoal'] as num?)?.toDouble() ?? 0.0;

      if (currentInvestment >= totalGoal && data['investmentStatus'] == 'open') {
        await _firestore.collection('investment_vehicles').doc(id).update({
          'investmentStatus': 'funded',
          'fundedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking funding complete: $e');
      return false;
    }
  }

  // Mark vehicle as purchased
  Future<void> markVehiclePurchased(String id) async {
    try {
      await _firestore.collection('investment_vehicles').doc(id).update({
        'vehicleStatus': 'purchased',
        'purchaseDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking vehicle as purchased: $e');
      rethrow;
    }
  }

  // Mark vehicle as sold
  Future<void> markVehicleSold(String id, double salePrice) async {
    try {
      await _firestore.collection('investment_vehicles').doc(id).update({
        'vehicleStatus': 'sold',
        'investmentStatus': 'sold',
        'saleDate': FieldValue.serverTimestamp(),
        'salePrice': salePrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking vehicle as sold: $e');
      rethrow;
    }
  }

  // Close investment (when deadline expires and not fully funded)
  Future<void> closeInvestment(String id) async {
    try {
      await _firestore.collection('investment_vehicles').doc(id).update({
        'investmentStatus': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error closing investment: $e');
      rethrow;
    }
  }

  // Delete investment vehicle
  Future<void> deleteInvestmentVehicle(String id) async {
    try {
      await _firestore.collection('investment_vehicles').doc(id).delete();
    } catch (e) {
      print('Error deleting investment vehicle: $e');
      rethrow;
    }
  }
}

