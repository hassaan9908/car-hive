import 'dart:convert';

import 'package:carhive/models/ad_model.dart';
import 'package:carhive/pages/car_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    // Background entrypoint intentionally lightweight.
    debugPrint('Background message received: ${message.messageId}');
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications();
    await _requestPermissions();
    await _saveCurrentToken();
    _registerForegroundHandlers();
    _registerOpenHandlers();
    _registerTokenRefresh();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null || response.payload!.isEmpty) {
          return;
        }
        final Map<String, dynamic> payload =
            jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationData(payload.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ));
      },
    );

    const channel = AndroidNotificationChannel(
      'carhive_alerts',
      'CarHive Alerts',
      description: 'Chat and ad activity notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _saveCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmPlatform': 'android',
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'fcmCurrentToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> syncTokenForUser(String userId) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmPlatform': 'android',
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'fcmCurrentToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> removeCurrentTokenForUser(String userId) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _registerTokenRefresh() {
    _messaging.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || token.isEmpty) return;

      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmPlatform': 'android',
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'fcmCurrentToken': token,
      }, SetOptions(merge: true));
    });
  }

  void _registerForegroundHandlers() {
    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ?? 'CarHive';
      final body = message.notification?.body ?? '';

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'carhive_alerts',
            'CarHive Alerts',
            channelDescription: 'Chat and ad activity notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
  }

  void _registerOpenHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationData(_toStringMap(message.data));
    });

    _messaging.getInitialMessage().then((message) {
      if (message == null) return;
      _handleNotificationData(_toStringMap(message.data));
    });
  }

  Map<String, String> _toStringMap(Map<String, dynamic> input) {
    return input.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  Future<void> _handleNotificationData(Map<String, String> data) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationData(data);
      });
      return;
    }

    final type = data['type'] ?? '';
    if (type == 'chat') {
      final otherUserId = data['otherUserId'] ?? '';
      final otherUserName = data['otherUserName'] ?? 'User';
      final conversationId = data['conversationId'] ?? '';
      if (otherUserId.isEmpty || conversationId.isEmpty) {
        return;
      }

      navigator.pushNamed(
        '/chat-detail',
        arguments: {
          'conversationId': conversationId,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
        },
      );
      return;
    }

    if (type == 'ad_live') {
      final adId = data['adId'] ?? '';
      if (adId.isEmpty) {
        navigator.pushNamed('/myads');
        return;
      }
      final ad = await _loadAd(adId);
      if (ad == null) {
        navigator.pushNamed('/myads');
        return;
      }
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Navigator.of(ctx).push(
        MaterialPageRoute<void>(
          builder: (context) => CarDetailsPage(ad: ad),
        ),
      );
      return;
    }

    if (type == 'ad_saved') {
      navigator.pushNamed('/myads');
    }
  }

  Future<AdModel?> _loadAd(String adId) async {
    try {
      final snap = await _firestore.collection('ads').doc(adId).get();
      if (!snap.exists || snap.data() == null) return null;
      return AdModel.fromFirestore(snap.data()!, snap.id);
    } catch (_) {
      return null;
    }
  }
}
