// services/notification_service.dart
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import 'notification_count_service.dart'; // Import count service

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final String? baseUrl = dotenv.env['BASE_URL'];

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const androidInitialization = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions
    await requestPermissions();

    // Setup message handlers
    setupMessageHandlers();
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Permission granted: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Setup message handlers
  void setupMessageHandlers() {
    // Foreground messages
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('Foreground message: ${message.notification?.title}');
    //   showLocalNotification(message);
    //
    //   // Increase notification count
    //   NotificationCountService().increaseCount();
    // });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notifications_enabled') ?? true;

      if (enabled) {
        print('Foreground message: ${message.notification?.title}');
        showLocalNotification(message);

        // Increase notification count
        NotificationCountService().increaseCount();
      } else {
        print("User menonaktifkan notifikasi, tidak ditampilkan");
      }
    });
    // Background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background message tapped: ${message.data}');
      handleNotificationTap(message.data);
    });

    // Terminated state message tap
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Terminated message tapped: ${message.data}');
        Future.delayed(const Duration(seconds: 1), () {
          handleNotificationTap(message.data);
        });
      }
    });
  }

  // Show local notification when app is in foreground
  Future<void> showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'You have a new message',
      details,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      print('Notification tapped: ${response.payload}');
      // Parse payload and handle navigation
      // You can use your app router here
    }
  }

  // Handle navigation based on notification data
  void handleNotificationTap(Map<String, dynamic> data) {
    print('Handling notification tap with data: $data');

    // Example navigation based on notification type
    String? type = data['type'];
    switch (type) {
      case 'order':
      // Navigate to order details
        print('Navigate to order: ${data['order_id']}');
        break;
      case 'promo':
      // Navigate to promo page
        print('Navigate to promo: ${data['promo_id']}');
        break;
      case 'chat':
      // Navigate to chat
        print('Navigate to chat: ${data['chat_id']}');
        break;
      default:
      // Navigate to home or default page
        print('Navigate to default page');
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Check permission status
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  // Show permission dialog for denied permissions
  Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Notifikasi'),
          content: const Text(
            'Aplikasi membutuhkan izin notifikasi untuk memberikan update terbaru tentang pesanan dan promo. '
                'Silakan aktifkan notifikasi di pengaturan aplikasi.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Nanti'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Pengaturan'),
              onPressed: () {
                Navigator.of(context).pop();
                // Open app settings
                // You might need to add app_settings package
                // AppSettings.openNotificationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  // Get notification user service
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final url = Uri.parse("${baseUrl!}/api/notifications/$userId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List notifications = data['data'];

      return notifications.map((n) => NotificationModel.fromJson(n)).toList();
    } else {
      throw Exception("Failed to load notifications");
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final url = Uri.parse("${baseUrl!}/api/notifications/$notificationId/read");
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Update notification count service
      NotificationCountService().decreaseCount();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Failed to mark notification as read");
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    final url = Uri.parse("${baseUrl!}/api/notifications/$userId/read-all");
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Reset notification count
      NotificationCountService().resetCount();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? "Failed to mark all notifications as read");
    }
  }
}