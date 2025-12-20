import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

/// Service for communicating with the 360 video processing backend
class Backend360Service {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:8000';
  
  /// Upload video and process it to generate 360 frames
  /// Returns list of frame URLs
  /// 
  /// For web: pass videoBytes directly
  /// For mobile: pass videoFile
  Future<Process360Result> processVideo({
    File? videoFile,
    Uint8List? videoBytes,
    String? filename,
    Function(int current, int total, String message)? onProgress,
  }) async {
    try {
      onProgress?.call(0, 100, 'Uploading video...');
      
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/process360'),
      );
      
      // Add video file - handle web and mobile differently
      if (kIsWeb && videoBytes != null) {
        // Web: Use bytes directly
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            videoBytes,
            filename: filename ?? 'video.mp4',
          ),
        );
      } else if (videoFile != null) {
        // Mobile: Use file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            videoFile.path,
          ),
        );
      } else {
        throw Exception('Either videoFile or videoBytes must be provided');
      }
      
      // Send request with progress tracking
      var streamedResponse = await request.send();
      
      onProgress?.call(50, 100, 'Processing video...');
      
      // Get response
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        onProgress?.call(100, 100, 'Complete!');
        
        return Process360Result(
          success: true,
          sessionId: jsonResponse['session_id'] as String,
          frameCount: jsonResponse['frame_count'] as int,
          frameUrls: List<String>.from(jsonResponse['frame_urls'] as List),
        );
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to process video: $e');
    }
  }
  
  /// Download a frame image
  Future<List<int>> downloadFrame(String frameUrl) async {
    try {
      final response = await http.get(Uri.parse(frameUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download frame: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading frame: $e');
    }
  }
  
  /// Download all frames and save to local cache
  /// On web, returns URLs directly (no local caching)
  Future<List<String>> downloadAllFrames({
    required List<String> frameUrls,
    required String sessionId,
    Function(int current, int total, String message)? onProgress,
  }) async {
    try {
      if (kIsWeb) {
        // Web: Just return URLs directly (browser will cache them)
        onProgress?.call(frameUrls.length, frameUrls.length, 'Complete!');
        return frameUrls;
      }
      
      // Mobile: Download and cache locally
      // Note: For mobile, we'd need path_provider, but to avoid web issues,
      // we'll just return URLs for now. Can be enhanced later if needed.
      // For now, mobile also uses URLs directly
      onProgress?.call(frameUrls.length, frameUrls.length, 'Complete!');
      return frameUrls;
    } catch (e) {
      throw Exception('Failed to download frames: $e');
    }
  }
  
  /// Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
}

/// Result of 360 video processing
class Process360Result {
  final bool success;
  final String sessionId;
  final int frameCount;
  final List<String> frameUrls;
  
  Process360Result({
    required this.success,
    required this.sessionId,
    required this.frameCount,
    required this.frameUrls,
  });
}


