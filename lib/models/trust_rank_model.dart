class TrustRankModel {
  final String userId;
  final double trustScore; // 0 - 100
  final String trustLevel; // Bronze, Silver, Gold
  final double responsivenessScore; // 0 - 100 (placeholder)
  final double profileCompleteness; // 0 - 100
  final double averageRating; // 0 - 5
  final int totalSales; // number of sold ads

  const TrustRankModel({
    required this.userId,
    required this.trustScore,
    required this.trustLevel,
    required this.responsivenessScore,
    required this.profileCompleteness,
    required this.averageRating,
    required this.totalSales,
  });

  Map<String, dynamic> toMap() {
    return {
      'trustScore': trustScore,
      'trustLevel': trustLevel,
      'responsivenessScore': responsivenessScore,
      'profileCompleteness': profileCompleteness,
      'averageRating': averageRating,
      'totalSales': totalSales,
      'trustUpdatedAt': DateTime.now().toIso8601String(),
    };
  }

  static TrustRankModel fromUserDoc(String userId, Map<String, dynamic> data) {
    return TrustRankModel(
      userId: userId,
      trustScore: (data['trustScore'] ?? 0).toDouble(),
      trustLevel: data['trustLevel'] ?? 'Bronze',
      responsivenessScore: (data['responsivenessScore'] ?? 0).toDouble(),
      profileCompleteness: (data['profileCompleteness'] ?? 0).toDouble(),
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalSales: (data['totalSales'] ?? 0) is int
          ? data['totalSales']
          : int.tryParse('${data['totalSales']}') ?? 0,
    );
  }
}
