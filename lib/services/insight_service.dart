import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record a view event for an ad
  Future<void> recordView(String adId) async {
    if (adId.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    print('InsightService.recordView: Starting for adId: $adId');

    try {
      final statsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('stats');

      final eventsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('events')
          .collection('items');

      await statsRef.set({
        'views': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await eventsRef.add({
        'type': 'view',
        'userId': currentUser.uid,
        'ts': FieldValue.serverTimestamp(),
      });
      print('InsightService.recordView: Successfully recorded');
    } catch (e) {
      print('Error recording view: $e');
    }
  }

  /// Record a contact click (phone call) event
  Future<void> recordContactClick(String adId) async {
    if (adId.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    print('InsightService.recordContactClick: Starting for adId: $adId');

    try {
      final statsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('stats');

      final eventsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('events')
          .collection('items');

      await statsRef.set({
        'contacts': FieldValue.increment(1),
        'lastContactAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await eventsRef.add({
        'type': 'contact',
        'userId': currentUser.uid,
        'ts': FieldValue.serverTimestamp(),
      });
      print('InsightService.recordContactClick: Successfully recorded');
    } catch (e) {
      print('Error recording contact: $e');
    }
  }

  /// Record a message sent event
  Future<void> recordMessageSent(String adId) async {
    if (adId.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    print('InsightService.recordMessageSent: Starting for adId: $adId');

    try {
      final statsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('stats');

      final eventsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('events')
          .collection('items');

      await statsRef.set({
        'messages': FieldValue.increment(1),
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await eventsRef.add({
        'type': 'message',
        'userId': currentUser.uid,
        'ts': FieldValue.serverTimestamp(),
      });
      print('InsightService.recordMessageSent: Successfully recorded');
    } catch (e) {
      print('Error recording message: $e');
    }
  }

  /// Record a save/bookmark event
  Future<void> recordSave(String adId) async {
    if (adId.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    print('InsightService: Recording save for adId: $adId');

    try {
      final statsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('stats');

      final eventsRef = _firestore
          .collection('ads')
          .doc(adId)
          .collection('insights')
          .doc('events')
          .collection('items');

      await statsRef.set({
        'saves': FieldValue.increment(1),
        'lastSavedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('InsightService: Stats updated successfully');

      await eventsRef.add({
        'type': 'save',
        'userId': currentUser.uid,
        'ts': FieldValue.serverTimestamp(),
      });

      print('InsightService: Event added successfully');
    } catch (e) {
      print('Error recording save: $e');
    }
  }

  /// Get insights stats for an ad
  Stream<Map<String, dynamic>> getAdInsights(String adId) {
    if (adId.isEmpty) {
      return Stream.value({});
    }

    return _firestore
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('stats')
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  /// Get daily events for chart (last N days)
  Stream<Map<String, Map<String, int>>> getDailyEvents(String adId,
      {int days = 14}) {
    if (adId.isEmpty) {
      return Stream.value({});
    }

    final since =
        Timestamp.fromDate(DateTime.now().subtract(Duration(days: days)));

    return _firestore
        .collection('ads')
        .doc(adId)
        .collection('insights')
        .doc('events')
        .collection('items')
        .where('ts', isGreaterThan: since)
        .snapshots()
        .map((snap) {
      Map<String, Map<String, int>> dailyData = {};

      for (var doc in snap.docs) {
        final data = doc.data();
        final ts = (data['ts'] as Timestamp?)?.toDate() ?? DateTime.now();
        final type = data['type'] as String? ?? 'view';
        final key =
            "${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}";

        dailyData[key] ??= {'view': 0, 'contact': 0, 'message': 0, 'save': 0};
        dailyData[key]![type] = (dailyData[key]![type] ?? 0) + 1;
      }

      return dailyData;
    });
  }

  /// Get platform-wide total views from all ads
  Future<int> getTotalPlatformViews() async {
    try {
      final adsSnapshot = await _firestore.collection('ads').get();
      int totalViews = 0;

      for (var doc in adsSnapshot.docs) {
        // Get views from the insights subcollection
        final insightsDoc = await _firestore
            .collection('ads')
            .doc(doc.id)
            .collection('insights')
            .doc('stats')
            .get();

        if (insightsDoc.exists) {
          totalViews += (insightsDoc.data()?['views'] ?? 0) as int;
        }
      }
      return totalViews;
    } catch (e) {
      print('Error getting total views: $e');
      return 0;
    }
  }

  /// Get platform-wide total messages from all ads
  Future<int> getTotalPlatformMessages() async {
    try {
      final adsSnapshot = await _firestore.collection('ads').get();
      int totalMessages = 0;

      for (var doc in adsSnapshot.docs) {
        final insightsDoc = await _firestore
            .collection('ads')
            .doc(doc.id)
            .collection('insights')
            .doc('stats')
            .get();

        if (insightsDoc.exists) {
          totalMessages += (insightsDoc.data()?['messages'] ?? 0) as int;
        }
      }
      return totalMessages;
    } catch (e) {
      print('Error getting total messages: $e');
      return 0;
    }
  }

  /// Get platform-wide total contacts from all ads
  Future<int> getTotalPlatformContacts() async {
    try {
      final adsSnapshot = await _firestore.collection('ads').get();
      int totalContacts = 0;

      for (var doc in adsSnapshot.docs) {
        final insightsDoc = await _firestore
            .collection('ads')
            .doc(doc.id)
            .collection('insights')
            .doc('stats')
            .get();

        if (insightsDoc.exists) {
          totalContacts += (insightsDoc.data()?['contacts'] ?? 0) as int;
        }
      }
      return totalContacts;
    } catch (e) {
      print('Error getting total contacts: $e');
      return 0;
    }
  }

  /// Get platform-wide total saves from all ads
  Future<int> getTotalPlatformSaves() async {
    try {
      final adsSnapshot = await _firestore.collection('ads').get();
      int totalSaves = 0;

      for (var doc in adsSnapshot.docs) {
        final insightsDoc = await _firestore
            .collection('ads')
            .doc(doc.id)
            .collection('insights')
            .doc('stats')
            .get();

        if (insightsDoc.exists) {
          totalSaves += (insightsDoc.data()?['saves'] ?? 0) as int;
        }
      }
      return totalSaves;
    } catch (e) {
      print('Error getting total saves: $e');
      return 0;
    }
  }

  /// Get weekly change percentage for a specific metric
  Future<double> getWeeklyChangePercentage(String metricType) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final twoWeeksAgo = now.subtract(const Duration(days: 14));

      int thisWeekCount = 0;
      int lastWeekCount = 0;

      final adsSnapshot = await _firestore.collection('ads').get();

      for (var adDoc in adsSnapshot.docs) {
        // This week's events
        final thisWeekEvents = await _firestore
            .collection('ads')
            .doc(adDoc.id)
            .collection('insights')
            .doc('events')
            .collection('items')
            .where('type', isEqualTo: metricType)
            .where('ts', isGreaterThan: Timestamp.fromDate(weekAgo))
            .get();
        thisWeekCount += thisWeekEvents.docs.length;

        // Last week's events
        final lastWeekEvents = await _firestore
            .collection('ads')
            .doc(adDoc.id)
            .collection('insights')
            .doc('events')
            .collection('items')
            .where('type', isEqualTo: metricType)
            .where('ts', isGreaterThan: Timestamp.fromDate(twoWeeksAgo))
            .where('ts', isLessThanOrEqualTo: Timestamp.fromDate(weekAgo))
            .get();
        lastWeekCount += lastWeekEvents.docs.length;
      }

      if (lastWeekCount == 0) {
        return thisWeekCount > 0 ? 100.0 : 0.0;
      }

      return ((thisWeekCount - lastWeekCount) / lastWeekCount * 100);
    } catch (e) {
      print('Error calculating weekly change: $e');
      return 0.0;
    }
  }

  /// Get total conversions (sold ads count)
  Future<int> getTotalConversions() async {
    try {
      final soldAds = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'sold')
          .get();
      return soldAds.docs.length;
    } catch (e) {
      print('Error getting conversions: $e');
      return 0;
    }
  }

  /// Calculate average time to sell in days
  Future<double> getAverageTimeToSell() async {
    try {
      final soldAds = await _firestore
          .collection('ads')
          .where('status', isEqualTo: 'sold')
          .get();

      if (soldAds.docs.isEmpty) return 0;

      double totalDays = 0;
      int count = 0;

      for (var doc in soldAds.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final soldAt = (data['soldAt'] as Timestamp?)?.toDate() ??
            (data['updatedAt'] as Timestamp?)?.toDate();

        if (createdAt != null && soldAt != null) {
          totalDays += soldAt.difference(createdAt).inDays;
          count++;
        }
      }

      return count > 0 ? totalDays / count : 0;
    } catch (e) {
      print('Error calculating avg time to sell: $e');
      return 0;
    }
  }

  /// Get all platform insights as a stream
  Stream<Map<String, dynamic>> getPlatformInsightsStream() {
    return _firestore.collection('ads').snapshots().asyncMap((snapshot) async {
      int totalViews = 0;
      int totalMessages = 0;
      int totalContacts = 0;
      int totalSaves = 0;
      int totalConversions = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Check for sold status
        if (data['status'] == 'sold') {
          totalConversions++;
        }

        // Get insights from subcollection
        final insightsDoc = await _firestore
            .collection('ads')
            .doc(doc.id)
            .collection('insights')
            .doc('stats')
            .get();

        if (insightsDoc.exists) {
          final insightData = insightsDoc.data()!;
          totalViews += (insightData['views'] ?? 0) as int;
          totalMessages += (insightData['messages'] ?? 0) as int;
          totalContacts += (insightData['contacts'] ?? 0) as int;
          totalSaves += (insightData['saves'] ?? 0) as int;
        }
      }

      return {
        'totalViews': totalViews,
        'totalMessages': totalMessages,
        'totalContacts': totalContacts,
        'totalSaves': totalSaves,
        'totalConversions': totalConversions,
        'totalAds': snapshot.docs.length,
      };
    });
  }
}
