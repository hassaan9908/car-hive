import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:carhive/processing/image_blend.dart';

/// Callback for interpolation progress updates
typedef InterpolationProgressCallback = void Function(int current, int total, String message);

/// Generates interpolated frames between 16 captured images
class FrameInterpolator {
  /// Number of synthetic frames to generate between each real frame
  static const int syntheticFramesPerPair = 3;
  
  /// Total frames after interpolation (16 real + 48 synthetic)
  static const int totalFrames = 64;

  /// Interpolate frames from 16 captured images
  /// 
  /// [sourceImages] - List of 16 image file paths (img_01.jpg to img_16.jpg)
  /// [outputDirectory] - Directory to save generated frames
  /// [onProgress] - Optional progress callback
  static Future<List<File>> interpolateFrames({
    required List<File> sourceImages,
    required Directory outputDirectory,
    InterpolationProgressCallback? onProgress,
  }) async {
    if (sourceImages.length != 16) {
      throw ArgumentError('Expected exactly 16 source images, got ${sourceImages.length}');
    }

    // Create output directory if it doesn't exist
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    final List<File> generatedFrames = [];
    int frameIndex = 1;

    onProgress?.call(0, 64, 'Initializing interpolation...');

    // Process each pair of consecutive images
    for (int i = 0; i < 16; i++) {
      final currentIndex = i;
      final nextIndex = (i + 1) % 16; // Wrap around for last to first

      final imageA = sourceImages[currentIndex];
      final imageB = sourceImages[nextIndex];

      onProgress?.call(
        frameIndex - 1,
        64,
        'Processing frames ${currentIndex + 1}-${nextIndex + 1}...',
      );

      // Load images
      final bytesA = await imageA.readAsBytes();
      final bytesB = await imageB.readAsBytes();

      final decodedA = img.decodeImage(bytesA);
      final decodedB = img.decodeImage(bytesB);

      if (decodedA == null || decodedB == null) {
        throw Exception('Failed to decode images at index $currentIndex');
      }

      // Normalize images before blending
      ImageBlend.equalizeBrightness(decodedA, decodedB);
      ImageBlend.normalizeExposure(decodedA, decodedB);

      // Save original frame A
      final frameA = await _saveFrame(
        decodedA,
        outputDirectory,
        frameIndex++,
      );
      generatedFrames.add(frameA);

      // Generate 3 synthetic frames between A and B (following reference approach)
      for (int j = 1; j <= syntheticFramesPerPair; j++) {
        // Linear blend ratio: 0.25, 0.5, 0.75
        double t = j / (syntheticFramesPerPair + 1);
        
        // Apply smooth curve for better transitions
        final alpha = ImageBlend.blendingCurve(t);

        onProgress?.call(
          frameIndex - 1,
          64,
          'Blending frame $frameIndex/64 (${(t * 100).toStringAsFixed(0)}%)...',
        );

        // Create cross-dissolve blend (simple linear blend like reference)
        var blended = ImageBlend.crossDissolve(decodedA, decodedB, alpha);

        // Apply light warp to reduce ghosting (progressive intensity like reference)
        final warpIntensity = 0.04 * j; // Progressive: 0.04, 0.08, 0.12
        blended = await _warpImage(blended, intensity: warpIntensity);

        // Normalize contrast for consistency
        blended = ImageBlend.normalizeContrast(blended);

        // Save generated frame
        final frame = await _saveFrame(
          blended,
          outputDirectory,
          frameIndex++,
        );
        generatedFrames.add(frame);
      }
    }

    onProgress?.call(64, 64, 'Interpolation complete!');

    return generatedFrames;
  }

  /// Save a frame to disk with proper naming
  static Future<File> _saveFrame(
    img.Image image,
    Directory outputDirectory,
    int frameNumber,
  ) async {
    // Encode as JPEG with high quality
    final encoded = img.encodeJpg(
      image,
      quality: 95,
    );

    // Generate filename: frame_001.jpg to frame_064.jpg
    final fileName = 'frame_${frameNumber.toString().padLeft(3, '0')}.jpg';
    final file = File('${outputDirectory.path}/$fileName');

    await file.writeAsBytes(encoded);

    return file;
  }

  /// Verify all 64 frames exist
  static Future<bool> verifyFrames(Directory outputDirectory) async {
    for (int i = 1; i <= totalFrames; i++) {
      final fileName = 'frame_${i.toString().padLeft(3, '0')}.jpg';
      final file = File('${outputDirectory.path}/$fileName');

      if (!await file.exists()) {
        return false;
      }
    }

    return true;
  }

  /// Load all 64 frames in order
  static Future<List<File?>> loadAllFrames(Directory outputDirectory) async {
    final List<File?> frames = [];

    for (int i = 1; i <= totalFrames; i++) {
      final fileName = 'frame_${i.toString().padLeft(3, '0')}.jpg';
      final file = File('${outputDirectory.path}/$fileName');

      if (await file.exists()) {
        frames.add(file);
      } else {
        frames.add(null);
      }
    }

    return frames;
  }

  /// Load all frames as bytes
  static Future<List<Uint8List?>> loadAllFramesAsBytes(
    Directory outputDirectory,
  ) async {
    final List<Uint8List?> frames = [];

    for (int i = 1; i <= totalFrames; i++) {
      final fileName = 'frame_${i.toString().padLeft(3, '0')}.jpg';
      final file = File('${outputDirectory.path}/$fileName');

      if (await file.exists()) {
        frames.add(await file.readAsBytes());
      } else {
        frames.add(null);
      }
    }

    return frames;
  }

  /// Applies a subtle warp to reduce ghosting (following reference approach)
  /// Uses improved blur-based warping for compatibility
  static Future<img.Image> _warpImage(img.Image input, {double intensity = 0.05}) async {
    if (intensity <= 0) return input;

    // Use horizontal blur to simulate motion blur (like reference's warp)
    final output = img.Image(width: input.width, height: input.height);
    final blurRadius = (intensity * 10).round().clamp(0, 2);

    if (blurRadius == 0) return input;

    // Horizontal blur simulates the warp effect
    for (int y = 0; y < input.height; y++) {
      for (int x = 0; x < input.width; x++) {
        int rSum = 0, gSum = 0, bSum = 0;
        int count = 0;

        for (int dx = -blurRadius; dx <= blurRadius; dx++) {
          final sx = (x + dx).clamp(0, input.width - 1);
          final pixel = input.getPixel(sx, y);
          
          rSum += pixel.r.round();
          gSum += pixel.g.round();
          bSum += pixel.b.round();
          count++;
        }

        final r = ((rSum / count).round()).clamp(0, 255).toInt();
        final g = ((gSum / count).round()).clamp(0, 255).toInt();
        final b = ((bSum / count).round()).clamp(0, 255).toInt();

        output.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return output;
  }
}

