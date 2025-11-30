import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dkcpilqiq';
  static const String _uploadPreset = 'unsigned_preset';
  static const String _imageUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  static const String _videoUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/video/upload';

  /// Upload a single image file to Cloudinary
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage({
    required File imageFile,
    Function(double)? onProgress,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await uploadImageBytes(
        imageBytes: bytes,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to read image file: $e');
    }
  }

  /// Upload image bytes to Cloudinary (for web/mobile compatibility)
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImageBytes({
    required Uint8List imageBytes,
    Function(double)? onProgress,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_imageUrl));

      // Add the upload preset
      request.fields['upload_preset'] = _uploadPreset;

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      // Send request
      final streamedRequest = request.send();

      final response = await streamedRequest;

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = utf8.decode(responseData);
        final jsonResponse = json.decode(responseString);

        // Get secure URL from response
        final secureUrl = jsonResponse['secure_url'] as String?;
        if (secureUrl != null) {
          return secureUrl;
        } else {
          throw Exception('No secure_url in Cloudinary response');
        }
      } else {
        final errorData = await response.stream.toBytes();
        final errorString = utf8.decode(errorData);
        throw Exception('Upload failed: ${response.statusCode} - $errorString');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }

  /// Upload a single video file to Cloudinary
  /// Returns the secure URL of the uploaded video
  Future<String> uploadVideo({
    required File videoFile,
    Function(double)? onProgress,
  }) async {
    try {
      final bytes = await videoFile.readAsBytes();
      return await uploadVideoBytes(
        videoBytes: bytes,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to read video file: $e');
    }
  }

  /// Upload video bytes to Cloudinary (for web/mobile compatibility)
  /// Returns the secure URL of the uploaded video
  Future<String> uploadVideoBytes({
    required Uint8List videoBytes,
    Function(double)? onProgress,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_videoUrl));

      // Add the upload preset
      request.fields['upload_preset'] = _uploadPreset;

      // Add the video file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          videoBytes,
          filename: 'video.mp4',
        ),
      );

      // Send request
      final streamedRequest = request.send();

      final response = await streamedRequest;

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = utf8.decode(responseData);
        final jsonResponse = json.decode(responseString);

        // Get secure URL from response
        final secureUrl = jsonResponse['secure_url'] as String?;
        if (secureUrl != null) {
          return secureUrl;
        } else {
          throw Exception('No secure_url in Cloudinary response');
        }
      } else {
        final errorData = await response.stream.toBytes();
        final errorString = utf8.decode(errorData);
        throw Exception('Upload failed: ${response.statusCode} - $errorString');
      }
    } catch (e) {
      throw Exception('Failed to upload video to Cloudinary: $e');
    }
  }

  /// Upload multiple images
  /// Returns list of secure URLs
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);

      try {
        final url = await uploadImage(imageFile: imageFiles[i]);
        urls.add(url);
      } catch (e) {
        // If one image fails, continue with others
        print('Failed to upload image ${i + 1}: $e');
      }
    }

    return urls;
  }

  /// Upload multiple image bytes
  /// Returns list of secure URLs
  Future<List<String>> uploadMultipleImagesBytes({
    required List<Uint8List> imageBytesList,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < imageBytesList.length; i++) {
      onProgress?.call(i + 1, imageBytesList.length);

      try {
        final url = await uploadImageBytes(imageBytes: imageBytesList[i]);
        urls.add(url);
      } catch (e) {
        // If one image fails, continue with others
        print('Failed to upload image ${i + 1}: $e');
      }
    }

    return urls;
  }

  /// Upload multiple videos
  /// Returns list of secure URLs
  Future<List<String>> uploadMultipleVideos({
    required List<File> videoFiles,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < videoFiles.length; i++) {
      onProgress?.call(i + 1, videoFiles.length);

      try {
        final url = await uploadVideo(videoFile: videoFiles[i]);
        urls.add(url);
      } catch (e) {
        // If one video fails, continue with others
        print('Failed to upload video ${i + 1}: $e');
      }
    }

    return urls;
  }

  /// Upload multiple video bytes
  /// Returns list of secure URLs
  Future<List<String>> uploadMultipleVideosBytes({
    required List<Uint8List> videoBytesList,
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> urls = [];

    for (int i = 0; i < videoBytesList.length; i++) {
      onProgress?.call(i + 1, videoBytesList.length);

      try {
        final url = await uploadVideoBytes(videoBytes: videoBytesList[i]);
        urls.add(url);
      } catch (e) {
        // If one video fails, continue with others
        print('Failed to upload video ${i + 1}: $e');
      }
    }

    return urls;
  }

  /// Get the base Cloudinary URL for a public ID
  String getImageUrl(String publicId, {int? width, int? height}) {
    final transformations = <String>[];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');

    final transform =
        transformations.isEmpty ? '' : 'upload/${transformations.join(',')}/';

    return 'https://res.cloudinary.com/$_cloudName/image/$transform$publicId';
  }

  /// Get the base Cloudinary URL for a video public ID
  String getVideoUrl(String publicId) {
    return 'https://res.cloudinary.com/$_cloudName/video/upload/$publicId';
  }

  /// Extract public ID from Cloudinary URL
  String extractPublicId(String url) {
    final uri = Uri.parse(url);
    final segments = List<String>.from(uri.pathSegments);
    final uploadIndex = segments.indexOf('upload');
    if (uploadIndex != -1 && uploadIndex + 1 < segments.length) {
      return segments.sublist(uploadIndex + 1).join('/');
    }
    return '';
  }

  /// Build a Cloudinary thumbnail URL for a given video URL using transformations.
  /// Defaults to capturing a frame at 1s and returning a JPG.
  String buildVideoThumbnailUrl(
    String videoUrl, {
    int second = 1,
    int? width,
    int? height,
    String format = 'jpg',
  }) {
    try {
      final uri = Uri.parse(videoUrl);
      final segments = List<String>.from(uri.pathSegments);
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1) return videoUrl;

      final beforeUpload = segments.sublist(0, uploadIndex + 1).join('/');
      final afterUpload = segments.sublist(uploadIndex + 1);

      if (afterUpload.isEmpty) return videoUrl;
      final last = afterUpload.removeLast();
      final dot = last.lastIndexOf('.');
      final baseName = dot > 0 ? last.substring(0, dot) : last;

      final transforms = <String>['so_$second', 'q_auto', 'f_$format'];
      if (width != null) transforms.add('w_$width');
      if (height != null) transforms.add('h_$height');

      final path = [
        beforeUpload,
        transforms.join(','),
        ...afterUpload,
        '$baseName.$format',
      ].join('/');

      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        path: '/$path',
      ).toString();
    } catch (_) {
      return videoUrl;
    }
  }
}
