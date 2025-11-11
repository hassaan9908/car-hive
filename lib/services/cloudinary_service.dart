import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dkcpilqiq';
  static const String _uploadPreset = 'unsigned_preset';
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

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
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
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

  /// Get the base Cloudinary URL for a public ID
  String getImageUrl(String publicId, {int? width, int? height}) {
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    
    final transform = transformations.isEmpty 
        ? '' 
        : 'upload/${transformations.join(',')}/';
    
    return 'https://res.cloudinary.com/$_cloudName/image/$transform$publicId';
  }

  /// Extract public ID from Cloudinary URL
  String extractPublicId(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 3) {
      return pathSegments.sublist(2).join('/');
    }
    return '';
  }
}

