// lib/core/services/notification_service.dart
// MILESTONE 3 - Firebase Cloud Messaging Service

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

// ✅ TOP-LEVEL FUNCTION for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log('🔔 Background message: ${message.messageId}');
  dev.log('📬 Title: ${message.notification?.title}');
  dev.log('📄 Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    dev.log('🔔 Initializing notification service...');

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    await _getFCMToken();

    // Handle foreground messages
    _handleForegroundMessages();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification taps
    _handleNotificationTaps();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      dev.log('🔄 FCM Token refreshed');
      _fcmToken = newToken;
      // Update token in Firestore if user is logged in
    });

    dev.log('✅ Notification service initialized');
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    dev.log('📱 Permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications (for foreground display)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings, // ✅ FIXED: Added parameter name
      onDidReceiveNotificationResponse: (details) {
        dev.log('🔔 Notification tapped: ${details.payload}');
        // Handle notification tap - navigate to appropriate screen
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      dev.log('✅ FCM Token: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      dev.log('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dev.log('🔔 Foreground message received');
      dev.log('📬 Title: ${message.notification?.title}');
      dev.log('📄 Body: ${message.notification?.body}');
      dev.log('📦 Data: ${message.data}');

      // Show local notification
      _showLocalNotification(message);
    });
  }

  /// Handle notification taps (when app was in background/terminated)
  void _handleNotificationTaps() {
    // App opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        dev.log('🔔 App opened from notification: ${message.messageId}');
        _handleNotificationNavigation(message);
      }
    });

    // App opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      dev.log(
        '🔔 App opened from background notification: ${message.messageId}',
      );
      _handleNotificationNavigation(message);
    });
  }

  /// Show local notification (foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: message.hashCode, // ✅ FIXED: Added parameter name
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationDetails: notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;

    // Extract navigation info
    final type = data['type'] as String?;
    final orderId = data['orderId'] as String?;

    dev.log('📍 Navigate to: type=$type, orderId=$orderId');

    // TODO: Implement navigation using GoRouter
    // Example:
    // if (type == 'new_order' && orderId != null) {
    //   navigatorKey.currentContext?.push('/admin/orders/$orderId');
    // }
  }

  /// Save FCM token to Firestore (call after user login)
  Future<void> saveFCMTokenToFirestore(String userId, String role) async {
    if (_fcmToken == null) {
      dev.log('⚠️ No FCM token to save');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      dev.log('✅ FCM token saved for user: $userId ($role)');
    } catch (e) {
      dev.log('❌ Error saving FCM token: $e');
    }
  }

  /// Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!userDoc.exists) {
        dev.log('❌ User not found: $userId');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        dev.log('⚠️ User has no FCM token: $userId');
        return;
      }

      // Create notification document in Firestore
      // Cloud Function will handle actual sending
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      dev.log('✅ Notification queued for user: $userId');
    } catch (e) {
      dev.log('❌ Error sending notification: $e');
    }
  }

  /// Send notification to admin (new order placed)
  static Future<void> sendNewOrderNotificationToAdmin({
    required String orderId,
    required String customerName,
    required double total,
    required String paymentMethod,
    String? paymentProofUrl,
  }) async {
    try {
      // Get all admin users
      final adminsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();

      for (final adminDoc in adminsSnapshot.docs) {
        await sendNotificationToUser(
          userId: adminDoc.id,
          title: '🛒 New Order Received!',
          body:
              '$customerName placed an order of PKR ${total.toInt()} via $paymentMethod',
          data: {
            'type': 'new_order',
            'orderId': orderId,
            'customerName': customerName,
            'total': total,
            'paymentMethod': paymentMethod,
            'paymentProofUrl': paymentProofUrl ?? '',
          },
        );
      }

      dev.log('✅ New order notifications sent to admins');
    } catch (e) {
      dev.log('❌ Error sending admin notifications: $e');
    }
  }

  /// Send notification to rider (order assigned)
  static Future<void> sendOrderAssignedNotificationToRider({
    required String riderId,
    required String orderId,
    required String customerName,
    required String storeName,
    required String deliveryAddress,
    required double deliveryFee,
  }) async {
    await sendNotificationToUser(
      userId: riderId,
      title: '🚚 New Delivery Assigned!',
      body: 'Pickup from $storeName → Deliver to $customerName',
      data: {
        'type': 'order_assigned',
        'orderId': orderId,
        'customerName': customerName,
        'storeName': storeName,
        'deliveryAddress': deliveryAddress,
        'deliveryFee': deliveryFee,
      },
    );

    dev.log('✅ Order assigned notification sent to rider: $riderId');
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
