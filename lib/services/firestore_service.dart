import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  /// Uploads ad to Firestore
  Future<void> uploadAd({
    required String location,
    required String carModel,
    required String brand,
    required String registeredCity,
    required String bodyColor,
    required String kmsDriven,
    required String price,
    required String description,
    required String phoneNumber,
    required String fuel,
    required String year,
    required List<File> images,
    required List<Uint8List> webImages,
  }) async {
    try {
      // ✅ Upload images to Firebase Storage
      List<String> downloadUrls = [];

      // Mobile images
      for (var image in images) {
        final ref = _storage
            .ref()
            .child("ads/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await ref.putFile(image);
        final url = await ref.getDownloadURL();
        downloadUrls.add(url);
      }

      // Web images
      for (var image in webImages) {
        final ref = _storage
            .ref()
            .child("ads/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await ref.putData(image);
        final url = await ref.getDownloadURL();
        downloadUrls.add(url);
      }

      // ✅ Create Firestore document
      await _firestore.collection("ads").add({
        "location": location,
        "carModel": carModel,
        "brand": brand,
        "registeredCity": registeredCity,
        "bodyColor": bodyColor,
        "kmsDriven": kmsDriven,
        "price": price,
        "description": description,
        "phoneNumber": phoneNumber,
        "fuel": fuel,
        "year": year,
        "photos": downloadUrls,
        "status": "active",
        "userId": _auth.currentUser?.uid ?? "anonymous",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to upload ad: $e");
    }
  }
}
