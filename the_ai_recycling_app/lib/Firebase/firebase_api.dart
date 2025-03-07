import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  // Handle background messages
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Get the FCM token
    String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print('FCM Token: $fcmToken');
    }

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground Message: ${message.notification?.title}');
    });
  }
}
