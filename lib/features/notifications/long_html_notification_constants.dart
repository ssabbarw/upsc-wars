/// Firestore + FCM keys for the long HTML announcement flow.
///
/// Send from Firebase Console with **custom data**:
/// [fcmDataKeyType] = [fcmDataValueLongHtmlMessage] (e.g. `type` = `long_html_message`).
/// Tapping the notification opens [LongHtmlNotificationScreen], which loads HTML
/// from Firestore document [documentId] in [collection].
class LongHtmlNotificationConstants {
  LongHtmlNotificationConstants._();

  static const String collection = 'Long_Html_Message';
  static const String documentId = 'message';
  static const String fieldMessage = 'message';

  static const String fcmDataKeyType = 'type';
  static const String fcmDataValueLongHtmlMessage = 'long_html_message';
}
