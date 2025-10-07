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
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      role: data['role'] ?? 'user',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      totalAdsPosted: data['totalAdsPosted'] ?? 0,
      activeAdsCount: data['activeAdsCount'] ?? 0,
      rejectedAdsCount: data['rejectedAdsCount'] ?? 0,
      totalSales: data['totalSales'] ?? 0,
      lastSaleAt: data['lastSaleAt'] != null
          ? (data['lastSaleAt'] as Timestamp).toDate()
          : null,
    );
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
