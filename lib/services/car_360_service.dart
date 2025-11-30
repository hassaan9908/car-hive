import 'dart:typed_data';
import 'dart:io';
import 'package:carhive/services/cloudinary_service.dart';
import 'package:carhive/models/car_360_set.dart';

/// Represents a single angle in the 360° capture sequence
class CaptureAngle {
  final int index;
  final String name;
  final String description;
  final double rotationDegrees;
  final String fileName;

  const CaptureAngle({
    required this.index,
    required this.name,
    required this.description,
    required this.rotationDegrees,
    required this.fileName,
  });
}

/// Service to manage 360° car photo capture with 16 angles
class Car360Service {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// The 16 angles for 360° capture (22.5° apart)
  static List<CaptureAngle> get captureAngles => List.generate(
        16,
        (index) => CaptureAngle(
          index: index,
          name: Car360Set.getAngleName(index),
          description: _getAngleDescription(index),
          rotationDegrees: Car360Set.getAngleDegrees(index),
          fileName: Car360Set.getFileName(index),
        ),
      );

  /// Get description for angle
  static String _getAngleDescription(int index) {
    final descriptions = [
      'Stand directly in front of the car',
      'Move slightly to the front-right',
      'Position at front-right corner (45°)',
      'Move towards the right side',
      'Stand at the right side of the car',
      'Move towards the back-right',
      'Position at back-right corner',
      'Move slightly behind on the right',
      'Stand directly behind the car',
      'Move slightly behind on the left',
      'Position at back-left corner',
      'Move towards the left side',
      'Stand at the left side of the car',
      'Move towards the front-left',
      'Position at front-left corner',
      'Move slightly to the front-left',
    ];
    return descriptions[index % 16];
  }

  /// Current capture session
  Car360Set? _currentSet;

  /// Get or create current capture session
  Car360Set get currentSet {
    _currentSet ??= Car360Set();
    return _currentSet!;
  }

  /// Start a new capture session
  void startNewSession() {
    _currentSet = Car360Set();
  }

  /// Get captured image bytes at index
  Uint8List? getCapturedImageBytes(int index) {
    return _currentSet?.imageBytes[index];
  }

  /// Get captured image file at index
  File? getCapturedImageFile(int index) {
    return _currentSet?.images[index];
  }

  /// Check if an angle has been captured
  bool isAngleCaptured(int index) {
    return _currentSet?.isAngleCaptured(index) ?? false;
  }

  /// Get count of captured images
  int get capturedCount => _currentSet?.capturedCount ?? 0;

  /// Check if all 16 angles are captured
  bool get isComplete => _currentSet?.isComplete ?? false;

  /// Store captured image bytes (for web)
  void setCapturedImageBytes(int index, Uint8List bytes) {
    if (index >= 0 && index < 16 && _currentSet != null) {
      final newImageBytes = List<Uint8List?>.from(_currentSet!.imageBytes);
      newImageBytes[index] = bytes;
      _currentSet = _currentSet!.copyWith(imageBytes: newImageBytes);
    }
  }

  /// Store captured image file (for mobile)
  void setCapturedImageFile(int index, File file) {
    if (index >= 0 && index < 16 && _currentSet != null) {
      final newImages = List<File?>.from(_currentSet!.images);
      newImages[index] = file;
      _currentSet = _currentSet!.copyWith(images: newImages);
    }
  }

  /// Store captured image (auto-detect type)
  void setCapturedImage(int index, dynamic image) {
    if (image is Uint8List) {
      setCapturedImageBytes(index, image);
    } else if (image is File) {
      setCapturedImageFile(index, image);
      // Also read bytes for preview
      setCapturedImageBytes(index, image.readAsBytesSync());
    }
  }

  /// Remove captured image at index
  void removeCapturedImage(int index) {
    if (index >= 0 && index < 16 && _currentSet != null) {
      final newImages = List<File?>.from(_currentSet!.images);
      final newImageBytes = List<Uint8List?>.from(_currentSet!.imageBytes);
      newImages[index] = null;
      newImageBytes[index] = null;
      _currentSet = _currentSet!.copyWith(
        images: newImages,
        imageBytes: newImageBytes,
      );
    }
  }

  /// Clear all captured images
  void clearAll() {
    _currentSet = null;
  }

  /// Set the current capture set (e.g., from capture screen)
  void setCurrentSet(Car360Set set) {
    _currentSet = set;
  }

  /// Get all captured images as bytes list (for preview)
  List<Uint8List> getAllCapturedBytes() {
    if (_currentSet == null) return [];

    final List<Uint8List> result = [];
    for (int i = 0; i < 16; i++) {
      if (_currentSet!.imageBytes[i] != null) {
        result.add(_currentSet!.imageBytes[i]!);
      } else if (_currentSet!.images[i] != null) {
        result.add(_currentSet!.images[i]!.readAsBytesSync());
      }
    }
    return result;
  }

  /// Get all captured bytes in order (with nulls for missing)
  List<Uint8List?> getAllImageBytesOrdered() {
    if (_currentSet == null) return List.filled(16, null);

    final List<Uint8List?> result = [];
    for (int i = 0; i < 16; i++) {
      if (_currentSet!.imageBytes[i] != null) {
        result.add(_currentSet!.imageBytes[i]!);
      } else if (_currentSet!.images[i] != null) {
        result.add(_currentSet!.images[i]!.readAsBytesSync());
      } else {
        result.add(null);
      }
    }
    return result;
  }

  /// Upload all captured images to Cloudinary
  /// Returns list of URLs in order (16 URLs for each angle)
  Future<List<String>> uploadAllImages({
    Function(int current, int total)? onProgress,
  }) async {
    if (_currentSet == null) return [];

    final List<String> urls = [];

    for (int i = 0; i < 16; i++) {
      onProgress?.call(i + 1, 16);

      try {
        String? url;

        if (_currentSet!.imageBytes[i] != null) {
          url = await _cloudinaryService.uploadImageBytes(
            imageBytes: _currentSet!.imageBytes[i]!,
          );
        } else if (_currentSet!.images[i] != null) {
          url = await _cloudinaryService.uploadImage(
            imageFile: _currentSet!.images[i]!,
          );
        }

        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        print('Failed to upload 360 image ${i + 1}: $e');
        rethrow;
      }
    }

    return urls;
  }

  /// Upload a Car360Set and return URLs
  Future<List<String>> uploadCar360Set(
    Car360Set set, {
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < 16; i++) {
      onProgress?.call(i + 1, 16);

      try {
        String? url;

        if (set.imageBytes[i] != null) {
          url = await _cloudinaryService.uploadImageBytes(
            imageBytes: set.imageBytes[i]!,
          );
        } else if (set.images[i] != null) {
          url = await _cloudinaryService.uploadImage(
            imageFile: set.images[i]!,
          );
        }

        if (url != null) {
          urls.add(url);
        }
      } catch (e) {
        print('Failed to upload 360 image ${i + 1}: $e');
        rethrow;
      }
    }

    return urls;
  }

  /// Get the next angle to capture
  int? getNextAngleToCapture() {
    return _currentSet?.getNextAngleToCapture();
  }

  /// Get list of missing angles
  List<CaptureAngle> getMissingAngles() {
    if (_currentSet == null) return captureAngles;

    final List<CaptureAngle> missing = [];
    for (int i = 0; i < 16; i++) {
      if (!_currentSet!.isAngleCaptured(i)) {
        missing.add(captureAngles[i]);
      }
    }
    return missing;
  }

  /// Get capture angle info
  CaptureAngle getAngle(int index) {
    return captureAngles[index % 16];
  }
}
