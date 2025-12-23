import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get or create a conversation between two users
  Future<String> getOrCreateConversation(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final currentUserId = currentUser.uid;

    // Ensure participant1Id < participant2Id for consistent conversation IDs
    final String participant1Id;
    final String participant2Id;
    if (currentUserId.compareTo(otherUserId) < 0) {
      participant1Id = currentUserId;
      participant2Id = otherUserId;
    } else {
      participant1Id = otherUserId;
      participant2Id = currentUserId;
    }

    // Create a consistent conversation ID
    final conversationId = '${participant1Id}_$participant2Id';

    // Try to get the conversation, if it doesn't exist or we can't read it, create it
    try {
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (conversationDoc.exists) {
        return conversationId;
      }
    } catch (e) {
      // If we can't read it (permission denied), try to create it anyway
      print('Could not read conversation, will try to create: $e');
    }

    // Create new conversation using set with merge to avoid overwriting if it exists
    final now = DateTime.now();
    final conversationData = {
      'participant1Id': participant1Id,
      'participant2Id': participant2Id,
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': '',
      'unreadCount1': 0,
      'unreadCount2': 0,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    // Use set with merge to create if doesn't exist, or update only if fields are missing
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .set(conversationData, SetOptions(merge: true));

    return conversationId;
  }

  // Send a message
  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final conversationId = await getOrCreateConversation(receiverId);
    final now = DateTime.now();

    // Create message with status 'sent'
    final chatMessage = ChatMessage(
      id: '', // Will be set by Firestore
      conversationId: conversationId,
      senderId: currentUser.uid,
      receiverId: receiverId,
      message: message.trim(),
      timestamp: now,
      isRead: false,
      status: MessageStatus.sent,
    );

    // Add message to Firestore with status 'sent'
    final messageRef = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(chatMessage.toFirestore());

    // Update conversation
    final currentUserId = currentUser.uid;
    final isParticipant1 = _isParticipant1(currentUserId, receiverId);

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': message.trim(),
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageSenderId': currentUserId,
      'updatedAt': Timestamp.fromDate(now),
      // Increment unread count for receiver
      if (isParticipant1) 'unreadCount2': FieldValue.increment(1),
      if (!isParticipant1) 'unreadCount1': FieldValue.increment(1),
    });

    // Mark message as delivered immediately (since receiver will see it in real-time)
    // In a real app, you might want to wait for delivery confirmation
    await _markMessageAsDelivered(conversationId, messageRef.id);
  }

  // Mark a message as delivered
  Future<void> _markMessageAsDelivered(String conversationId, String messageId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': 'delivered',
      });
    } catch (e) {
      print('Error marking message as delivered: $e');
    }
  }

  // Get messages stream for a conversation
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get conversations stream for current user
  Stream<List<Conversation>> getConversationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final currentUserId = currentUser.uid;

    // Query conversations where user is participant1 (without orderBy to avoid index requirement)
    final stream1 = _firestore
        .collection('conversations')
        .where('participant1Id', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc.data(), doc.id))
            .toList());

    // Query conversations where user is participant2 (without orderBy to avoid index requirement)
    final stream2 = _firestore
        .collection('conversations')
        .where('participant2Id', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc.data(), doc.id))
            .toList());

    // Combine both streams using StreamController for better compatibility
    final controller = StreamController<List<Conversation>>();
    List<Conversation> conversations1 = [];
    List<Conversation> conversations2 = [];
    bool hasStream1 = false;
    bool hasStream2 = false;

    void emitIfReady() {
      if (hasStream1 && hasStream2) {
        final allConversations = [...conversations1, ...conversations2];
        allConversations.sort((a, b) =>
            b.lastMessageTime.compareTo(a.lastMessageTime));
        if (!controller.isClosed) {
          controller.add(allConversations);
        }
      }
    }

    final subscription1 = stream1.listen(
      (list) {
        conversations1 = list;
        hasStream1 = true;
        emitIfReady();
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    final subscription2 = stream2.listen(
      (list) {
        conversations2 = list;
        hasStream2 = true;
        emitIfReady();
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    // Cancel subscriptions when controller is closed
    controller.onCancel = () {
      subscription1.cancel();
      subscription2.cancel();
    };

    return controller.stream;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final currentUserId = currentUser.uid;

    // Get conversation to determine which participant is reading
    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      return;
    }

    final conversation =
        Conversation.fromFirestore(conversationDoc.data()!, conversationId);
    final isParticipant1 = conversation.participant1Id == currentUserId;

    // Mark all unread messages as read and update their status
    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'status': 'read', // Update status to read
      });
    }

    // Also update messages that are delivered but not read yet
    final deliveredMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'delivered')
        .get();

    for (var doc in deliveredMessages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'status': 'read',
      });
    }

    // Reset unread count
    batch.update(
      _firestore.collection('conversations').doc(conversationId),
      {
        if (isParticipant1) 'unreadCount1': 0,
        if (!isParticipant1) 'unreadCount2': 0,
      },
    );

    await batch.commit();
  }

  // Helper method to determine if current user is participant1
  bool _isParticipant1(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0;
  }

  // Delete a message (deletes for all users)
  Future<void> deleteMessage(String conversationId, String messageId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Get the message to check if user is sender or participant
    final messageDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!messageDoc.exists) {
      throw Exception('Message not found');
    }

    final messageData = messageDoc.data()!;
    final senderId = messageData['senderId'] as String;

    // Check if user is the sender or a participant in the conversation
    final conversationDoc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      throw Exception('Conversation not found');
    }

    final conversationData = conversationDoc.data()!;
    final participant1Id = conversationData['participant1Id'] as String;
    final participant2Id = conversationData['participant2Id'] as String;

    // Only allow deletion if user is the sender or a participant
    if (currentUser.uid != senderId &&
        currentUser.uid != participant1Id &&
        currentUser.uid != participant2Id) {
      throw Exception('You do not have permission to delete this message');
    }

    // Delete the message
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();

    // Update conversation's lastMessage if this was the last message
    final lastMessageSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastMessageSnapshot.docs.isNotEmpty) {
      final lastMessage = lastMessageSnapshot.docs.first.data();
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': lastMessage['message'] ?? '',
        'lastMessageTime': lastMessage['timestamp'],
        'lastMessageSenderId': lastMessage['senderId'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // No messages left, clear last message
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get user info for display
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}

