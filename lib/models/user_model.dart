import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String role; // 'user', 'admin', 'super_admin'
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final int totalAdsPosted;
  final int activeAdsCount;
  final int rejectedAdsCount;
  final int totalSales;
  final DateTime? lastSaleAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.role = 'user',
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
    this.totalAdsPosted = 0,
    this.activeAdsCount = 0,
    this.rejectedAdsCount = 0,
    this.totalSales = 0,
    this.lastSaleAt,
  });

  factory UserModel.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: _asString(data['email']),
      displayName: _asNullableString(data['displayName'] ?? data['fullName']),
      phoneNumber: _asNullableString(data['phoneNumber']),
      role: _normalizeRole(data['role']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(data['lastLoginAt']) ??
          _parseDateTime(data['updatedAt']) ??
          DateTime.now(),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      totalAdsPosted: _asInt(data['totalAdsPosted']),
      activeAdsCount: _asInt(data['activeAdsCount']),
      rejectedAdsCount: _asInt(data['rejectedAdsCount']),
      totalSales: _asInt(data['totalSales']),
      lastSaleAt: _parseDateTime(data['lastSaleAt']),
    );
  }

  static String _asString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String? _asNullableString(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _normalizeRole(dynamic role) {
    final normalized = role?.toString().trim().toLowerCase() ?? 'user';
    final underscored = normalized.replaceAll('-', '_').replaceAll(' ', '_');
    if (underscored == 'superadmin') {
      return 'super_admin';
    }
    return underscored.isEmpty ? 'user' : underscored;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isActive': isActive,
      'totalAdsPosted': totalAdsPosted,
      'activeAdsCount': activeAdsCount,
      'rejectedAdsCount': rejectedAdsCount,
      'totalSales': totalSales,
      'lastSaleAt': lastSaleAt != null ? Timestamp.fromDate(lastSaleAt!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    int? totalAdsPosted,
    int? activeAdsCount,
    int? rejectedAdsCount,
    int? totalSales,
    DateTime? lastSaleAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      totalAdsPosted: totalAdsPosted ?? this.totalAdsPosted,
      activeAdsCount: activeAdsCount ?? this.activeAdsCount,
      rejectedAdsCount: rejectedAdsCount ?? this.rejectedAdsCount,
      totalSales: totalSales ?? this.totalSales,
      lastSaleAt: lastSaleAt ?? this.lastSaleAt,
    );
  }
}
