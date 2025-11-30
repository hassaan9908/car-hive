import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/blog_model.dart';
import '../models/video_model.dart';

class ContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload a new blog
  Future<String> uploadBlog(BlogModel blog) async {
    try {
      // Set timestamps if not already set
      final now = Timestamp.now();
      if (blog.createdAt == null) {
        blog = BlogModel(
          id: blog.id,
          title: blog.title,
          content: blog.content,
          author: blog.author,
          authorId: blog.authorId,
          tags: blog.tags,
          imageUrl: blog.imageUrl,
          createdAt: now.toDate(),
          updatedAt: now.toDate(),
        );
      }
      
      final docRef = await _firestore.collection('blogs').add(blog.toFirestore());
      return docRef.id;
    } on FirebaseException catch (e) {
      print('Firebase error uploading blog: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check your Firebase security rules.');
      }
      rethrow;
    } catch (e) {
      print('Error uploading blog: $e');
      rethrow;
    }
  }

  // Update an existing blog
  Future<void> updateBlog(String blogId, BlogModel blog) async {
    try {
      // Update timestamp
      final updatedBlog = BlogModel(
        id: blog.id,
        title: blog.title,
        content: blog.content,
        author: blog.author,
        authorId: blog.authorId,
        tags: blog.tags,
        imageUrl: blog.imageUrl,
        createdAt: blog.createdAt,
        updatedAt: Timestamp.now().toDate(),
      );
      
      await _firestore.collection('blogs').doc(blogId).update(updatedBlog.toFirestore());
    } catch (e) {
      print('Error updating blog: $e');
      rethrow;
    }
  }

  // Delete a blog
  Future<void> deleteBlog(String blogId) async {
    try {
      await _firestore.collection('blogs').doc(blogId).delete();
    } catch (e) {
      print('Error deleting blog: $e');
      rethrow;
    }
  }

  // Get all blogs sorted by latest first
  Future<List<BlogModel>> getAllBlogs() async {
    try {
      final snapshot = await _firestore.collection('blogs').orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => BlogModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      print('Firebase error getting blogs: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check your Firebase security rules.');
      }
      rethrow;
    } catch (e) {
      print('Error getting blogs: $e');
      rethrow;
    }
  }

  // Upload a new video
  Future<String> uploadVideo(VideoModel video) async {
    try {
      // Set timestamps if not already set
      final now = Timestamp.now();
      if (video.createdAt == null) {
        video = VideoModel(
          id: video.id,
          title: video.title,
          description: video.description,
          author: video.author,
          authorId: video.authorId,
          videoUrl: video.videoUrl,
          thumbnailUrl: video.thumbnailUrl,
          tags: video.tags,
          createdAt: now.toDate(),
          updatedAt: now.toDate(),
        );
      }
      
      final docRef = await _firestore.collection('videos').add(video.toFirestore());
      return docRef.id;
    } on FirebaseException catch (e) {
      print('Firebase error uploading video: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check your Firebase security rules.');
      }
      rethrow;
    } catch (e) {
      print('Error uploading video: $e');
      rethrow;
    }
  }

  // Update an existing video
  Future<void> updateVideo(String videoId, VideoModel video) async {
    try {
      // Update timestamp
      final updatedVideo = VideoModel(
        id: video.id,
        title: video.title,
        description: video.description,
        author: video.author,
        authorId: video.authorId,
        videoUrl: video.videoUrl,
        thumbnailUrl: video.thumbnailUrl,
        tags: video.tags,
        createdAt: video.createdAt,
        updatedAt: Timestamp.now().toDate(),
      );
      
      await _firestore.collection('videos').doc(videoId).update(updatedVideo.toFirestore());
    } catch (e) {
      print('Error updating video: $e');
      rethrow;
    }
  }

  // Delete a video
  Future<void> deleteVideo(String videoId) async {
    try {
      await _firestore.collection('videos').doc(videoId).delete();
    } catch (e) {
      print('Error deleting video: $e');
      rethrow;
    }
  }

  // Get all videos sorted by latest first
  Future<List<VideoModel>> getAllVideos() async {
    try {
      final snapshot = await _firestore.collection('videos').orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) => VideoModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      print('Firebase error getting videos: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Please check your Firebase security rules.');
      }
      rethrow;
    } catch (e) {
      print('Error getting videos: $e');
      rethrow;
    }
  }
}