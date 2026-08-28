import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/notifications/notification_open_stack.dart';
import 'package:upsc_wars/features/fomo_pulse/fomo_pulse_constants.dart';

void main() {
  group('NotificationOpenStacks', () {
    test('CA Shot is Home → list → detail', () {
      final stack = NotificationOpenStacks.caShot(' pulse-1 ');
      expect(stack.base, '/');
      expect(stack.overlays, [
        FomoPulseConstants.hubLocation,
        FomoPulseConstants.detailLocation(
          'pulse-1',
          source: FomoPulseConstants.entryPush,
        ),
      ]);
    });

    test('Chat is Community → list → thread', () {
      final stack = NotificationOpenStacks.chat(
        chatId: 'c1',
        peerEmail: 'A@B.com',
        peerName: 'Ada',
      );
      expect(stack.base, '/community');
      expect(stack.overlays.first, '/chats');
      expect(stack.overlays.last, startsWith('/chat/c1?'));
      expect(stack.overlays.last, contains('peer=a'));
      expect(stack.overlays.last, contains('name=Ada'));
    });

    test('Open challenge is Community Open tab → detail', () {
      final stack = NotificationOpenStacks.openChallenge('ch-1');
      expect(stack.base, '/community?tab=open_challenge');
      expect(stack.overlays, ['/community/open-challenges/ch-1']);
    });

    test('Daily War hub sits on Home', () {
      expect(NotificationOpenStacks.dailyWarHub.base, '/');
      expect(NotificationOpenStacks.dailyWarHub.overlays, ['/daily-war']);
    });

    test('Battle join sits on Home', () {
      final stack = NotificationOpenStacks.battleJoin('sess-1');
      expect(stack.base, '/');
      expect(stack.overlays, ['/battle/join/sess-1']);
    });
  });
}
