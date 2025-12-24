import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class PhotoService {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Capture photo from camera
  Future<File?> capturePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error capturing photo: $e');
      return null;
    }
  }

  // Pick photo from gallery
  Future<File?> pickPhotoFromGallery() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error picking photo: $e');
      return null;
    }
  }

  // Pick multiple photos from gallery
  Future<List<File>> pickMultiplePhotos() async {
    try {
      final photos = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      return photos.map((photo) => File(photo.path)).toList();
    } catch (e) {
      print('Error picking multiple photos: $e');
      return [];
    }
  }

  // Upload photo to Firebase Storage
  Future<String> uploadPhoto(
    File photoFile, {
    required String inspectionId,
    required String itemId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fileName = path.basename(photoFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      final ref = _firebaseStorage
          .ref()
          .child('inspections')
          .child(userId)
          .child(inspectionId)
          .child(itemId)
          .child(uniqueFileName);

      final uploadTask = ref.putFile(photoFile);
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      rethrow;
    }
  }

  // Upload multiple photos
  Future<List<String>> uploadMultiplePhotos(
    List<File> photoFiles, {
    required String inspectionId,
    required String itemId,
  }) async {
    try {
      final List<String> uploadedUrls = [];

      for (final photoFile in photoFiles) {
        final url = await uploadPhoto(
          photoFile,
          inspectionId: inspectionId,
          itemId: itemId,
        );
        uploadedUrls.add(url);
      }

      return uploadedUrls;
    } catch (e) {
      print('Error uploading multiple photos: $e');
      rethrow;
    }
  }

  // Delete photo from Firebase Storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _firebaseStorage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting photo: $e');
      rethrow;
    }
  }

  // Delete multiple photos
  Future<void> deleteMultiplePhotos(List<String> photoUrls) async {
    try {
      for (final url in photoUrls) {
        await deletePhoto(url);
      }
    } catch (e) {
      print('Error deleting multiple photos: $e');
      rethrow;
    }
  }

  // Compress photo
  Future<File> compressPhoto(File photoFile) async {
    try {
      // For now, just return the original file
      // In a production app, you'd use flutter_image_compress
      return photoFile;
    } catch (e) {
      print('Error compressing photo: $e');
      return photoFile;
    }
  }
}
