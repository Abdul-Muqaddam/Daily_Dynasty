import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level handler required for background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handling — app was not running
  // flutter_local_notifications will display it automatically
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'daily_dynasty_channel',
    'Daily Dynasty Alerts',
    description: 'Trade offers, draft alerts, and game results.',
    importance: Importance.max,
    playSound: true,
  );

  /// Call once at app startup (in main.dart) to initialize FCM and local notifications.
  static Future<void> initialize() async {
    try {
      print("🔔 NotificationService: Initializing...");
      
      // 1. Request permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print("🔔 NotificationService: Permission denied.");
        return;
      }

      // 2. Set up Android notification channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 3. Initialize local notifications
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initSettings);

      // 4. Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      // 6. Save FCM token to Firestore
      await _saveTokenToFirestore();

      // 7. Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveToken(newToken);
      });
      
      print("🔔 NotificationService: Successfully initialized.");
    } catch (e) {
      print("🔔 NotificationService Error: $e");
      // Don't rethrow! Allow main() to continue to runApp().
    }
  }

  static Future<void> _saveTokenToFirestore() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      print("🔔 NotificationService: Error retrieving FCM token: $e");
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─── In-App Notification Helpers ────────────────────────────────────────────
  // These write Firestore-based notification records for the Activity Feed.

  /// Called when a trade offer is created — notifies the recipient.
  static Future<void> sendTradeOfferNotification({
    required String recipientUid,
    required String senderName,
  }) async {
    await _writeNotification(
      recipientUid: recipientUid,
      title: 'New Trade Offer!',
      body: '$senderName sent you a trade proposal. Check your Trade Block!',
      type: 'trade_offer',
    );
  }

  /// Called when the commissioner launches the Draft.
  static Future<void> sendDraftStartNotification({
    required List<String> memberUids,
    required String leagueName,
  }) async {
    for (final uid in memberUids) {
      await _writeNotification(
        recipientUid: uid,
        title: '🏈 The Draft is LIVE!',
        body: 'The $leagueName Rookie Draft has started. Get in there!',
        type: 'draft_started',
      );
    }
  }

  /// Called when a new pick is made and it is the recipient's turn.
  static Future<void> sendOnTheClockNotification({
    required String recipientUid,
  }) async {
    await _writeNotification(
      recipientUid: recipientUid,
      title: "⏰ You're On The Clock!",
      body: "It's your turn to pick in the Draft. You have 2 minutes!",
      type: 'draft_on_clock',
    );
  }

  /// Called after weekly match simulation.
  static Future<void> sendMatchResultNotification({
    required String recipientUid,
    required String result,
    required String opponentName,
    required double yourScore,
    required double theirScore,
  }) async {
    final emoji = result == 'W' ? '✅' : '❌';
    await _writeNotification(
      recipientUid: recipientUid,
      title: '$emoji Week Result: $result vs $opponentName',
      body: 'Final Score: ${yourScore.toStringAsFixed(1)} - ${theirScore.toStringAsFixed(1)}',
      type: 'match_result',
    );
  }

  static Future<void> _writeNotification({
    required String recipientUid,
    required String title,
    required String body,
    required String type,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(recipientUid)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a stream of unread notification count for badge display.
  static Stream<int> unreadCountStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Marks all notifications as read for the current user.
  static Future<void> markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
