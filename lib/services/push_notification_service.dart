import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Push notification permission granted');
      
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      
      if (token != null) {
        _pendingToken = token;
        await _sendTokenToServer(token);
      }
    } else {
      print('Push notification permission denied');
    }

    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      await _sendTokenToServer(newToken);
    });
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await ApiClient.instance.getAuthToken();
      if (authToken != null && authToken.isNotEmpty) {
        await ApiClient.instance.post('/api/auth/fcm-token', {
          'fcm_token': token,
        });
        print('FCM token sent to server successfully');
      } else {
        print('User not logged in - FCM token not sent');
      }
    } catch (e) {
      print('Failed to send FCM token to server: $e');
    }
  }

  String? _pendingToken;

  Future<void> onUserLoggedIn() async {
    if (_pendingToken != null) {
      await _sendTokenToServer(_pendingToken!);
    } else {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'shinepara_orders',
      'إشعارات الطلبات',
      description: 'إشعارات حالة الطلبات والعروض',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'shinepara_orders',
            'إشعارات الطلبات',
            channelDescription: 'إشعارات حالة الطلبات والعروض',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification opened: ${message.data}');
    final data = message.data;
    if (data['type'] == 'order_status' || data['type']?.startsWith('order_') == true) {
      // Navigate to orders screen - implement navigation logic here
    }
  }

  Future<void> resendTokenToServer() async {
    String? token = await _messaging.getToken();
    if (token != null) {
      await _sendTokenToServer(token);
    }
  }
}
