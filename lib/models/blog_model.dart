import 'package:cloud_firestore/cloud_firestore.dart';

class BlogModel {
  final String? id;
  final String title;
  final String content;
  final String author;
  final String? authorId;
  final List<String>? tags;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BlogModel({
    this.id,
    required this.title,
    required this.content,
    required this.author,
    this.authorId,
    this.tags,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create BlogModel from Firestore document
  factory BlogModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    Timestamp? createdAtTimestamp = data['createdAt'];
    Timestamp? updatedAtTimestamp = data['updatedAt'];
    
    return BlogModel(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      authorId: data['authorId'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      imageUrl: data['imageUrl'],
      createdAt: createdAtTimestamp?.toDate(),
      updatedAt: updatedAtTimestamp?.toDate(),
    );
  }

  // Convert BlogModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'authorId': authorId,
      'tags': tags,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}