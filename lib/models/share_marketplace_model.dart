import 'package:cloud_firestore/cloud_firestore.dart';

class ShareMarketplaceModel {
  final String id;
  final String investmentId;
  final String vehicleInvestmentId;
  final String sellerUserId;

  final double sharePercentage;
  final double askingPrice;
  final double originalInvestment;

  final String status; // active, sold, cancelled

  final String? buyerUserId;
  final DateTime? soldAt;
  final double? soldPrice;

  final DateTime listedAt;
  final DateTime? expiresAt;
  final String? description;

  ShareMarketplaceModel({
    required this.id,
    required this.investmentId,
    required this.vehicleInvestmentId,
    required this.sellerUserId,
    required this.sharePercentage,
    required this.askingPrice,
    required this.originalInvestment,
    this.status = 'active',
    this.buyerUserId,
    this.soldAt,
    this.soldPrice,
    required this.listedAt,
    this.expiresAt,
    this.description,
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

  // Helper: Convert anything → String
  static String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  // Factory: Convert Firestore document → ShareMarketplaceModel
  factory ShareMarketplaceModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return ShareMarketplaceModel(
      id: documentId,
      investmentId: _asString(data['investmentId']),
      vehicleInvestmentId: _asString(data['vehicleInvestmentId']),
      sellerUserId: _asString(data['sellerUserId']),
      sharePercentage: _asDouble(data['sharePercentage']),
      askingPrice: _asDouble(data['askingPrice']),
      originalInvestment: _asDouble(data['originalInvestment']),
      status: _asString(data['status']).isEmpty
          ? 'active'
          : _asString(data['status']),
      buyerUserId: _asString(data['buyerUserId']).isEmpty
          ? null
          : _asString(data['buyerUserId']),
      soldAt: _parseDate(data['soldAt']),
      soldPrice:
          data['soldPrice'] != null ? _asDouble(data['soldPrice']) : null,
      listedAt: _parseDate(data['listedAt']) ?? DateTime.now(),
      expiresAt: _parseDate(data['expiresAt']),
      description: _asString(data['description']).isEmpty
          ? null
          : _asString(data['description']),
    );
  }

  // Convert ShareMarketplaceModel → Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'investmentId': investmentId,
      'vehicleInvestmentId': vehicleInvestmentId,
      'sellerUserId': sellerUserId,
      'sharePercentage': sharePercentage,
      'askingPrice': askingPrice,
      'originalInvestment': originalInvestment,
      'status': status,
      'buyerUserId': buyerUserId,
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'soldPrice': soldPrice,
      'listedAt': Timestamp.fromDate(listedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'description': description,
    };
  }

  // Helper: Check if listing is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Helper: Check if listing is active
  bool get isActive => status == 'active' && !isExpired;

  // Helper: Calculate profit/loss for seller
  double get sellerProfitLoss {
    if (soldPrice == null) return 0.0;
    return soldPrice! - originalInvestment;
  }

  // Helper: Calculate premium/discount percentage
  double get priceChangePercentage {
    if (originalInvestment <= 0) return 0.0;
    return ((askingPrice - originalInvestment) / originalInvestment * 100);
  }
}

