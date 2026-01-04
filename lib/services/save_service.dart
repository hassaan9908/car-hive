import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'insight_service.dart';

class SaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InsightService _insightService = InsightService();

  /// Check if current user has saved an ad
  Stream<bool> isAdSaved(String adId) {
    final user = _auth.currentUser;
    if (user == null || adId.isEmpty) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedAds')
        .doc(adId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Toggle save status for an ad
  Future<bool> toggleSave(String adId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to save ads');
    }

    print('SaveService: Toggling save for adId: $adId');

    final savedRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedAds')
        .doc(adId);

    final doc = await savedRef.get();

    if (doc.exists) {
      // Unsave the ad
      await savedRef.delete();
      print('SaveService: Ad unsaved successfully');
      return false;
    } else {
      // Save the ad
      await savedRef.set({
        'adId': adId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      print('SaveService: Ad saved successfully, recording insight...');

      // Record the save event for insights
      await _insightService.recordSave(adId);
      print('SaveService: Insight recorded successfully');
      return true;
    }
  }

  /// Get all saved ads for current user
  Stream<List<String>> getSavedAdIds() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savedAds')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }
}
