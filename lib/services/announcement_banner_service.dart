import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/announcement_banner_model.dart';

class AnnouncementBannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _bannerCollection =>
      _firestore.collection('announcement_banners');

  Future<String> createBanner(AnnouncementBannerModel banner) async {
    try {
      final now = DateTime.now();
      final normalizedBanner = banner.copyWith(
        createdAt: banner.createdAt ?? now,
        updatedAt: now,
        createdBy: banner.createdBy ?? _auth.currentUser?.uid,
      );

      final docRef =
          await _bannerCollection.add(normalizedBanner.toFirestore());
      return docRef.id;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Please make sure the current user is an admin.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to create announcement banner: $e');
    }
  }

  Stream<List<AnnouncementBannerModel>> watchAllBanners() {
    return _bannerCollection.snapshots().map((snapshot) {
      final banners = snapshot.docs
          .map(
            (doc) => AnnouncementBannerModel.fromFirestore(doc.data(), doc.id),
          )
          .toList();

      banners.sort(_sortByNewest);
      return banners;
    });
  }

  Stream<List<AnnouncementBannerModel>> watchActiveBanners({int limit = 5}) {
    return watchAllBanners().map((banners) {
      return banners.where((banner) => banner.isActive).take(limit).toList();
    });
  }

  Future<void> updateBannerStatus(String bannerId, bool isActive) async {
    try {
      await _bannerCollection.doc(bannerId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Please make sure the current user is an admin.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to update banner status: $e');
    }
  }

  Future<void> deleteBanner(String bannerId) async {
    try {
      await _bannerCollection.doc(bannerId).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Please make sure the current user is an admin.',
        );
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete banner: $e');
    }
  }

  int _sortByNewest(
    AnnouncementBannerModel a,
    AnnouncementBannerModel b,
  ) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }
}
