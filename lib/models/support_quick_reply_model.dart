import 'package:cloud_firestore/cloud_firestore.dart';

class SupportQuickTopic {
  final String id;
  final String title;
  final String icon;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportQuickTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.sortOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportQuickTopic.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SupportQuickTopic(
      id: documentId,
      title: _readString(data['title'], fallback: 'Support topic'),
      icon: _readString(data['icon']),
      sortOrder: _readInt(data['sortOrder']),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }
}

class SupportQuickQuestion {
  final String id;
  final String topicId;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportQuickQuestion({
    required this.id,
    required this.topicId,
    required this.question,
    required this.answer,
    required this.sortOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportQuickQuestion.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
    String topicId,
  ) {
    return SupportQuickQuestion(
      id: documentId,
      topicId: topicId,
      question: _readString(data['question'], fallback: 'Support question'),
      answer: _readString(data['answer']),
      sortOrder: _readInt(data['sortOrder']),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? fallback : normalized;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}
