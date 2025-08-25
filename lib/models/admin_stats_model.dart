class AdminStatsModel {
  final int totalUsers;
  final int totalAds;
  final int pendingAds;
  final int activeAds;
  final int rejectedAds;
  final int totalRevenue;
  final DateTime lastUpdated;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalAds,
    required this.pendingAds,
    required this.activeAds,
    required this.rejectedAds,
    required this.totalRevenue,
    required this.lastUpdated,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      totalUsers: json['totalUsers'] ?? 0,
      totalAds: json['totalAds'] ?? 0,
      pendingAds: json['pendingAds'] ?? 0,
      activeAds: json['activeAds'] ?? 0,
      rejectedAds: json['rejectedAds'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalAds': totalAds,
      'pendingAds': pendingAds,
      'activeAds': activeAds,
      'rejectedAds': rejectedAds,
      'totalRevenue': totalRevenue,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  AdminStatsModel copyWith({
    int? totalUsers,
    int? totalAds,
    int? pendingAds,
    int? activeAds,
    int? rejectedAds,
    int? totalRevenue,
    DateTime? lastUpdated,
  }) {
    return AdminStatsModel(
      totalUsers: totalUsers ?? this.totalUsers,
      totalAds: totalAds ?? this.totalAds,
      pendingAds: pendingAds ?? this.pendingAds,
      activeAds: activeAds ?? this.activeAds,
      rejectedAds: rejectedAds ?? this.rejectedAds,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}


