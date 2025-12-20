import 'package:cloud_firestore/cloud_firestore.dart';

class InvestmentModel {
  final String id;
  final String vehicleInvestmentId;
  final String userId;

  final double amount;
  final double investmentRatio;
  final DateTime investmentDate;

  final String status; // pending, active, sold, refunded

  final bool sharesForSale;
  final double? sharesForSalePrice;
  final DateTime? sharesForSaleDate;

  final double totalProfitReceived;
  final DateTime? lastProfitDistributionDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  InvestmentModel({
    required this.id,
    required this.vehicleInvestmentId,
    required this.userId,
    required this.amount,
    required this.investmentRatio,
    required this.investmentDate,
    this.status = 'pending',
    this.sharesForSale = false,
    this.sharesForSalePrice,
    this.sharesForSaleDate,
    this.totalProfitReceived = 0.0,
    this.lastProfitDistributionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper: Parse Firestore dates
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // Helper: Parse double
  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper: Parse boolean
  static bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  // Factory: Convert Firestore document → InvestmentModel
  factory InvestmentModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return InvestmentModel(
      id: documentId,
      vehicleInvestmentId: data['vehicleInvestmentId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      amount: _asDouble(data['amount']),
      investmentRatio: _asDouble(data['investmentRatio']),
      investmentDate: _parseDate(data['investmentDate']) ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
      sharesForSale: _asBool(data['sharesForSale']),
      sharesForSalePrice: data['sharesForSalePrice'] != null
          ? _asDouble(data['sharesForSalePrice'])
          : null,
      sharesForSaleDate: _parseDate(data['sharesForSaleDate']),
      totalProfitReceived: _asDouble(data['totalProfitReceived'] ?? 0.0),
      lastProfitDistributionDate: _parseDate(data['lastProfitDistributionDate']),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  // Convert InvestmentModel → Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'vehicleInvestmentId': vehicleInvestmentId,
      'userId': userId,
      'amount': amount,
      'investmentRatio': investmentRatio,
      'investmentDate': Timestamp.fromDate(investmentDate),
      'status': status,
      'sharesForSale': sharesForSale,
      'sharesForSalePrice': sharesForSalePrice,
      'sharesForSaleDate': sharesForSaleDate != null
          ? Timestamp.fromDate(sharesForSaleDate!)
          : null,
      'totalProfitReceived': totalProfitReceived,
      'lastProfitDistributionDate': lastProfitDistributionDate != null
          ? Timestamp.fromDate(lastProfitDistributionDate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper: Calculate current value based on investment ratio
  double calculateCurrentValue(double vehicleCurrentValue) {
    return vehicleCurrentValue * investmentRatio;
  }

  // Helper: Calculate potential profit
  double calculatePotentialProfit(double salePrice, double totalInvestment, double platformFeePercentage) {
    final totalProfit = salePrice - totalInvestment;
    final platformFee = totalProfit * (platformFeePercentage / 100);
    final netProfit = totalProfit - platformFee;
    return netProfit * investmentRatio;
  }
}

