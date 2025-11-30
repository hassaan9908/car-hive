import 'dart:io';
import 'dart:typed_data';

/// Model representing a complete set of 16 360° car images
class Car360Set {
  /// List of 16 images (File for mobile, null if using bytes)
  final List<File?> images;

  /// List of 16 image bytes (for web or memory storage)
  final List<Uint8List?> imageBytes;

  /// Session ID (timestamp-based folder name)
  final String sessionId;

  /// List of image URLs after upload to Cloudinary
  final List<String>? uploadedUrls;

  /// Timestamp when capture started
  final DateTime createdAt;

  /// The 16 angles in degrees
  static const List<double> angles = [
    0,
    22.5,
    45,
    67.5,
    90,
    112.5,
    135,
    157.5,
    180,
    202.5,
    225,
    247.5,
    270,
    292.5,
    315,
    337.5,
  ];

  /// Angle names for display
  static const List<String> angleNames = [
    'Front',
    'Front-Right 1',
    'Front-Right 2',
    'Right-Front',
    'Right',
    'Right-Back',
    'Back-Right 2',
    'Back-Right 1',
    'Back',
    'Back-Left 1',
    'Back-Left 2',
    'Left-Back',
    'Left',
    'Left-Front',
    'Front-Left 2',
    'Front-Left 1',
  ];

  /// File name format for each angle
  static List<String> get fileNames => [
        'angle_000.jpg',
        'angle_022.jpg',
        'angle_045.jpg',
        'angle_067.jpg',
        'angle_090.jpg',
        'angle_112.jpg',
        'angle_135.jpg',
        'angle_157.jpg',
        'angle_180.jpg',
        'angle_202.jpg',
        'angle_225.jpg',
        'angle_247.jpg',
        'angle_270.jpg',
        'angle_292.jpg',
        'angle_315.jpg',
        'angle_337.jpg',
      ];

  Car360Set({
    List<File?>? images,
    List<Uint8List?>? imageBytes,
    String? sessionId,
    this.uploadedUrls,
    DateTime? createdAt,
  })  : images = images ?? List.filled(16, null),
        imageBytes = imageBytes ?? List.filled(16, null),
        sessionId = sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
        createdAt = createdAt ?? DateTime.now();

  /// Check if a specific angle is captured
  bool isAngleCaptured(int index) {
    if (index < 0 || index >= 16) return false;
    return images[index] != null || imageBytes[index] != null;
  }

  /// Get count of captured images
  int get capturedCount {
    int count = 0;
    for (int i = 0; i < 16; i++) {
      if (images[i] != null || imageBytes[i] != null) {
        count++;
      }
    }
    return count;
  }

  /// Check if all 16 angles are captured
  bool get isComplete => capturedCount == 16;

  /// Get the next angle index to capture
  int? getNextAngleToCapture() {
    for (int i = 0; i < 16; i++) {
      if (!isAngleCaptured(i)) {
        return i;
      }
    }
    return null;
  }

  /// Get file name for angle index
  static String getFileName(int index) {
    if (index < 0 || index >= 16) return 'angle_unknown.jpg';
    return fileNames[index];
  }

  /// Get angle in degrees for index
  static double getAngleDegrees(int index) {
    if (index < 0 || index >= 16) return 0;
    return angles[index];
  }

  /// Get angle name for display
  static String getAngleName(int index) {
    if (index < 0 || index >= 16) return 'Unknown';
    return angleNames[index];
  }

  /// Create a copy with updated values
  Car360Set copyWith({
    List<File?>? images,
    List<Uint8List?>? imageBytes,
    String? sessionId,
    List<String>? uploadedUrls,
    DateTime? createdAt,
  }) {
    return Car360Set(
      images: images ?? List.from(this.images),
      imageBytes: imageBytes ?? List.from(this.imageBytes),
      sessionId: sessionId ?? this.sessionId,
      uploadedUrls: uploadedUrls ?? this.uploadedUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'uploadedUrls': uploadedUrls,
      'createdAt': createdAt.toIso8601String(),
      'capturedCount': capturedCount,
      'isComplete': isComplete,
    };
  }

  /// Create from JSON
  factory Car360Set.fromJson(Map<String, dynamic> json) {
    return Car360Set(
      sessionId: json['sessionId'] as String?,
      uploadedUrls: (json['uploadedUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

