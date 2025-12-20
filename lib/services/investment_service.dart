import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/investment_model.dart';

class InvestmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all investments for a user
  Stream<List<InvestmentModel>> getUserInvestments(String userId) {
    return _firestore
        .collection('investments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get active investments for a user
  Stream<List<InvestmentModel>> getUserActiveInvestments(String userId) {
    return _firestore
        .collection('investments')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all investments for a vehicle
  Stream<List<InvestmentModel>> getInvestmentsForVehicle(
      String vehicleInvestmentId) {
    return _firestore
        .collection('investments')
        .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get active investments for a vehicle
  Stream<List<InvestmentModel>> getActiveInvestmentsForVehicle(
      String vehicleInvestmentId) {
    return _firestore
        .collection('investments')
        .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvestmentModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get investment by ID
  Future<InvestmentModel?> getInvestmentById(String id) async {
    try {
      final doc = await _firestore.collection('investments').doc(id).get();
      if (!doc.exists) return null;
      return InvestmentModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting investment: $e');
      return null;
    }
  }

  // Create investment
  Future<String> createInvestment({
    required String vehicleInvestmentId,
    required double amount,
    required double totalInvestmentGoal,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Calculate investment ratio
      final investmentRatio = amount / totalInvestmentGoal;

      final investment = InvestmentModel(
        id: '', // Will be set by Firestore
        vehicleInvestmentId: vehicleInvestmentId,
        userId: user.uid,
        amount: amount,
        investmentRatio: investmentRatio,
        investmentDate: DateTime.now(),
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef =
          await _firestore.collection('investments').add(investment.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating investment: $e');
      rethrow;
    }
  }

  // Update investment
  Future<void> updateInvestment(String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('investments').doc(id).update(updates);
    } catch (e) {
      print('Error updating investment: $e');
      rethrow;
    }
  }

  // Activate investment (after payment confirmation)
  Future<void> activateInvestment(String id) async {
    try {
      await _firestore.collection('investments').doc(id).update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error activating investment: $e');
      rethrow;
    }
  }

  // Mark investment as sold (shares transferred)
  Future<void> markInvestmentSold(String id) async {
    try {
      await _firestore.collection('investments').doc(id).update({
        'status': 'sold',
        'sharesForSale': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking investment as sold: $e');
      rethrow;
    }
  }

  // Mark investment as refunded
  Future<void> markInvestmentRefunded(String id) async {
    try {
      await _firestore.collection('investments').doc(id).update({
        'status': 'refunded',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking investment as refunded: $e');
      rethrow;
    }
  }

  // List shares for sale
  Future<void> listSharesForSale({
    required String investmentId,
    required double askingPrice,
    String? description,
  }) async {
    try {
      await _firestore.collection('investments').doc(investmentId).update({
        'sharesForSale': true,
        'sharesForSalePrice': askingPrice,
        'sharesForSaleDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error listing shares for sale: $e');
      rethrow;
    }
  }

  // Cancel share sale listing
  Future<void> cancelShareSale(String investmentId) async {
    try {
      await _firestore.collection('investments').doc(investmentId).update({
        'sharesForSale': false,
        'sharesForSalePrice': null,
        'sharesForSaleDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error canceling share sale: $e');
      rethrow;
    }
  }

  // Update investment ownership (for share transfers)
  Future<void> transferInvestmentOwnership(
      String investmentId, String newUserId) async {
    try {
      await _firestore.collection('investments').doc(investmentId).update({
        'userId': newUserId,
        'sharesForSale': false,
        'sharesForSalePrice': null,
        'sharesForSaleDate': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error transferring investment ownership: $e');
      rethrow;
    }
  }

  // Update profit received
  Future<void> updateProfitReceived(String id, double profitAmount) async {
    try {
      final doc = await _firestore.collection('investments').doc(id).get();
      if (!doc.exists) return;

      final currentProfit = (doc.data()?['totalProfitReceived'] as num?)?.toDouble() ?? 0.0;
      final newTotal = currentProfit + profitAmount;

      await _firestore.collection('investments').doc(id).update({
        'totalProfitReceived': newTotal,
        'lastProfitDistributionDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating profit received: $e');
      rethrow;
    }
  }

  // Calculate investment ratio
  double calculateInvestmentRatio(double amount, double totalGoal) {
    if (totalGoal <= 0) return 0.0;
    return amount / totalGoal;
  }

  // Delete investment
  Future<void> deleteInvestment(String id) async {
    try {
      await _firestore.collection('investments').doc(id).delete();
    } catch (e) {
      print('Error deleting investment: $e');
      rethrow;
    }
  }
}

