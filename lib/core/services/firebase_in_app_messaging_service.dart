import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';

/// Firebase In-App Messaging: create and target campaigns in the Firebase console
/// (Engage → In-App Messaging). Use [triggerEvent] for contextual trigger names
/// defined on those campaigns.
abstract final class FirebaseInAppMessagingService {
  static FirebaseInAppMessaging get _fiam => FirebaseInAppMessaging.instance;

  /// Call once after [Firebase.initializeApp]. Ensures in-app messages are not
  /// suppressed for this process (suppression is not persisted across restarts).
  static Future<void> initializeAfterFirebase() =>
      _fiam.setMessagesSuppressed(false);

  static Future<void> triggerEvent(String eventName) =>
      _fiam.triggerEvent(eventName);

  static Future<void> setMessagesSuppressed(bool suppress) =>
      _fiam.setMessagesSuppressed(suppress);

  static Future<void> setAutomaticDataCollectionEnabled(bool enabled) =>
      _fiam.setAutomaticDataCollectionEnabled(enabled);
}
