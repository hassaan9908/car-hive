import 'dart:io';
import 'dart:typed_data';
import 'package:carhive/utils/360_file_handler.dart';
import 'package:carhive/processing/frame_interpolator.dart';

/// Service to handle frame interpolation workflow
class InterpolationService {
  /// Run complete interpolation workflow
  /// 
  /// Loads 16 raw images, generates 64 interpolated frames, saves them
  static Future<List<File>> generateInterpolatedFrames({
    required Function(int current, int total, String message) onProgress,
  }) async {
    // Load all raw images
    onProgress(0, 100, 'Loading captured images...');
    final rawImages = await Car360FileHandler.loadAllRawImages();
    
    // Filter out nulls and verify we have 16
    final validImages = rawImages.whereType<File>().toList();
    if (validImages.length != 16) {
      throw Exception('Expected 16 raw images, found ${validImages.length}');
    }

    // Get output directory
    final outputDir = await Car360FileHandler.getGeneratedFramesDirectory();

    // Run interpolation
    final interpolatedFrames = await FrameInterpolator.interpolateFrames(
      sourceImages: validImages,
      outputDirectory: outputDir,
      onProgress: (current, total, message) {
        // Map progress from 0-64 to 10-100 (assuming loading took 10%)
        final mappedProgress = 10 + ((current / total) * 90).round();
        onProgress(mappedProgress, 100, message);
      },
    );

    return interpolatedFrames;
  }

  /// Check if interpolated frames already exist
  static Future<bool> interpolatedFramesExist() async {
    final outputDir = await Car360FileHandler.getGeneratedFramesDirectory();
    return await FrameInterpolator.verifyFrames(outputDir);
  }

  /// Load all 64 interpolated frames
  static Future<List<File?>> loadInterpolatedFrames() async {
    final outputDir = await Car360FileHandler.getGeneratedFramesDirectory();
    return await FrameInterpolator.loadAllFrames(outputDir);
  }

  /// Load all 64 frames as bytes
  static Future<List<Uint8List?>> loadInterpolatedFramesAsBytes() async {
    final outputDir = await Car360FileHandler.getGeneratedFramesDirectory();
    return await FrameInterpolator.loadAllFramesAsBytes(outputDir);
  }
}

