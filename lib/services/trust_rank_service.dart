import 'package:cloud_firestore/cloud_firestore.dart';

class TrustRankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public entry: recompute and persist trust metrics for a user
  Future<void> recomputeAndSave(String userId) async {
    final averages = await _computeAggregates(userId);
    final profileCompleteness = await _computeProfileCompleteness(userId);
    final responsiveness = await _estimateResponsiveness(userId);

    // Weighted score (simple baseline)
    // rating 40%, sales 30%, responsiveness 20%, profile 10%
    final ratingScore = (averages['avgRating'] as double) / 5.0 * 100.0;
    final salesScore = _clamp((averages['totalSales'] as int) * 10.0, 0.0,
        100.0); // 10 pts per sale capped at 100
    final respScore = responsiveness; // already 0-100
    final profScore = profileCompleteness; // 0-100

    final trustScore = (0.4 * ratingScore) +
        (0.3 * salesScore) +
        (0.2 * respScore) +
        (0.1 * profScore);
    final trustLevel = _levelForScore(trustScore);

    await _firestore.collection('users').doc(userId).set({
      'trustScore': trustScore,
      'trustLevel': trustLevel,
      'averageRating': averages['avgRating'],
      'totalSales': averages['totalSales'],
      'responsivenessScore': respScore,
      'profileCompleteness': profScore,
      'trustUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Admin/maintenance: recompute trust for all users once
  Future<void> recomputeForAllUsers() async {
    final snap = await _firestore.collection('users').get();
    for (final doc in snap.docs) {
      try {
        await recomputeAndSave(doc.id);
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> _computeAggregates(String userId) async {
    // Average rating from reviews where ad owner is the user
    // and total sales from ads marked 'sold'
    double avgRating = 0.0;
    int ratingCount = 0;
    int totalSales = 0;
    int totalRating = 0;

    // Compute sales
    final adsSnap = await _firestore
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in adsSnap.docs) {
      final data = doc.data();
      if (data['status'] == 'sold') totalSales += 1;
    }

    // Compute ratings: reviews for user's ads from new reviews collection
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('adOwnerId', isEqualTo: userId)
        .get();

    for (final reviewDoc in reviewsSnapshot.docs) {
      final reviewData = reviewDoc.data();
      final ratingVal = reviewData['rating'];
      if (ratingVal is int) {
        totalRating += ratingVal;
        ratingCount += 1;
      }
    }
    if (ratingCount > 0) {
      avgRating = totalRating / ratingCount;
    }

    return {
      'avgRating': avgRating,
      'totalSales': totalSales,
    };
  }

  Future<double> _computeProfileCompleteness(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data() ?? {};

    int fieldsPresent = 0;
    int totalFields = 5; // displayName, phoneNumber, createdAt, isActive, email

    if ((data['displayName'] ?? '').toString().isNotEmpty) fieldsPresent++;
    if ((data['phoneNumber'] ?? '').toString().isNotEmpty) fieldsPresent++;
    if (data['createdAt'] != null) fieldsPresent++;
    if (data['isActive'] != null) fieldsPresent++;
    if ((data['email'] ?? '').toString().isNotEmpty) fieldsPresent++;

    return (fieldsPresent / totalFields) * 100.0;
  }

  // Placeholder responsiveness estimate: uses activity timestamps if available
  Future<double> _estimateResponsiveness(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data() ?? {};

      // avgResponseMs: average time to respond (milliseconds). Lower is better.
      // messagesResponded/messagesReceived: compute a response rate.
      final avgResponseMs = _asInt(data['avgResponseMs']);
      final messagesResponded = _asInt(data['messagesResponded']);
      final messagesReceived = _asInt(data['messagesReceived']);

      double rateScore = 0.0;
      if (messagesReceived > 0) {
        final rate = messagesResponded / messagesReceived;
        rateScore = (rate.clamp(0.0, 1.0)) * 100.0; // 0-100
      }

      double timeScore;
      if (avgResponseMs <= 0) {
        timeScore = 60.0; // unknown baseline
      } else if (avgResponseMs <= 60 * 60 * 1000) {
        // <= 1h
        timeScore = 100.0;
      } else if (avgResponseMs <= 24 * 60 * 60 * 1000) {
        // <= 24h
        timeScore = 70.0;
      } else if (avgResponseMs <= 72 * 60 * 60 * 1000) {
        // <= 72h
        timeScore = 40.0;
      } else {
        timeScore = 20.0;
      }

      // Weighted responsiveness: 70% time, 30% response rate
      return 0.7 * timeScore + 0.3 * rateScore;
    } catch (_) {
      return 60.0;
    }
  }

  String _levelForScore(double score) {
    if (score >= 80.0) return 'Gold';
    if (score >= 50.0) return 'Silver';
    return 'Bronze';
  }

  double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
