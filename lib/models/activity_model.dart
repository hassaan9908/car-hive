import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  userRegistered,
  adPosted,
  adApproved,
  adRejected,
  userRoleChanged,
  userStatusChanged,
}

class ActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String? userId;
  final String? adId;
  final String? adminId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.userId,
    this.adId,
    this.adminId,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ActivityModel(
      id: documentId,
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ActivityType.userRegistered,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'],
      adId: data['adId'],
      adminId: data['adminId'],
      metadata: data['metadata'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'userId': userId,
      'adId': adId,
      'adminId': adminId,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  IconData get icon {
    switch (type) {
      case ActivityType.userRegistered:
        return Icons.person_add;
      case ActivityType.adPosted:
        return Icons.add_circle;
      case ActivityType.adApproved:
        return Icons.check_circle;
      case ActivityType.adRejected:
        return Icons.cancel;
      case ActivityType.userRoleChanged:
        return Icons.admin_panel_settings;
      case ActivityType.userStatusChanged:
        return Icons.block;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.userRegistered:
        return Colors.blue;
      case ActivityType.adPosted:
        return Colors.orange;
      case ActivityType.adApproved:
        return Colors.green;
      case ActivityType.adRejected:
        return Colors.red;
      case ActivityType.userRoleChanged:
        return Colors.purple;
      case ActivityType.userStatusChanged:
        return Colors.grey;
    }
  }
}
