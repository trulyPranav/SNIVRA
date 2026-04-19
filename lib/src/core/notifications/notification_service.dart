import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/tokens/data/repository/token_repo.dart';

// ─── Notification channel constants ──────────────────────────────────────────
const _kChannelId = 'snivra_bookings';
const _kChannelName = 'Booking Notifications';
const _kChannelDescription =
    'Alerts for booking confirmations, arrivals, completions and cancellations';

// ─── Background handler (top-level, separate isolate) ────────────────────────
// Called when the app is in the background or terminated.
// Firebase MUST be re-initialised here because this runs in its own isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Re-init Firebase in the background isolate.
  await Firebase.initializeApp();

  // Notification messages: FCM shows them automatically on Android when the
  // app is backgrounded/terminated — no manual work needed.
  // Data-only messages: must be shown manually.
  if (message.notification == null) {
    await _showNotification(message);
  }
}

// ─── Shared display helper (used from both foreground & background) ───────────
Future<void> _showNotification(RemoteMessage message) async {
  final title =
      message.notification?.title ?? message.data['title'] as String?;
  final body = message.notification?.body ?? message.data['body'] as String?;
  if (title == null && body == null) return;

  final localNotifications = FlutterLocalNotificationsPlugin();
  await localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await localNotifications.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

// ─── NotificationService ─────────────────────────────────────────────────────

/// Singleton that owns all Firebase Messaging setup, foreground notification
/// display, and FCM token registration.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  TokenRepository? _tokenRepo;
  bool _initialized = false;

  // ── Configuration ──────────────────────────────────────────────────────────

  void configure({required TokenRepository tokenRepo}) {
    _tokenRepo = tokenRepo;
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register the top-level background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+ shows a dialog; older versions are no-op).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialise flutter_local_notifications for foreground messages.
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Create the Android notification channel used for all booking alerts.
    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show notifications while the app is in the foreground.
    // Handles both notification messages and data-only messages.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Re-register when FCM rotates the token.
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // ── Token registration ─────────────────────────────────────────────────────

  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _tokenRepo?.registerFcmToken(token);
      }
    } catch (_) {
      // Best-effort — do not crash the app.
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    // Use the shared helper so both notification-payload and data-only
    // messages are displayed while the app is open.
    await _showNotification(message);
  }

  Future<void> _onTokenRefresh(String newToken) async {
    try {
      await _tokenRepo?.registerFcmToken(newToken);
    } catch (_) {
      // Best-effort.
    }
  }
}


// end of file
