import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String adId;
  final String? adTitle;
  final String? adOwnerId;
  final String userId;
  final String? userName;
  final String comment;
  final int rating; // 1-5
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.adId,
    this.adTitle,
    this.adOwnerId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ReviewModel(
      id: documentId,
      adId: data['adId'] ?? '',
      adTitle: data['adTitle'],
      adOwnerId: data['adOwnerId'],
      userId: data['userId'] ?? '',
      userName: data['userName'],
      comment: data['comment'] ?? '',
      rating: (data['rating'] ?? 0) is int
          ? data['rating'] as int
          : int.tryParse('${data['rating']}') ?? 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] != null)
              ? DateTime.tryParse('${data['createdAt']}') ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adId': adId,
      'adTitle': adTitle,
      'adOwnerId': adOwnerId,
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
