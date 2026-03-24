import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const String _ordersChannelId = 'shinepara_orders';
  static const String _ordersChannelName = 'إشعارات الطلبات';
  static const String _ordersChannelDescription = 'إشعارات حالة الطلبات والعروض';

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

      String? token = await _getTokenSafely(waitForApnsOnIos: true);
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

  Future<String?> _getTokenSafely({bool waitForApnsOnIos = false}) async {
    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          waitForApnsOnIos) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          // APNS token can arrive slightly after app startup/login on iOS.
          for (int i = 0; i < 8 && apnsToken == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            apnsToken = await _messaging.getAPNSToken();
          }
        }
        if (apnsToken == null) {
          print('APNS token is not ready yet; skip FCM token fetch for now');
          return null;
        }
      }
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> onUserLoggedIn() async {
    try {
      if (_pendingToken != null) {
        await _sendTokenToServer(_pendingToken!);
        return;
      }
      String? token = await _getTokenSafely(waitForApnsOnIos: true);
      if (token != null) {
        _pendingToken = token;
        await _sendTokenToServer(token);
      }
    } catch (e) {
      // Push setup should never block login flow.
      print('Skipping token sync on login: $e');
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

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _ordersChannelId,
      _ordersChannelName,
      description: _ordersChannelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    RemoteNotification? notification = message.notification;
    final String? title = notification?.title ?? message.data['title']?.toString();
    final String? body = notification?.body ??
        message.data['message']?.toString() ??
        message.data['body']?.toString();

    if (!kIsWeb && (title != null || body != null)) {
      _localNotifications.show(
        message.messageId.hashCode ^ DateTime.now().millisecondsSinceEpoch,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _ordersChannelId,
            _ordersChannelName,
            channelDescription: _ordersChannelDescription,
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
    final token = await _getTokenSafely(waitForApnsOnIos: true);
    if (token != null) {
      _pendingToken = token;
      await _sendTokenToServer(token);
    }
  }
}
