import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/community/domain/community_bot.dart';

void main() {
  group('isTrafficBotEmail', () {
    test('matches reserved bot domain', () {
      expect(isTrafficBotEmail('priya.k11@upscwars.bot'), isTrue);
      expect(isTrafficBotEmail('Priya.K11@UPSCWARS.BOT'), isTrue);
    });

    test('rejects real users', () {
      expect(isTrafficBotEmail('priya@gmail.com'), isFalse);
      expect(isTrafficBotEmail(''), isFalse);
      expect(isTrafficBotEmail(null), isFalse);
    });
  });

  group('isTrafficBotUid', () {
    test('matches roster ids', () {
      expect(isTrafficBotUid('bot_priya_k11'), isTrue);
      expect(isTrafficBotUid('abc123'), isFalse);
      expect(isTrafficBotUid(null), isFalse);
    });
  });
}
