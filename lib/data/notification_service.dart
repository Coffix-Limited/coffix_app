import 'dart:convert';
import 'dart:io';

import 'package:coffix_app/core/di/service_locator.dart';
import 'package:coffix_app/features/home/presentation/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse details) {
  // Background isolate: navigation is not available here.
  // The app will handle the notification via getInitialMessage when it resumes.
}

@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("The message is: ${message.notification?.title}");
  print("The message is: ${message.notification?.body}");
  print("The message is: ${message.data}");
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    navigatorKey.currentState?.pushNamed(HomePage.route);
  }

  Future initPushNotifications() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _firebaseMessaging.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      showNotification(
        title: notification.title,
        body: notification.body,
        payload: jsonEncode(message.data),
      );
    });
  }

  final _androidChannel = AndroidNotificationChannel(
    "daily_channel_id",
    "Daily Notifications",
    description: "Daily Notification Channel",
    importance: Importance.defaultImportance,
  );

  // INITIALIZE
  Future<void> initialize() async {
    // prepare firebase messaging
    await _firebaseMessaging.requestPermission();

    // get fcm token
    // final fcmToken = await _firebaseMessaging.getToken();
    if (Platform.isIOS) {
      await _firebaseMessaging.getAPNSToken();
    }
    // print("Token: $fcmToken");

    // prepare android init settings
    const initSettingsAndroid = AndroidInitializationSettings(
      "@drawable/launcher_icon",
    );

    // prepare ios settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // init settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    // finally, initialize the plugin!
    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == null) return;
        final data = jsonDecode(details.payload!) as Map<String, dynamic>;
        final message = RemoteMessage(data: data);
        handleMessage(message);
      },
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );
    final platform = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(_androidChannel);
    initPushNotifications();
  }

  // NOTIFICATIONS DETAIL SETUP
  NotificationDetails notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        "daily_channel_id",
        "Daily Notifications",
        channelDescription: "Daily Notification Channel",
        importance: Importance.max,
        priority: Priority.high,
        icon: "@drawable/launcher_icon",
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails(),
      payload: payload,
    );
  }
}
