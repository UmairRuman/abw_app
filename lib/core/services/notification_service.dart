// lib/core/services/notification_service.dart
// COMPLETE VERSION - ALL ISSUES FIXED
// ✅ Admin notifications work
// ✅ Customer notifications work
// ✅ Rider notifications include special instructions and payment info

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'dart:convert';
import 'dart:developer' as dev;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  dev.log('🔔 Background message: ${message.messageId}');
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

  static const String _projectId = 'abw-app-cef3e';

  static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "abw-app-cef3e",
  "private_key_id": "5e3c3a9ac29a92e3c68519b71cae42967cfd9ca8",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCkf3J90ILZ2y89\\nLSwAN9o/PPLLV1K+kv1ZVMBzKSwJ+/ibkxyaUSTL2X23m+1VIMnkJarZgSwpcUZj\\nprvaB2rvb3QTC8P1oVmJdtR23e8H+Xee1gGU/99ekoXWMl+fCReUyHmtxzOVwj+Y\\nWqSTMqHR6/FrpwjP9oYtAHzw15Th+XlhMu24z7u5iI1tQMfPey7ccf+hl51zD2Cp\\nZ0oTTfvOoSE1u2qLAqjJdjYtARM3Bfnd++y/i6kaESg3y43bLVTVWuCfyAjhXcra\\nQJlPojCSsLI9QZ4OksYcVy5Q1Kk/BCnlfdaOe2BYoxOZ+fh/sm/EPnMRWYkVx4Sr\\nBaJ3o2uBAgMBAAECggEAAip3BVoP+jKNG8b/yJ1aDDG1i3p1KYybTyhMnZeOr8j3\\nooP2DfNNXG1a+IAFYkGoXUHztTs8RVI4MfEZkX4K6RrBRZjtKRhJRGqVbJIKgI/g\\nnjpFUtycAjPd4dtpVkyf2PX0yC/fXLSHv6FKsz3cH8mPNOXCBqVbA4Lf1XbF/12s\\nn0vWR7KqCUxZYUY5wQd6vpOn05Cfdfg40l9Nwg+r/ppEHgZd7Q9Mty3sKE6qp5Ze\\nvGRxwXsUdFFzN4uDmj6TRPLI5nUPDjSmTLIkqONBPbxnsqUlGmMeG4zfsbRrWIv6\\nl3EL/ziDSf/YkAffcfN8DJ/yJWn/TGCVV6CijrPnYwKBgQDa02o8QHXV1Vm1nnRq\\nUVNfaoUTUcoKwd6JVlO+Cv8/VvMybB+YSGmNUUASesNIgfuHxn+8GZujtp5E2F9w\\nwyok0GDM8IvrIE+bpij4Et3aZ7VE1WYAvK6YnVK0Z0FXXoPcc8TG2sZVLhg0FmqQ\\nPd/soe3wEKt5j+WqLaxu0dLdfwKBgQDAcVhR9dxddkybGfG1QyqyJYgr8TVuUnfH\\nRrKOJjQUDaFRdsgwTEMURECpEnITu3inNSDy0Fnz8dJCKVvuSnu43j6u5FJsHcO3\\nuCisDopyaftjPpuExoH67DqL9N/viiHM60JC+hNLRhfVjXVlZuXTWhcz8291cCQ2\\nsVUctCA2/wKBgQChlgAaodbhofvumyWH5KnWCYhe7cRuER7M90w7R0+YbBKFp0Xl\\nY4Nd8SOJAdH2VtVwO2nTcm11hMJ2P/iqAdO6/4ybiP0pEOD4JMiX9waP4oj+XT5H\\nSQz8cR/DS4P6ijaAsZQa6y4NdE43GF50SNxzlldnMEgPKe0Dr1pnMtWs7QKBgHIF\\n9o3BfktGX8d6jNOYs4CQammW5tCyPlQtmHhPPIYxOUcaeSzc0tX8Rs+mpT750lhI\\nS3hzaQj4XFtlRBohucLktAFOOWPkEuYVUMv5ZaC7GP9Jxj3anIM/WsU4V0MH9lUD\\ng+RJZgswwch/o3JskHo1JBBdCcpsophhZAu40mmjAoGBAIfh/7eh4/YUyskZ7qtm\\nZVXDmqL2OWKQf+zutIC3jVX8rglKzhTt0BjXCsBxagY346fKQXGK38Rf84FRHZXS\\nigKZRXrar2CKtMG1uVrEH1P2j1Sb0p8WT4nyozd2cNVmFIREj4mBcS5XemJ3RIJx\\nSFQd8wsacHR4B4WvZnbMcyH3\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@abw-app-cef3e.iam.gserviceaccount.com",
  "client_id": "110400958814479297113",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40abw-app-cef3e.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  Future<void> initialize() async {
    dev.log('🔔 Initializing notification service...');
    await _requestPermission();
    await _initializeLocalNotifications();
    await _getFCMToken();
    _handleForegroundMessages();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _handleNotificationTaps();
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
    });
    dev.log('✅ Notification service initialized');
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        dev.log('🔔 Notification tapped: ${details.payload}');
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
  }

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

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      dev.log('🔔 Foreground message received');
      _showLocalNotification(message);
    });
  }

  void _handleNotificationTaps() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationNavigation(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    dev.log('📍 Navigate to: ${message.data}');
  }

  Future<void> saveFCMTokenToFirestore(String userId, String role) async {
    if (_fcmToken == null) return;

    try {
      final String collection;
      final String lowerRole = role.toLowerCase();

      if (lowerRole == 'rider') {
        collection = 'riders';
      } else if (lowerRole == 'admin') {
        collection = 'admins';
      } else {
        collection = 'users';
      }

      if (lowerRole != 'customer') {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await FirebaseFirestore.instance.collection(collection).doc(userId).set({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      dev.log('✅ FCM token saved for $role: $userId');
    } catch (e) {
      dev.log('❌ Error saving FCM token: $e');
    }
  }

  static Future<String> _getAccessToken() async {
    try {
      dev.log('🔐 Getting OAuth access token...');
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        jsonDecode(_serviceAccountJson),
      );
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(
        accountCredentials,
        scopes,
      );
      final accessToken = client.credentials.accessToken.data;
      dev.log('✅ Access token obtained');
      client.close();
      return accessToken;
    } catch (e) {
      dev.log('❌ Error getting access token: $e');
      rethrow;
    }
  }

  static Future<bool> _sendFCMNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      dev.log('📤 Sending FCM notification via HTTP v1...');
      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {'title': title, 'body': body},
            'data':
                data?.map((key, value) => MapEntry(key, value.toString())) ??
                {},
            'android': {
              'priority': 'high',
              'notification': {
                'sound': 'default',
                'notification_priority': 'PRIORITY_HIGH',
              },
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'badge': 1},
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        dev.log('✅ Notification sent successfully (v1)');
        return true;
      } else {
        dev.log('❌ Failed to send notification (v1)');
        dev.log('   Status: ${response.statusCode}');
        dev.log('   Body: ${response.body}');
        return false;
      }
    } catch (e) {
      dev.log('❌ Error sending FCM notification (v1): $e');
      return false;
    }
  }

  /// Send notification to specific user (customer)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      dev.log('🔔 Sending notification to user: $userId');

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

      final sent = await _sendFCMNotification(
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: data,
      );

      if (sent) {
        dev.log('✅ Notification delivered to user: $userId');
      }
    } catch (e) {
      dev.log('❌ Error sending notification to user: $e');
    }
  }

  /// ✅ FIXED: Send notification to admin (new order placed)
  static Future<void> sendNewOrderNotificationToAdmin({
    required String orderId,
    required String customerName,
    required double total,
    required String paymentMethod,
    String? paymentProofUrl,
  }) async {
    try {
      dev.log('🔔 Sending new order notifications to admins...');

      final adminsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();

      dev.log('📊 Found ${adminsSnapshot.docs.length} admins');

      if (adminsSnapshot.docs.isEmpty) {
        dev.log('⚠️ No admins found!');
        return;
      }

      int successCount = 0;
      for (final adminDoc in adminsSnapshot.docs) {
        final adminData = adminDoc.data();
        final fcmToken = adminData['fcmToken'] as String?;
        final adminName = adminData['name'] as String? ?? 'Admin';

        if (fcmToken == null || fcmToken.isEmpty) {
          dev.log('⚠️ Admin "$adminName" (${adminDoc.id}) has no FCM token');
          continue;
        }

        dev.log('📤 Sending to admin "$adminName"...');

        // ✅ ACTUALLY SEND VIA HTTP v1 API
        final sent = await _sendFCMNotification(
          fcmToken: fcmToken,
          title: '🛒 New Order Received!',
          body:
              '$customerName placed an order of PKR ${total.toInt()} via $paymentMethod',
          data: {
            'type': 'new_order',
            'orderId': orderId,
            'customerName': customerName,
            'total': total.toString(),
            'paymentMethod': paymentMethod,
            'paymentProofUrl': paymentProofUrl ?? '',
          },
        );

        if (sent) {
          successCount++;
          dev.log('   ✅ Sent to $adminName');
        } else {
          dev.log('   ❌ Failed to send to $adminName');
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      dev.log(
        '✅ Notifications sent to $successCount/${adminsSnapshot.docs.length} admins',
      );
    } catch (e) {
      dev.log('❌ Error sending admin notifications: $e');
    }
  }

  /// ✅ UPDATED: Send notification to rider with special instructions
  static Future<void> sendOrderAssignedNotificationToRider({
    required String riderId,
    required String orderId,
    required String customerName,
    required String storeName,
    required String deliveryAddress,
    required double deliveryFee,
    String? specialInstructions, // ✅ NEW
    String? paymentMethod, // ✅ NEW
    String? paymentProofUrl, // ✅ NEW
  }) async {
    try {
      dev.log('🔔 Sending order assigned notification to rider: $riderId');

      final riderDoc =
          await FirebaseFirestore.instance
              .collection('riders')
              .doc(riderId)
              .get();

      if (!riderDoc.exists) {
        dev.log('❌ Rider not found: $riderId');
        return;
      }

      final fcmToken = riderDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        dev.log('⚠️ Rider has no FCM token: $riderId');
        return;
      }

      // ✅ BUILD NOTIFICATION BODY WITH INSTRUCTIONS HINT
      String notificationBody =
          'Pickup from $storeName → Deliver to $customerName';

      if (paymentMethod != null && paymentMethod != 'cod') {
        notificationBody += ' • Payment: $paymentMethod';
      }

      if (specialInstructions != null && specialInstructions.isNotEmpty) {
        notificationBody += ' • ⚠️ Has special instructions';
      }

      final sent = await _sendFCMNotification(
        fcmToken: fcmToken,
        title: '🚚 New Delivery Assigned!',
        body: notificationBody,
        data: {
          'type': 'order_assigned',
          'orderId': orderId,
          'customerName': customerName,
          'storeName': storeName,
          'deliveryAddress': deliveryAddress,
          'deliveryFee': deliveryFee.toString(),
          'specialInstructions': specialInstructions ?? '', // ✅ NEW
          'paymentMethod': paymentMethod ?? 'cod', // ✅ NEW
          'paymentProofUrl': paymentProofUrl ?? '', // ✅ NEW
        },
      );

      if (sent) {
        dev.log('✅ Notification delivered to rider: $riderId');
        if (specialInstructions != null && specialInstructions.isNotEmpty) {
          dev.log('   📝 Includes special instructions');
        }
        if (paymentProofUrl != null && paymentProofUrl.isNotEmpty) {
          dev.log('   💳 Includes payment proof');
        }
      }
    } catch (e) {
      dev.log('❌ Error sending notification to rider: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
