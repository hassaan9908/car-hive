import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for handling 360° image file operations
class Car360FileHandler {
  /// Get the storage directory for 360 images
  static Future<Directory> getStorageDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File storage not supported on web');
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory('${appDir.path}/storage/360');
    
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    
    return storageDir;
  }

  /// Get the directory for raw captured images
  static Future<Directory> getRawImagesDirectory() async {
    final storageDir = await getStorageDirectory();
    final rawDir = Directory('${storageDir.path}/raw');
    
    if (!await rawDir.exists()) {
      await rawDir.create(recursive: true);
    }
    
    return rawDir;
  }

  /// Get the directory for generated/interpolated frames
  static Future<Directory> getGeneratedFramesDirectory() async {
    final storageDir = await getStorageDirectory();
    final genDir = Directory('${storageDir.path}/gen');
    
    if (!await genDir.exists()) {
      await genDir.create(recursive: true);
    }
    
    return genDir;
  }

  /// Get file path for a specific angle (1-16)
  /// Format: /storage/360/raw/img_01.jpg, img_02.jpg, etc.
  static Future<String> getRawImagePath(int angleIndex) async {
    if (angleIndex < 1 || angleIndex > 16) {
      throw ArgumentError('Angle index must be between 1 and 16');
    }
    
    final rawDir = await getRawImagesDirectory();
    final fileName = 'img_${angleIndex.toString().padLeft(2, '0')}.jpg';
    return '${rawDir.path}/$fileName';
  }

  /// Save image bytes to raw images directory
  static Future<File> saveRawImage(int angleIndex, Uint8List imageBytes) async {
    final filePath = await getRawImagePath(angleIndex);
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return file;
  }

  /// Load raw image file
  static Future<File?> loadRawImage(int angleIndex) async {
    try {
      final filePath = await getRawImagePath(angleIndex);
      final file = File(filePath);
      
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      print('Error loading raw image $angleIndex: $e');
    }
    
    return null;
  }

  /// Load all 16 raw images in order
  static Future<List<File?>> loadAllRawImages() async {
    final List<File?> images = [];
    
    for (int i = 1; i <= 16; i++) {
      final file = await loadRawImage(i);
      images.add(file);
    }
    
    return images;
  }

  /// Load all raw images as bytes
  static Future<List<Uint8List?>> loadAllRawImagesAsBytes() async {
    final List<Uint8List?> imageBytes = [];
    
    for (int i = 1; i <= 16; i++) {
      try {
        final file = await loadRawImage(i);
        if (file != null) {
          final bytes = await file.readAsBytes();
          imageBytes.add(bytes);
        } else {
          imageBytes.add(null);
        }
      } catch (e) {
        print('Error loading raw image bytes $i: $e');
        imageBytes.add(null);
      }
    }
    
    return imageBytes;
  }

  /// Verify all 16 raw images exist
  static Future<bool> verifyAllRawImagesExist() async {
    for (int i = 1; i <= 16; i++) {
      final file = await loadRawImage(i);
      if (file == null || !await file.exists()) {
        return false;
      }
    }
    return true;
  }

  /// Get count of existing raw images
  static Future<int> getExistingRawImageCount() async {
    int count = 0;
    
    for (int i = 1; i <= 16; i++) {
      final file = await loadRawImage(i);
      if (file != null && await file.exists()) {
        count++;
      }
    }
    
    return count;
  }

  /// Delete raw image at angle index
  static Future<bool> deleteRawImage(int angleIndex) async {
    try {
      final file = await loadRawImage(angleIndex);
      if (file != null && await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting raw image $angleIndex: $e');
    }
    
    return false;
  }

  /// Delete all raw 360 images
  static Future<void> deleteAllRawImages() async {
    try {
      final rawDir = await getRawImagesDirectory();
      if (await rawDir.exists()) {
        await rawDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting all raw images: $e');
    }
  }

  /// Delete all generated frames
  static Future<void> deleteAllGeneratedFrames() async {
    try {
      final genDir = await getGeneratedFramesDirectory();
      if (await genDir.exists()) {
        await genDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting generated frames: $e');
    }
  }

  /// Clear all 360 data (raw + generated)
  static Future<void> clearAll() async {
    await deleteAllRawImages();
    await deleteAllGeneratedFrames();
  }

  /// Get file size of a raw image
  static Future<int?> getRawImageSize(int angleIndex) async {
    try {
      final file = await loadRawImage(angleIndex);
      if (file != null && await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting raw image size $angleIndex: $e');
    }
    
    return null;
  }

  // Legacy support - redirect to raw images
  @Deprecated('Use getRawImagePath instead')
  static Future<String> getFilePath(int angleIndex) => getRawImagePath(angleIndex);
  
  @Deprecated('Use saveRawImage instead')
  static Future<File> saveImage(int angleIndex, Uint8List imageBytes) =>
      saveRawImage(angleIndex, imageBytes);
  
  @Deprecated('Use loadRawImage instead')
  static Future<File?> loadImage(int angleIndex) => loadRawImage(angleIndex);
  
  @Deprecated('Use loadAllRawImages instead')
  static Future<List<File?>> loadAllImages() => loadAllRawImages();
  
  @Deprecated('Use loadAllRawImagesAsBytes instead')
  static Future<List<Uint8List?>> loadAllImagesAsBytes() => loadAllRawImagesAsBytes();
  
  @Deprecated('Use verifyAllRawImagesExist instead')
  static Future<bool> verifyAllImagesExist() => verifyAllRawImagesExist();
  
  @Deprecated('Use getExistingRawImageCount instead')
  static Future<int> getExistingImageCount() => getExistingRawImageCount();
  
  @Deprecated('Use deleteRawImage instead')
  static Future<bool> deleteImage(int angleIndex) => deleteRawImage(angleIndex);
}
