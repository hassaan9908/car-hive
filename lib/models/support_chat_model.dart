import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportChatStatus {
  open,
  resolved,
}

enum SupportSenderType {
  user,
  admin,
}

class SupportUserProfile {
  final String name;
  final String avatar;
  final String email;
  final DateTime? joinedAt;

  const SupportUserProfile({
    required this.name,
    required this.avatar,
    required this.email,
    this.joinedAt,
  });

  factory SupportUserProfile.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return SupportUserProfile(
      name: _readString(data['name'], fallback: 'CarHive User'),
      avatar: _readString(data['avatar']),
      email: _readString(data['email']),
      joinedAt: _readDate(data['joinedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatar': avatar,
      'email': email,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
    };
  }
}

class SupportChat {
  final String userId;
  final String ticketNumber;
  final SupportChatStatus status;
  final String subject;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final SupportSenderType? lastSenderType;
  final int unreadByAdmin;
  final int unreadByUser;
  final SupportUserProfile userProfile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportChat({
    required this.userId,
    required this.ticketNumber,
    required this.status,
    required this.subject,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastSenderType,
    required this.unreadByAdmin,
    required this.unreadByUser,
    required this.userProfile,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportChat.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SupportChat(
      userId: documentId,
      ticketNumber: _readString(data['ticketNumber']),
      status: _readStatus(data['status']),
      subject: _readString(data['subject']),
      lastMessage: _readString(data['lastMessage']),
      lastMessageTime: _readDate(data['lastMessageTime']),
      lastSenderType: _readSenderTypeOrNull(data['lastSenderType']),
      unreadByAdmin: _readInt(data['unreadByAdmin']),
      unreadByUser: _readInt(data['unreadByUser']),
      userProfile: SupportUserProfile.fromMap(
        data['userProfile'] is Map
            ? Map<String, dynamic>.from(data['userProfile'] as Map)
            : null,
      ),
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  bool get isResolved => status == SupportChatStatus.resolved;
}

class SupportMessage {
  final String id;
  final String text;
  final String senderId;
  final SupportSenderType senderType;
  final DateTime timestamp;
  final bool isRead;

  const SupportMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderType,
    required this.timestamp,
    required this.isRead,
  });

  factory SupportMessage.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return SupportMessage(
      id: documentId,
      text: _readString(data['text']),
      senderId: _readString(data['senderId']),
      senderType: _readSenderType(data['senderType']),
      timestamp: _readDate(data['timestamp']) ?? DateTime.now(),
      isRead: data['isRead'] is bool ? data['isRead'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderType': senderType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class SupportOnlineStatus {
  final bool online;
  final DateTime? lastSeen;

  const SupportOnlineStatus({
    required this.online,
    this.lastSeen,
  });

  factory SupportOnlineStatus.fromMap(Map<String, dynamic>? data) {
    return SupportOnlineStatus(
      online: data?['online'] is bool ? data!['online'] as bool : false,
      lastSeen: _readDate(data?['lastSeen']),
    );
  }
}

String supportStatusLabel(SupportChatStatus status) {
  switch (status) {
    case SupportChatStatus.open:
      return 'Open';
    case SupportChatStatus.resolved:
      return 'Resolved';
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

SupportChatStatus _readStatus(dynamic value) {
  return value?.toString() == 'resolved'
      ? SupportChatStatus.resolved
      : SupportChatStatus.open;
}

SupportSenderType _readSenderType(dynamic value) {
  return value?.toString() == 'admin'
      ? SupportSenderType.admin
      : SupportSenderType.user;
}

SupportSenderType? _readSenderTypeOrNull(dynamic value) {
  if (value == null) return null;
  return _readSenderType(value);
}
