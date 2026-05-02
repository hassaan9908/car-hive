import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Service to generate interpolated frames from image URLs
/// NOTE: This service is deprecated - we now use video-based 360 capture
/// This is kept for backward compatibility with existing listings
class UrlInterpolationService {
  /// Generate frames from image URLs
  /// NOTE: This is a placeholder - video-based capture is now the primary method
  /// For existing listings with image URLs, they will be used directly
  static Future<List<Uint8List?>> generateFromUrls({
    required List<String> imageUrls,
    Function(int current, int total, String message)? onProgress,
  }) async {
    // For video-based approach, we just return the URLs as-is
    // No interpolation needed since video already provides smooth frames
    onProgress?.call(0, 100, 'Loading frames...');
    
    // Download images as bytes for compatibility
    final List<Uint8List?> framesBytes = [];
    
    try {
      for (int i = 0; i < imageUrls.length; i++) {
        onProgress?.call(
          ((i + 1) / imageUrls.length * 100).round(),
          100,
          'Loading frame ${i + 1}/${imageUrls.length}...',
        );

        final url = imageUrls[i];
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          framesBytes.add(response.bodyBytes);
        } else {
          framesBytes.add(null);
        }
      }

      onProgress?.call(100, 100, 'Complete!');
      return framesBytes;
    } catch (e) {
      rethrow;
    }
  }

}



