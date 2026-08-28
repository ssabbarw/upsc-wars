import 'package:upsc_wars/features/chat/chat_fcm.dart';
import 'package:upsc_wars/features/fomo_pulse/fomo_pulse_constants.dart';

/// Where a notification tap should land, and what sits above [base] so back
/// walks overlays then [base].
class NotificationOpenStack {
  const NotificationOpenStack({required this.base, this.overlays = const []});

  /// First location (`go`). Shell tabs (`/`, `/community`, `/games`) belong here.
  final String base;

  /// Pushed on the next frame, in order. Back pops the last one first.
  final List<String> overlays;
}

/// Builds back stacks for notification taps. Keep in sync with
/// [BattleMessagingService] routing.
abstract final class NotificationOpenStacks {
  NotificationOpenStacks._();

  /// CA Shot leaf: Home → list → detail.
  static NotificationOpenStack caShot(String pulseId) {
    return NotificationOpenStack(
      base: '/',
      overlays: [
        FomoPulseConstants.hubLocation,
        FomoPulseConstants.detailLocation(
          pulseId,
          source: FomoPulseConstants.entryPush,
        ),
      ],
    );
  }

  /// Chat leaf: Community → chat list → thread.
  static NotificationOpenStack chat({
    required String chatId,
    required String peerEmail,
    String? peerName,
  }) {
    return NotificationOpenStack(
      base: '/community',
      overlays: [
        '/chats',
        ChatFcm.threadLocation(
          chatId: chatId,
          peerEmail: peerEmail,
          peerName: peerName,
        ),
      ],
    );
  }

  /// Open-challenge leaf: Community (Open tab) → detail.
  static NotificationOpenStack openChallenge(String challengeId) {
    return NotificationOpenStack(
      base: '/community?tab=open_challenge',
      overlays: ['/community/open-challenges/${challengeId.trim()}'],
    );
  }

  /// Daily Battle lobby / results hub: Home → `/daily-war`.
  static const dailyWarHub = NotificationOpenStack(
    base: '/',
    overlays: ['/daily-war'],
  );

  static NotificationOpenStack battleJoin(String sessionId) =>
      NotificationOpenStack(
        base: '/',
        overlays: ['/battle/join/${sessionId.trim()}'],
      );

  static const longHtml = NotificationOpenStack(
    base: '/',
    overlays: ['/notification/long-html'],
  );

  static NotificationOpenStack dailyCaReview(String date) =>
      NotificationOpenStack(
        base: '/',
        overlays: ['/internal/daily-ca-review/${date.trim()}'],
      );
}
