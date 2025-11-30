import 'package:flutter/foundation.dart';
import '../models/blog_model.dart';
import '../models/video_model.dart';
import '../services/content_service.dart';

class ContentProvider with ChangeNotifier {
  final ContentService _contentService = ContentService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  List<BlogModel> _blogs = [];
  List<VideoModel> _videos = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BlogModel> get blogs => _blogs;
  List<VideoModel> get videos => _videos;
  
  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  // Clear error
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Upload a new blog
  Future<bool> uploadBlog(BlogModel blog) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _contentService.uploadBlog(blog);
      
      // Refresh blogs list
      await loadAllBlogs();
      
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Permission denied. Please make sure you are logged in as an admin and that Firebase security rules are properly configured.';
      }
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a blog
  Future<bool> deleteBlog(String blogId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _contentService.deleteBlog(blogId);
      
      // Refresh blogs list
      await loadAllBlogs();
      
      return true;
    } catch (e) {
      _setError('Failed to delete blog: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Load all blogs
  Future<void> loadAllBlogs() async {
    try {
      _setLoading(true);
      _clearError();
      
      _blogs = await _contentService.getAllBlogs();
      // Sort by createdAt in descending order (latest first)
      _blogs.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      notifyListeners();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Permission denied. Please make sure you are logged in as an admin and that Firebase security rules are properly configured.';
      }
      _setError(errorMessage);
    } finally {
      _setLoading(false);
    }
  }
  
  // Upload a new video
  Future<bool> uploadVideo(VideoModel video) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _contentService.uploadVideo(video);
      
      // Refresh videos list
      await loadAllVideos();
      
      return true;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Permission denied. Please make sure you are logged in as an admin and that Firebase security rules are properly configured.';
      }
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a video
  Future<bool> deleteVideo(String videoId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _contentService.deleteVideo(videoId);
      
      // Refresh videos list
      await loadAllVideos();
      
      return true;
    } catch (e) {
      _setError('Failed to delete video: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Load all videos
  Future<void> loadAllVideos() async {
    try {
      _setLoading(true);
      _clearError();
      
      _videos = await _contentService.getAllVideos();
      // Sort by createdAt in descending order (latest first)
      _videos.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      notifyListeners();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Permission denied. Please make sure you are logged in as an admin and that Firebase security rules are properly configured.';
      }
      _setError(errorMessage);
    } finally {
      _setLoading(false);
    }
  }
}