import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/splash/video_splash_screen.dart';
import 'services/push_notification_service.dart';
import 'services/providers.dart';

const String _ordersChannelId = 'shinepara_orders';
const String _ordersChannelName = 'إشعارات الطلبات';
const String _ordersChannelDescription = 'إشعارات حالة الطلبات والعروض';

final FlutterLocalNotificationsPlugin _backgroundNotifications =
    FlutterLocalNotificationsPlugin();
bool _backgroundNotificationsInitialized = false;

Future<void> _ensureBackgroundNotificationsReady() async {
  if (_backgroundNotificationsInitialized) return;

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _backgroundNotifications.initialize(initSettings);
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    _ordersChannelId,
    _ordersChannelName,
    description: _ordersChannelDescription,
    importance: Importance.high,
  );
  await _backgroundNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  _backgroundNotificationsInitialized = true;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ensureBackgroundNotificationsReady();

  // For data-only pushes, Android/iOS won't display a system banner by default.
  final title = message.notification?.title ?? message.data['title']?.toString();
  final body = message.notification?.body ??
      message.data['message']?.toString() ??
      message.data['body']?.toString();

  if (message.notification == null && (title != null || body != null)) {
    await _backgroundNotifications.show(
      message.messageId.hashCode ^ DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _ordersChannelId,
          _ordersChannelName,
          channelDescription: _ordersChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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

  debugPrint('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge + transparent status bar so our background fills the notch.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS (dark background => light icons)
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Register background handler early. Firebase will be initialized inside it.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Capture startup/runtime errors in release builds (helps diagnose "white screen").
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  runApp(
    const ProviderScope(
      child: ShineparaApp(),
    ),
  );
}

class ShineparaApp extends ConsumerStatefulWidget {
  const ShineparaApp({super.key});

  @override
  ConsumerState<ShineparaApp> createState() => _ShineparaAppState();
}

class _ShineparaAppState extends ConsumerState<ShineparaApp>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _videoDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final isLoggedIn = ref.read(authProvider) != null;
      if (isLoggedIn) {
        PushNotificationService().resendTokenToServer();
      }
    }
  }

  Future<void> _bootstrap() async {
    // Never let startup services block the first frame.
    bool firebaseReady = false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20));
      firebaseReady = true;
    } catch (e, st) {
      debugPrint('Firebase init failed: $e');
      debugPrintStack(stackTrace: st);
    }

    if (firebaseReady) {
      try {
        await PushNotificationService()
            .init()
            .timeout(const Duration(seconds: 25));
      } catch (e, st) {
        debugPrint('Push init failed: $e');
        debugPrintStack(stackTrace: st);
      }
    }

    try {
      await ref
          .read(authProvider.notifier)
          .tryAutoLogin()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Auto login failed: $e');
    }
    try {
      await ref
          .read(appLocaleProvider.notifier)
          .load()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Locale load failed: $e');
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_videoDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: VideoSplashScreen(
          key: const ValueKey('video-splash'),
          allowSkip: false,
          onDone: () {
            if (mounted) {
              setState(() {
                _videoDone = true;
              });
            }
          },
        ),
      );
    }

    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _InitHoldScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Shine - العناية بالبشرة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      locale: ref.watch(appLocaleProvider),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final locale = ref.watch(appLocaleProvider);
        return Directionality(
          textDirection:
              locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}

class _InitHoldScreen extends StatelessWidget {
  const _InitHoldScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2D1714),
      body: SizedBox.expand(),
    );
  }
}
