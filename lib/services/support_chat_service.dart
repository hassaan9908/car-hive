import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/support_chat_model.dart';
import '../models/support_quick_reply_model.dart';

class SupportChatService {
  SupportChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  static const String welcomeMessage =
      "Hi! How can we help you today? Describe your issue and we'll get back to you shortly.";

  DocumentReference<Map<String, dynamic>> chatRef(String userId) {
    return _firestore.collection('supportChats').doc(userId);
  }

  CollectionReference<Map<String, dynamic>> messagesRef(String userId) {
    return chatRef(userId).collection('messages');
  }

  CollectionReference<Map<String, dynamic>> get quickTopicsRef {
    return _firestore.collection('supportQuickReplies');
  }

  CollectionReference<Map<String, dynamic>> quickQuestionsRef(String topicId) {
    return quickTopicsRef.doc(topicId).collection('questions');
  }

  Stream<SupportOnlineStatus> supportStatusStream() {
    return _firestore
        .collection('config')
        .doc('supportStatus')
        .snapshots()
        .map((doc) => SupportOnlineStatus.fromMap(doc.data()));
  }

  Stream<SupportChat?> currentUserChatStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return chatRef(user.uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      final ticket = data['ticketNumber']?.toString().trim() ?? '';
      if (ticket.isEmpty) return null;
      return SupportChat.fromFirestore(data, doc.id);
    });
  }

  Stream<List<SupportChat>> allChatsStream() {
    return _firestore
        .collection('supportChats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) =>
                (doc.data()['ticketNumber']?.toString().trim().isNotEmpty ??
                    false))
            .map((doc) => SupportChat.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SupportMessage>> messagesStream(String userId) {
    return messagesRef(userId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessage.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SupportQuickTopic>> quickTopicsStream({
    bool activeOnly = true,
  }) {
    return quickTopicsRef.orderBy('sortOrder').snapshots().map((snapshot) {
      final topics = snapshot.docs
          .map((doc) => SupportQuickTopic.fromFirestore(doc.data(), doc.id))
          .where((topic) => !activeOnly || topic.isActive)
          .toList();
      topics.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return topics;
    });
  }

  Stream<List<SupportQuickQuestion>> quickQuestionsStream(
    String topicId, {
    bool activeOnly = true,
  }) {
    return quickQuestionsRef(topicId).orderBy('sortOrder').snapshots().map(
      (snapshot) {
        final questions = snapshot.docs
            .map((doc) => SupportQuickQuestion.fromFirestore(
                  doc.data(),
                  doc.id,
                  topicId,
                ))
            .where((question) => !activeOnly || question.isActive)
            .toList();
        questions.sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          if (order != 0) return order;
          return a.question.toLowerCase().compareTo(b.question.toLowerCase());
        });
        return questions;
      },
    );
  }

  Future<void> sendUserMessage(String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in to use live chat.');
    final message = text.trim();
    if (message.isEmpty) return;

    await _ensureOpenChatForUser(user, message);
    final now = DateTime.now();
    final messageRef = messagesRef(user.uid).doc();
    final batch = _firestore.batch();

    batch.set(messageRef, {
      'text': message,
      'senderId': user.uid,
      'senderType': 'user',
      'timestamp': Timestamp.fromDate(now),
      'isRead': false,
    });
    batch.set(
      chatRef(user.uid),
      {
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastSenderType': 'user',
        'unreadByAdmin': FieldValue.increment(1),
        'unreadByUser': 0,
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> sendAdminMessage({
    required String userId,
    required String text,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('Admin is not authenticated.');
    final message = text.trim();
    if (message.isEmpty) return;

    final now = DateTime.now();
    final messageRef = messagesRef(userId).doc();
    final batch = _firestore.batch();

    batch.set(messageRef, {
      'text': message,
      'senderId': admin.uid,
      'senderType': 'admin',
      'timestamp': Timestamp.fromDate(now),
      'isRead': false,
    });
    batch.set(
      chatRef(userId),
      {
        'lastMessage': message,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastSenderType': 'admin',
        'unreadByUser': FieldValue.increment(1),
        'unreadByAdmin': 0,
        'updatedAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await _trySendPushNotification(userId: userId, message: message);
  }

  Future<void> markReadByUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _markRead(
      userId: user.uid,
      readerType: SupportSenderType.user,
      senderTypeToMark: SupportSenderType.admin,
      unreadField: 'unreadByUser',
    );
  }

  Future<void> markReadByAdmin(String userId) async {
    await _markRead(
      userId: userId,
      readerType: SupportSenderType.admin,
      senderTypeToMark: SupportSenderType.user,
      unreadField: 'unreadByAdmin',
    );
  }

  Future<void> markResolved(SupportChat chat) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('Admin is not authenticated.');

    final now = DateTime.now();
    final finalMessage =
        'Your support ticket #${chat.ticketNumber} has been marked as resolved. Thank you for contacting CarHive Support!';
    final batch = _firestore.batch();
    final messageRef = messagesRef(chat.userId).doc();

    batch.set(messageRef, {
      'text': finalMessage,
      'senderId': admin.uid,
      'senderType': 'admin',
      'timestamp': Timestamp.fromDate(now),
      'isRead': false,
    });
    batch.update(chatRef(chat.userId), {
      'status': 'resolved',
      'lastMessage': finalMessage,
      'lastMessageTime': Timestamp.fromDate(now),
      'lastSenderType': 'admin',
      'unreadByUser': FieldValue.increment(1),
      'unreadByAdmin': 0,
      'updatedAt': Timestamp.fromDate(now),
      'resolvedAt': Timestamp.fromDate(now),
      'resolvedBy': admin.uid,
    });

    await batch.commit();
    await _trySendPushNotification(userId: chat.userId, message: finalMessage);
  }

  Future<void> startNewChat() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in to use live chat.');

    while (true) {
      final existingMessages = await messagesRef(user.uid).limit(450).get();
      if (existingMessages.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in existingMessages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    final ticketNumber = await _nextTicketNumber();
    final now = DateTime.now();
    await chatRef(user.uid).set({
      'ticketNumber': ticketNumber,
      'status': 'open',
      'subject': '',
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(now),
      'lastSenderType': null,
      'unreadByAdmin': 0,
      'unreadByUser': 0,
      'userProfile': await _buildUserProfile(user),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> setAdminOnline(bool online) async {
    final user = _auth.currentUser;
    await _firestore.collection('config').doc('supportStatus').set({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
      if (user != null) 'adminId': user.uid,
    }, SetOptions(merge: true));
  }

  Future<void> createQuickTopic({
    required String title,
    required String icon,
    required int sortOrder,
    required bool isActive,
  }) async {
    await quickTopicsRef.add({
      'title': title.trim(),
      'icon': icon.trim(),
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateQuickTopic({
    required String topicId,
    required String title,
    required String icon,
    required int sortOrder,
    required bool isActive,
  }) async {
    await quickTopicsRef.doc(topicId).update({
      'title': title.trim(),
      'icon': icon.trim(),
      'sortOrder': sortOrder,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuickTopic(String topicId) async {
    while (true) {
      final questions = await quickQuestionsRef(topicId).limit(450).get();
      if (questions.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in questions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await quickTopicsRef.doc(topicId).delete();
  }

  Future<void> createQuickQuestion({
    required String topicId,
    required String question,
    required String answer,
    required int sortOrder,
    required bool isActive,
  }) async {
    await quickQuestionsRef(topicId).add({
      'question': question.trim(),
      'answer': answer.trim(),
      'sortOrder': sortOrder,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateQuickQuestion({
    required String topicId,
    required String questionId,
    required String question,
    required String answer,
    required int sortOrder,
    required bool isActive,
  }) async {
    await quickQuestionsRef(topicId).doc(questionId).update({
      'question': question.trim(),
      'answer': answer.trim(),
      'sortOrder': sortOrder,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuickQuestion({
    required String topicId,
    required String questionId,
  }) async {
    await quickQuestionsRef(topicId).doc(questionId).delete();
  }

  Future<void> seedStarterQuickReplies() async {
    final starters = <Map<String, dynamic>>[
      {
        'title': 'My Booking Issue',
        'icon': 'Car',
        'questions': [
          {
            'question': "I didn't receive confirmation",
            'answer':
                'Please check your notifications and email inbox first. If confirmation is still missing, share your booking date and area with support so we can verify it.',
          },
          {
            'question': 'Wrong date was booked',
            'answer':
                'You can request a reschedule from My Visits. If the date was selected incorrectly by mistake, send the correct date to support and we will help you adjust it.',
          },
          {
            'question': 'I want to cancel',
            'answer':
                'Open My Visits and check the visit status. If cancellation is not available there, talk to support with your ticket details.',
          },
        ],
      },
      {
        'title': 'Payment Problem',
        'icon': 'Pay',
        'questions': [
          {
            'question': 'Payment was deducted',
            'answer':
                'If your payment was deducted but the action is not updated, wait a few minutes and refresh. If it still fails, send the transaction ID to support.',
          },
          {
            'question': 'Promotion did not activate',
            'answer':
                'Promotions can take a short time to reflect. If your ad is still not promoted, share the ad title and payment reference with support.',
          },
        ],
      },
      {
        'title': 'My Ad Not Showing',
        'icon': 'Ad',
        'questions': [
          {
            'question': 'My ad is pending',
            'answer':
                'Pending ads are reviewed before appearing publicly. Please check My Ads for the current status and rejection reason if one exists.',
          },
          {
            'question': 'My active ad disappeared',
            'answer':
                'Please check whether the ad was marked sold, removed, expired, or rejected. Support can verify the latest status for you.',
          },
        ],
      },
      {
        'title': 'Reschedule Visit',
        'icon': 'Time',
        'questions': [
          {
            'question': 'I want another slot',
            'answer':
                'Open My Visits and submit a reschedule request with your preferred date and time slot. Admin will review the request.',
          },
          {
            'question': 'My request is pending',
            'answer':
                'Pending requests are reviewed by admin. You will get an update when it is accepted or rejected.',
          },
        ],
      },
      {
        'title': 'Other / Custom',
        'icon': 'Help',
        'questions': [
          {
            'question': 'I need help with something else',
            'answer':
                'No problem. Tap Talk to a human and describe your issue so CarHive Support can help you directly.',
          },
        ],
      },
    ];

    final batch = _firestore.batch();
    for (var topicIndex = 0; topicIndex < starters.length; topicIndex++) {
      final topic = starters[topicIndex];
      final questions = (topic['questions'] as List)
          .map((value) => Map<String, String>.from(value as Map))
          .toList();
      final topicRef = quickTopicsRef.doc();
      batch.set(topicRef, {
        'title': topic['title'],
        'icon': topic['icon'],
        'sortOrder': topicIndex,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (var questionIndex = 0;
          questionIndex < questions.length;
          questionIndex++) {
        final question = questions[questionIndex];
        batch.set(topicRef.collection('questions').doc(), {
          'question': question['question'],
          'answer': question['answer'],
          'sortOrder': questionIndex,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<SupportChat> _ensureOpenChatForUser(
      User user, String firstText) async {
    final ref = chatRef(user.uid);
    final snapshot = await ref.get();
    final existingData = snapshot.data();
    if (snapshot.exists &&
        existingData?['status'] != 'resolved' &&
        (existingData?['ticketNumber']?.toString().trim().isNotEmpty ??
            false)) {
      return SupportChat.fromFirestore(snapshot.data()!, snapshot.id);
    }

    final ticketNumber = await _nextTicketNumber();
    final now = DateTime.now();
    final subject = _subjectFrom(firstText);
    final data = {
      'ticketNumber': ticketNumber,
      'status': 'open',
      'subject': subject,
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(now),
      'lastSenderType': null,
      'unreadByAdmin': 0,
      'unreadByUser': 0,
      'userProfile': await _buildUserProfile(user),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
    await ref.set(data);
    return SupportChat.fromFirestore(data, user.uid);
  }

  Future<String> _nextTicketNumber() async {
    final counterRef = _firestore.collection('config').doc('ticketCounter');
    final next = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final current = snapshot.exists && snapshot.data()?['lastNumber'] is num
          ? (snapshot.data()!['lastNumber'] as num).toInt()
          : 1000;
      final resolved = current + 1;
      transaction.set(
        counterRef,
        {
          'lastNumber': resolved,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return resolved;
    });
    return 'CH-${next.toString().padLeft(4, '0')}';
  }

  Future<Map<String, dynamic>> _buildUserProfile(User user) async {
    String name = user.displayName?.trim() ?? '';
    String email = user.email?.trim() ?? '';
    String avatar = user.photoURL?.trim() ?? '';
    DateTime? joinedAt;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      if (data != null) {
        name = _firstNotEmpty([
          data['displayName'],
          data['fullName'],
          data['username'],
          name,
          email.split('@').first,
        ]);
        email = _firstNotEmpty([data['email'], email]);
        avatar = _firstNotEmpty([data['photoUrl'], data['avatar'], avatar]);
        joinedAt = _readDate(data['createdAt']);
      }
    } catch (_) {
      name = name.isNotEmpty ? name : email.split('@').first;
    }

    return SupportUserProfile(
      name: name.isNotEmpty ? name : 'CarHive User',
      email: email,
      avatar: avatar,
      joinedAt: joinedAt,
    ).toMap();
  }

  Future<void> _markRead({
    required String userId,
    required SupportSenderType readerType,
    required SupportSenderType senderTypeToMark,
    required String unreadField,
  }) async {
    final chatSnapshot = await chatRef(userId).get();
    if (!chatSnapshot.exists) return;

    final unreadMessages = await messagesRef(userId)
        .where('senderType', isEqualTo: senderTypeToMark.name)
        .where('isRead', isEqualTo: false)
        .limit(400)
        .get();
    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    batch.update(
      chatRef(userId),
      {
        unreadField: 0,
        '${readerType.name}LastReadAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
  }

  Future<void> _trySendPushNotification({
    required String userId,
    required String message,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendSupportChatNotification');
      await callable.call(<String, dynamic>{
        'userId': userId,
        'title': 'CarHive Support',
        'body': _preview(message),
        'route': '/support-chat',
      });
    } catch (e) {
      await _firestore.collection('support_notification_requests').add({
        'userId': userId,
        'title': 'CarHive Support',
        'body': _preview(message),
        'route': '/support-chat',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    }
  }

  String _subjectFrom(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 60) return normalized;
    return '${normalized.substring(0, 57)}...';
  }

  String _preview(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 100) return normalized;
    return '${normalized.substring(0, 97)}...';
  }

  String _firstNotEmpty(List<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
