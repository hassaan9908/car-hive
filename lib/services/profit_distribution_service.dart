import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/investment_model.dart';
import '../models/investment_transaction_model.dart';
import 'investment_vehicle_service.dart';
import 'investment_service.dart';
import 'investment_transaction_service.dart';

class ProfitDistributionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InvestmentVehicleService _vehicleService = InvestmentVehicleService();
  final InvestmentService _investmentService = InvestmentService();
  final InvestmentTransactionService _transactionService =
      InvestmentTransactionService();

  // Calculate profit distribution for all investors (Proportional Method)
  Future<Map<String, double>> calculateProfitDistribution(
      String vehicleInvestmentId) async {
    try {
      // Get investment vehicle
      final vehicle = await _vehicleService.getInvestmentVehicleById(vehicleInvestmentId);
      if (vehicle == null) {
        throw Exception('Investment vehicle not found');
      }

      if (vehicle.salePrice <= 0) {
        throw Exception('Sale price not set');
      }

      // Calculate total profit
      final totalProfit = vehicle.salePrice - vehicle.totalInvestmentGoal;
      if (totalProfit <= 0) {
        // No profit, return empty map
        return {};
      }

      // Calculate platform fee
      final platformFee = totalProfit * (vehicle.platformFeePercentage / 100);
      final netProfit = totalProfit - platformFee;

      // Get all active investments
      final investmentsSnapshot = await _firestore
          .collection('investments')
          .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
          .where('status', isEqualTo: 'active')
          .get();

      if (investmentsSnapshot.docs.isEmpty) {
        throw Exception('No active investments found');
      }

      // Calculate profit for each investor (Proportional Method)
      final profitDistribution = <String, double>{};

      for (final doc in investmentsSnapshot.docs) {
        final investment = InvestmentModel.fromFirestore(doc.data(), doc.id);
        
        // Proportional distribution: profit × investment ratio
        final investorProfit = netProfit * investment.investmentRatio;
        profitDistribution[investment.id] = investorProfit;
      }

      return profitDistribution;
    } catch (e) {
      print('Error calculating profit distribution: $e');
      rethrow;
    }
  }

  // Distribute profits to all investors
  Future<void> distributeProfits(String vehicleInvestmentId) async {
    try {
      // Calculate profit distribution
      final profitDistribution = await calculateProfitDistribution(vehicleInvestmentId);

      if (profitDistribution.isEmpty) {
        print('No profit to distribute');
        return;
      }

      // Get investment vehicle for metadata
      final vehicle = await _vehicleService.getInvestmentVehicleById(vehicleInvestmentId);
      if (vehicle == null) {
        throw Exception('Investment vehicle not found');
      }

      // Distribute profits to each investor
      for (final entry in profitDistribution.entries) {
        final investmentId = entry.key;
        final profitAmount = entry.value;

        // Update investment with profit received
        await _investmentService.updateProfitReceived(investmentId, profitAmount);

        // Get investment to get userId
        final investment = await _investmentService.getInvestmentById(investmentId);
        if (investment == null) continue;

        // Create profit distribution transaction
        await _transactionService.createTransaction(
          vehicleInvestmentId: vehicleInvestmentId,
          investmentId: investmentId,
          userId: investment.userId,
          type: 'profit_distribution',
          amount: profitAmount,
          status: 'pending',
          profitAmount: profitAmount,
          distributionDate: DateTime.now(),
          notes: 'Profit distribution from vehicle sale (Proportional Method)',
        );
      }

      print('Profit distribution completed for ${profitDistribution.length} investors');
    } catch (e) {
      print('Error distributing profits: $e');
      rethrow;
    }
  }

  // Process profit distribution payments (mark transactions as completed)
  Future<void> processProfitDistributionPayments(
      String vehicleInvestmentId) async {
    try {
      // Get all pending profit distribution transactions for this vehicle
      final transactionsSnapshot = await _firestore
          .collection('investment_transactions')
          .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
          .where('type', isEqualTo: 'profit_distribution')
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in transactionsSnapshot.docs) {
        // In a real implementation, this would integrate with payment gateway
        // For now, we'll mark them as completed
        // TODO: Integrate with payment gateway (JazzCash, EasyPay, etc.)
        await _transactionService.markTransactionCompleted(doc.id);
      }

      print('Profit distribution payments processed');
    } catch (e) {
      print('Error processing profit distribution payments: $e');
      rethrow;
    }
  }

  // Get profit distribution history for a vehicle
  Stream<List<InvestmentTransactionModel>> getProfitDistributionHistory(
      String vehicleInvestmentId) {
    return _firestore
        .collection('investment_transactions')
        .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
        .where('type', isEqualTo: 'profit_distribution')
        .orderBy('distributionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentTransactionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get profit distribution history for a user
  Stream<List<InvestmentTransactionModel>> getUserProfitHistory(String userId) {
    return _firestore
        .collection('investment_transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'profit_distribution')
        .orderBy('distributionDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              InvestmentTransactionModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Calculate total profit for a vehicle
  Future<double> calculateTotalProfit(String vehicleInvestmentId) async {
    try {
      final vehicle = await _vehicleService.getInvestmentVehicleById(vehicleInvestmentId);
      if (vehicle == null) {
        return 0.0;
      }

      if (vehicle.salePrice <= 0) {
        return 0.0;
      }

      final totalProfit = vehicle.salePrice - vehicle.totalInvestmentGoal;
      final platformFee = totalProfit * (vehicle.platformFeePercentage / 100);
      final netProfit = totalProfit - platformFee;

      return netProfit;
    } catch (e) {
      print('Error calculating total profit: $e');
      return 0.0;
    }
  }
}

