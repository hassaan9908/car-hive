import 'package:cloud_firestore/cloud_firestore.dart';

class InvestmentVehicleModel {
  final String id;
  final String adId;
  final String title;
  final String price;
  final String location;
  final String year;
  final String mileage;
  final String fuel;
  final List<String>? imageUrls;
  final List<String>? images360Urls;

  // Investment fields
  final double totalInvestmentGoal;
  final double minimumContribution;
  final double currentInvestment;
  final String investmentStatus; // open, funded, closed, sold
  final DateTime? fundedAt;
  final DateTime? closedAt;

  final String initiatorUserId;
  final String? vehicleOwnerId;

  final String profitDistributionMethod; // "proportional" or "equal"
  final double platformFeePercentage;

  final String vehicleStatus; // pending, purchased, maintenance, rented, sold
  final DateTime? purchaseDate;
  final DateTime? saleDate;
  final double salePrice;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final String? description;

  InvestmentVehicleModel({
    required this.id,
    required this.adId,
    required this.title,
    required this.price,
    required this.location,
    required this.year,
    required this.mileage,
    required this.fuel,
    this.imageUrls,
    this.images360Urls,
    required this.totalInvestmentGoal,
    required this.minimumContribution,
    required this.currentInvestment,
    required this.investmentStatus,
    this.fundedAt,
    this.closedAt,
    required this.initiatorUserId,
    this.vehicleOwnerId,
    this.profitDistributionMethod = 'proportional',
    this.platformFeePercentage = 5.0,
    this.vehicleStatus = 'pending',
    this.purchaseDate,
    this.saleDate,
    this.salePrice = 0.0,
    required this.createdAt,
    required this.updatedAt,
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

  // Helper: Convert anything → String
  static String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  // Helper: Parse image URLs
  static List<String>? _parseImageUrls(dynamic raw) {
    if (raw == null) return null;

    if (raw is List) {
      final List<String> out = [];
      for (final item in raw) {
        if (item == null) continue;
        if (item is String) {
          out.add(item);
        }
      }
      return out.isEmpty ? null : out;
    }

    if (raw is String && raw.isNotEmpty) return [raw];
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

  // Factory: Convert Firestore document → InvestmentVehicleModel
  factory InvestmentVehicleModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return InvestmentVehicleModel(
      id: documentId,
      adId: _asString(data['adId']),
      title: _asString(data['title']),
      price: _asString(data['price']),
      location: _asString(data['location']),
      year: _asString(data['year']),
      mileage: _asString(data['mileage']),
      fuel: _asString(data['fuel']),
      imageUrls: _parseImageUrls(data['imageUrls']),
      images360Urls: _parseImageUrls(data['images360Urls']),
      totalInvestmentGoal: _asDouble(data['totalInvestmentGoal']),
      minimumContribution: _asDouble(data['minimumContribution']),
      currentInvestment: _asDouble(data['currentInvestment'] ?? 0.0),
      investmentStatus: _asString(data['investmentStatus']).isEmpty
          ? 'open'
          : _asString(data['investmentStatus']),
      fundedAt: _parseDate(data['fundedAt']),
      closedAt: _parseDate(data['closedAt']),
      initiatorUserId: _asString(data['initiatorUserId']),
      vehicleOwnerId: _asString(data['vehicleOwnerId']).isEmpty
          ? null
          : _asString(data['vehicleOwnerId']),
      profitDistributionMethod: _asString(data['profitDistributionMethod'])
              .isEmpty
          ? 'proportional'
          : _asString(data['profitDistributionMethod']),
      platformFeePercentage: _asDouble(data['platformFeePercentage'] ?? 5.0),
      vehicleStatus: _asString(data['vehicleStatus']).isEmpty
          ? 'pending'
          : _asString(data['vehicleStatus']),
      purchaseDate: _parseDate(data['purchaseDate']),
      saleDate: _parseDate(data['saleDate']),
      salePrice: _asDouble(data['salePrice'] ?? 0.0),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
      expiresAt: _parseDate(data['expiresAt']),
      description: _asString(data['description']).isEmpty
          ? null
          : _asString(data['description']),
    );
  }

  // Convert InvestmentVehicleModel → Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'adId': adId,
      'title': title,
      'price': price,
      'location': location,
      'year': year,
      'mileage': mileage,
      'fuel': fuel,
      'imageUrls': imageUrls,
      'images360Urls': images360Urls,
      'totalInvestmentGoal': totalInvestmentGoal,
      'minimumContribution': minimumContribution,
      'currentInvestment': currentInvestment,
      'investmentStatus': investmentStatus,
      'fundedAt': fundedAt != null ? Timestamp.fromDate(fundedAt!) : null,
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'initiatorUserId': initiatorUserId,
      'vehicleOwnerId': vehicleOwnerId,
      'profitDistributionMethod': profitDistributionMethod,
      'platformFeePercentage': platformFeePercentage,
      'vehicleStatus': vehicleStatus,
      'purchaseDate':
          purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
      'saleDate': saleDate != null ? Timestamp.fromDate(saleDate!) : null,
      'salePrice': salePrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'description': description,
    };
  }

  // Helper: Calculate funding progress percentage
  double get fundingProgress {
    if (totalInvestmentGoal <= 0) return 0.0;
    return (currentInvestment / totalInvestmentGoal * 100).clamp(0.0, 100.0);
  }

  // Helper: Check if fully funded
  bool get isFullyFunded {
    return currentInvestment >= totalInvestmentGoal;
  }

  // Helper: Get remaining amount needed
  double get remainingAmount {
    return (totalInvestmentGoal - currentInvestment).clamp(0.0, totalInvestmentGoal);
  }

  // Helper: Check if expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

