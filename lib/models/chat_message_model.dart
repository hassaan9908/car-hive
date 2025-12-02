import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus {
  sent,      // Single tick - message sent
  delivered, // Double tick - message delivered to receiver
  read,      // Double tick (blue) - message read by receiver
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Handle status conversion from string to enum
    MessageStatus messageStatus = MessageStatus.sent;
    if (data['status'] != null) {
      final statusString = data['status'].toString().toLowerCase();
      switch (statusString) {
        case 'delivered':
          messageStatus = MessageStatus.delivered;
          break;
        case 'read':
          messageStatus = MessageStatus.read;
          break;
        default:
          messageStatus = MessageStatus.sent;
      }
    } else if (data['isRead'] == true) {
      // Backward compatibility: if isRead is true, set status to read
      messageStatus = MessageStatus.read;
    }

    return ChatMessage(
      id: documentId,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      status: messageStatus,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'status': status.toString().split('.').last, // Store as 'sent', 'delivered', or 'read'
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }
}

