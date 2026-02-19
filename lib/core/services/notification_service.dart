import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  factory NotificationService() {
    return instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permission

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log('User granted permission: ${settings.authorizationStatus}');

    // Get FCM Token
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      log('FCM Token: $fcmToken');
    } catch (e) {
      log('Error getting FCM token: $e');
    }

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification clicked: ${response.payload}');
        // Handle notification tap logic here if needed
      },
    );

    // Foreground Message Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
        showNotification(message);
      }
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    final String? imageUrl =
        message.notification?.android?.imageUrl ?? message.data['image'];
    BigPictureStyleInformation? bigPictureStyleInformation;

    if (imageUrl != null) {
      try {
        final String? bigPicturePath = await _downloadAndSaveFile(
          imageUrl,
          'bigPicture',
        );
        if (bigPicturePath != null) {
          bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicturePath),
            hideExpandedLargeIcon: true,
            contentTitle: message.notification?.title,
            htmlFormatContentTitle: true,
            summaryText: message.notification?.body,
            htmlFormatSummaryText: true,
          );
        }
      } catch (e) {
        log('Error downloading image: $e');
      }
    }

    AndroidNotificationDetails
    androidNotificationDetails = AndroidNotificationDetails(
      'high_importance_channel', // ID must match the one in AndroidManifest.xml
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: bigPictureStyleInformation,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: notificationDetails,
      payload: message.data.toString(),
    );
  }

  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = Directory.systemTemp;
      final String filePath = '${directory.path}/$fileName.jpg';
      final dio = Dio();
      await dio.download(url, filePath);
      return filePath;
    } catch (e) {
      log('Error downloading file: $e');
      return null;
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }
}
