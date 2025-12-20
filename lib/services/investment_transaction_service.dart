import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment_transaction_model.dart';

class InvestmentTransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all transactions for a user
  Stream<List<InvestmentTransactionModel>> getUserTransactions(String userId) {
    return _firestore
        .collection('investment_transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentTransactionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get transactions for a vehicle
  Stream<List<InvestmentTransactionModel>> getVehicleTransactions(
      String vehicleInvestmentId) {
    return _firestore
        .collection('investment_transactions')
        .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentTransactionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get transactions by type
  Stream<List<InvestmentTransactionModel>> getTransactionsByType(
      String userId, String type) {
    return _firestore
        .collection('investment_transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentTransactionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get transaction by ID
  Future<InvestmentTransactionModel?> getTransactionById(String id) async {
    try {
      final doc =
          await _firestore.collection('investment_transactions').doc(id).get();
      if (!doc.exists) return null;
      return InvestmentTransactionModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  // Create transaction
  Future<String> createTransaction({
    required String vehicleInvestmentId,
    String? investmentId,
    required String userId,
    required String type,
    required double amount,
    String status = 'pending',
    String? paymentMethod,
    String? paymentReference,
    double? profitAmount,
    DateTime? distributionDate,
    double? sharePrice,
    double? sharePercentage,
    String? notes,
  }) async {
    try {
      final transaction = InvestmentTransactionModel(
        id: '', // Will be set by Firestore
        vehicleInvestmentId: vehicleInvestmentId,
        investmentId: investmentId,
        userId: userId,
        type: type,
        amount: amount,
        status: status,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        profitAmount: profitAmount,
        distributionDate: distributionDate,
        sharePrice: sharePrice,
        sharePercentage: sharePercentage,
        createdAt: DateTime.now(),
        notes: notes,
      );

      final docRef = await _firestore
          .collection('investment_transactions')
          .add(transaction.toFirestore());

      return docRef.id;
    } catch (e) {
      print('Error creating transaction: $e');
      rethrow;
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(
      String id, String status, {DateTime? completedAt}) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (completedAt != null) {
        updates['completedAt'] = Timestamp.fromDate(completedAt);
      } else if (status == 'completed') {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('investment_transactions')
          .doc(id)
          .update(updates);
    } catch (e) {
      print('Error updating transaction status: $e');
      rethrow;
    }
  }

  // Update transaction payment details
  Future<void> updateTransactionPayment(
      String id, String paymentMethod, String paymentReference) async {
    try {
      await _firestore.collection('investment_transactions').doc(id).update({
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
      });
    } catch (e) {
      print('Error updating transaction payment: $e');
      rethrow;
    }
  }

  // Mark transaction as completed
  Future<void> markTransactionCompleted(String id) async {
    try {
      await _firestore.collection('investment_transactions').doc(id).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking transaction as completed: $e');
      rethrow;
    }
  }

  // Mark transaction as failed
  Future<void> markTransactionFailed(String id, {String? notes}) async {
    try {
      final updates = <String, dynamic>{
        'status': 'failed',
      };
      if (notes != null) {
        updates['notes'] = notes;
      }
      await _firestore.collection('investment_transactions').doc(id).update(updates);
    } catch (e) {
      print('Error marking transaction as failed: $e');
      rethrow;
    }
  }

  // Mark transaction as refunded
  Future<void> markTransactionRefunded(String id) async {
    try {
      await _firestore.collection('investment_transactions').doc(id).update({
        'status': 'refunded',
      });
    } catch (e) {
      print('Error marking transaction as refunded: $e');
      rethrow;
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.collection('investment_transactions').doc(id).delete();
    } catch (e) {
      print('Error deleting transaction: $e');
      rethrow;
    }
  }
}

