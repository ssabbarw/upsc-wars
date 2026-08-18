import 'fomo_pulse_constants.dart';

/// FCM data contract for Pulse notifications.
///
/// Keep this tiny. FCM data payloads cap at 4KB — a UPSC MCQ plus explanation
/// often exceeds that, and stuffing the correct answer in the push would leak it.
abstract final class FomoPulseFcm {
  static const kind = FomoPulseConstants.fcmKind;

  static const dataKeyKind = 'kind';
  static const dataKeyPulseId = 'pulse_id';
  static const dataKeyNotificationId = 'notification_id';

  static String? pulseIdFromData(Map<String, dynamic> data) {
    final raw = data[dataKeyPulseId];
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }
}
