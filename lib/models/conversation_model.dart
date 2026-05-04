import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final int unreadCount1;
  final int unreadCount2;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Optional ad context (set when conversation is started from a listing)
  final String? adId;
  final String? adTitle;
  final String? adPrice;
  final String? adImageUrl;
  final String? adStatus;
  final String? buyerId;  // uid of the user who initiated (the buyer)
  final String? sellerId; // uid of the ad owner (the seller)

  Conversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.lastMessageSenderId = '',
    this.unreadCount1 = 0,
    this.unreadCount2 = 0,
    required this.createdAt,
    required this.updatedAt,
    this.adId,
    this.adTitle,
    this.adPrice,
    this.adImageUrl,
    this.adStatus,
    this.buyerId,
    this.sellerId,
  });

  factory Conversation.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return Conversation(
      id: documentId,
      participant1Id: data['participant1Id'] ?? '',
      participant2Id: data['participant2Id'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount1: data['unreadCount1'] ?? 0,
      unreadCount2: data['unreadCount2'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      adId: data['adId']?.toString(),
      adTitle: data['adTitle']?.toString(),
      adPrice: data['adPrice']?.toString(),
      adImageUrl: data['adImageUrl']?.toString(),
      adStatus: data['adStatus']?.toString(),
      buyerId: data['buyerId']?.toString(),
      sellerId: data['sellerId']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount1': unreadCount1,
      'unreadCount2': unreadCount2,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (adId != null) 'adId': adId,
      if (adTitle != null) 'adTitle': adTitle,
      if (adPrice != null) 'adPrice': adPrice,
      if (adImageUrl != null) 'adImageUrl': adImageUrl,
      if (adStatus != null) 'adStatus': adStatus,
      if (buyerId != null) 'buyerId': buyerId,
      if (sellerId != null) 'sellerId': sellerId,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return currentUserId == participant1Id ? participant2Id : participant1Id;
  }

  int getUnreadCountForUser(String currentUserId) {
    return currentUserId == participant1Id ? unreadCount1 : unreadCount2;
  }
}
