import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';
import 'trust_rank_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<ReviewModel>> streamReviews(String adId) {
    print('🔍 DEBUG: Streaming reviews for adId: $adId');

    return _firestore
        .collection('reviews')
        .where('adId', isEqualTo: adId)
        .snapshots()
        .map((snapshot) {
      print('📊 DEBUG: Received ${snapshot.docs.length} reviews for ad $adId');
      if (snapshot.docs.isEmpty) {
        print('⚠️ No reviews found for ad $adId');
        return <ReviewModel>[];
      }

      try {
        final reviews = snapshot.docs.map((doc) {
          print('📝 Review data: ${doc.data()}');
          return ReviewModel.fromFirestore(doc.data(), doc.id);
        }).toList();

        // Sort by createdAt descending (newest first) on client side
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('✅ Successfully parsed ${reviews.length} reviews');
        return reviews;
      } catch (e) {
        print('❌ ERROR parsing reviews: $e');
        return <ReviewModel>[];
      }
    });
  }

  Future<void> addReview({
    required String adId,
    required int rating,
    required String comment,
  }) async {
    print('🔍 DEBUG: Starting addReview with adId: $adId, rating: $rating');

    final user = _auth.currentUser;
    if (user == null) {
      print('❌ ERROR: User not authenticated');
      throw Exception('User not authenticated');
    }

    print('✅ User authenticated: ${user.uid}');

    // Check if ad exists
    final adDoc = await _firestore.collection('ads').doc(adId).get();
    if (!adDoc.exists) {
      print('❌ ERROR: Ad with ID $adId does not exist');
      throw Exception('Ad not found');
    }
    print('✅ Ad exists: ${adDoc.data()?['title']}');

    final reviewRef = _firestore.collection('reviews').doc();

    // Get ad data for additional review information
    final adData = adDoc.data()!;
    final adTitle = (adData['title'] ?? '').toString().trim();
    final finalAdTitle = adTitle.isNotEmpty ? adTitle : 'Untitled Car';
    final adOwnerId = adData['userId'] as String?;

    // Determine a non-empty display name for the reviewer
    final String resolvedUserName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : (user.email != null && user.email!.isNotEmpty)
                ? user.email!.split('@').first
                : 'User';

    final data = {
      'adId': adId,
      'adTitle': finalAdTitle,
      'adOwnerId': adOwnerId,
      'userId': user.uid,
      'userName': resolvedUserName,
      'comment': comment.trim(),
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    };

    print('📝 DEBUG: Review data: $data');

    try {
      await reviewRef.set(data);
      print('✅ Review saved successfully to: ${reviewRef.path}');
    } catch (e) {
      print('❌ ERROR saving review: $e');
      rethrow;
    }

    // After a review is added, recompute TrustRank for the ad owner
    try {
      final adData = adDoc.data();
      final ownerId = adData != null ? adData['userId'] as String? : null;
      if (ownerId != null && ownerId.isNotEmpty) {
        print('🔄 Recomputing trust rank for owner: $ownerId');
        await TrustRankService().recomputeAndSave(ownerId);
        print('✅ Trust rank recomputed successfully');
      }
    } catch (e) {
      print('⚠️ WARNING: Failed to recompute trust rank: $e');
    }
  }
}
