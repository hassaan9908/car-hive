import 'package:cloud_firestore/cloud_firestore.dart';

class InvestmentTransactionModel {
  final String id;
  final String vehicleInvestmentId;
  final String? investmentId;
  final String userId;

  final String type; // investment, profit_distribution, share_sale, share_purchase, refund
  final double amount;
  final String status; // pending, completed, failed, refunded

  final String? paymentMethod; // jazzcash, easypay, bank_transfer, card, stripe
  final String? paymentReference;
  final String? stripePaymentIntentId;
  final String? stripePayoutId;
  final String? payoutStatus;

  final double? profitAmount; // For profit distribution transactions
  final DateTime? distributionDate;

  final double? sharePrice; // For share transactions
  final double? sharePercentage;

  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  InvestmentTransactionModel({
    required this.id,
    required this.vehicleInvestmentId,
    this.investmentId,
    required this.userId,
    required this.type,
    required this.amount,
    this.status = 'pending',
    this.paymentMethod,
    this.paymentReference,
    this.stripePaymentIntentId,
    this.stripePayoutId,
    this.payoutStatus,
    this.profitAmount,
    this.distributionDate,
    this.sharePrice,
    this.sharePercentage,
    required this.createdAt,
    this.completedAt,
    this.notes,
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

  // Factory: Convert Firestore document → InvestmentTransactionModel
  factory InvestmentTransactionModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return InvestmentTransactionModel(
      id: documentId,
      vehicleInvestmentId: _asString(data['vehicleInvestmentId']),
      investmentId: _asString(data['investmentId']).isEmpty
          ? null
          : _asString(data['investmentId']),
      userId: _asString(data['userId']),
      type: _asString(data['type']),
      amount: _asDouble(data['amount']),
      status: _asString(data['status']).isEmpty
          ? 'pending'
          : _asString(data['status']),
      paymentMethod: _asString(data['paymentMethod']).isEmpty
          ? null
          : _asString(data['paymentMethod']),
      paymentReference: _asString(data['paymentReference']).isEmpty
          ? null
          : _asString(data['paymentReference']),
      stripePaymentIntentId: _asString(data['stripePaymentIntentId']).isEmpty
          ? null
          : _asString(data['stripePaymentIntentId']),
      stripePayoutId: _asString(data['stripePayoutId']).isEmpty
          ? null
          : _asString(data['stripePayoutId']),
      payoutStatus: _asString(data['payoutStatus']).isEmpty
          ? null
          : _asString(data['payoutStatus']),
      profitAmount: data['profitAmount'] != null
          ? _asDouble(data['profitAmount'])
          : null,
      distributionDate: _parseDate(data['distributionDate']),
      sharePrice:
          data['sharePrice'] != null ? _asDouble(data['sharePrice']) : null,
      sharePercentage: data['sharePercentage'] != null
          ? _asDouble(data['sharePercentage'])
          : null,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      completedAt: _parseDate(data['completedAt']),
      notes: _asString(data['notes']).isEmpty ? null : _asString(data['notes']),
    );
  }

  // Convert InvestmentTransactionModel → Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'vehicleInvestmentId': vehicleInvestmentId,
      'investmentId': investmentId,
      'userId': userId,
      'type': type,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripePayoutId': stripePayoutId,
      'payoutStatus': payoutStatus,
      'profitAmount': profitAmount,
      'distributionDate': distributionDate != null
          ? Timestamp.fromDate(distributionDate!)
          : null,
      'sharePrice': sharePrice,
      'sharePercentage': sharePercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
    };
  }

  // Helper: Check if transaction is completed
  bool get isCompleted => status == 'completed';

  // Helper: Check if transaction failed
  bool get isFailed => status == 'failed';

  // Helper: Check if transaction is pending
  bool get isPending => status == 'pending';
}

