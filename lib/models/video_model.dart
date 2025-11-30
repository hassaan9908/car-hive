import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String? id;
  final String title;
  final String description;
  final String author;
  final String? authorId;
  final String videoUrl;
  final String? thumbnailUrl;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VideoModel({
    this.id,
    required this.title,
    required this.description,
    required this.author,
    this.authorId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.tags,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create VideoModel from Firestore document
  factory VideoModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    Timestamp? createdAtTimestamp = data['createdAt'];
    Timestamp? updatedAtTimestamp = data['updatedAt'];
    
    return VideoModel(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      author: data['author'] ?? '',
      authorId: data['authorId'],
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      createdAt: createdAtTimestamp?.toDate(),
      updatedAt: updatedAtTimestamp?.toDate(),
    );
  }

  // Convert VideoModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'author': author,
      'authorId': authorId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}