import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:carhive/processing/frame_interpolator.dart';

/// Service to generate interpolated frames from image URLs
/// This allows viewing existing listings with smooth 64-frame rotation
class UrlInterpolationService {
  /// Generate 64 interpolated frames from 16 image URLs
  /// Downloads images, generates frames, returns as bytes in memory
  static Future<List<Uint8List?>> generateFromUrls({
    required List<String> imageUrls,
    Function(int current, int total, String message)? onProgress,
  }) async {
    if (imageUrls.length != 16) {
      throw ArgumentError('Expected exactly 16 image URLs, got ${imageUrls.length}');
    }

    onProgress?.call(0, 100, 'Downloading images...');

    // Download all 16 images to temp files
    final tempDir = await _getTempDirectory();
    final List<File> tempFiles = [];

    try {
      // Download images
      for (int i = 0; i < imageUrls.length; i++) {
        onProgress?.call(
          (i / imageUrls.length * 30).round(),
          100,
          'Downloading image ${i + 1}/16...',
        );

        final url = imageUrls[i];
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final tempFile = File('${tempDir.path}/temp_img_${i.toString().padLeft(2, '0')}.jpg');
          await tempFile.writeAsBytes(response.bodyBytes);
          tempFiles.add(tempFile);
        } else {
          throw Exception('Failed to download image ${i + 1}: HTTP ${response.statusCode}');
        }
      }

      // Generate interpolated frames
      onProgress?.call(30, 100, 'Generating interpolated frames...');

      final outputDir = await _getTempOutputDirectory();
      await FrameInterpolator.interpolateFrames(
        sourceImages: tempFiles,
        outputDirectory: outputDir,
        onProgress: (current, total, message) {
          // Map 0-64 progress to 30-100
          final progress = 30 + ((current / total) * 70).round();
          onProgress?.call(progress, 100, message);
        },
      );

      // Load all 64 frames as bytes
      final framesBytes = await FrameInterpolator.loadAllFramesAsBytes(outputDir);

      // Cleanup temp files
      await _cleanupTempFiles(tempDir, tempFiles, outputDir);

      onProgress?.call(100, 100, 'Complete!');

      return framesBytes;
    } catch (e) {
      // Cleanup on error
      await _cleanupTempFiles(tempDir, tempFiles, Directory(''));
      rethrow;
    }
  }

  /// Get temporary directory for downloaded images
  static Future<Directory> _getTempDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/360_temp_download');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  /// Get temporary output directory for generated frames
  static Future<Directory> _getTempOutputDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${appDir.path}/360_temp_gen');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  /// Cleanup temporary files
  static Future<void> _cleanupTempFiles(
    Directory tempDir,
    List<File> tempFiles,
    Directory outputDir,
  ) async {
    try {
      // Delete downloaded temp files
      for (final file in tempFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete generated frames
      if (await outputDir.exists()) {
        await outputDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error cleaning up temp files: $e');
    }
  }
}

