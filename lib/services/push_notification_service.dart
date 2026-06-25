import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;
  String? _lastSyncedUid;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      // The notification is also saved in Firestore and shown by the bell.
      // On Android/iOS, the FCM notification appears when the app is backgrounded.
    });

    _messaging.onTokenRefresh.listen((token) async {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _saveToken(uid, token);
    });
  }

  Future<void> syncTokenForUser(AppUser user) async {
    if (_lastSyncedUid == user.uid) return;
    _lastSyncedUid = user.uid;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _saveToken(user.uid, token);
    } catch (_) {
      // Notification permission/token problems should not block login.
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'notificationPermission': 'requested',
      'notificationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
