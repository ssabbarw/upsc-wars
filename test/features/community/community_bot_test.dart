import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/community/domain/community_bot.dart';

void main() {
  group('TrafficBotIndex', () {
    test('matches listed emails case-insensitively', () {
      const index = TrafficBotIndex(emails: {'priya.sharma24@gmail.com'});
      expect(index.matches(email: 'Priya.Sharma24@Gmail.com'), isTrue);
      expect(index.matches(email: 'priya@gmail.com'), isFalse);
      expect(index.matches(email: ''), isFalse);
      expect(index.matches(), isFalse);
    });

    test('matches listed uids', () {
      const index = TrafficBotIndex(uids: {'abc123xyz'});
      expect(index.matches(uid: 'abc123xyz'), isTrue);
      expect(index.matches(uid: 'other'), isFalse);
      expect(index.matches(uid: ''), isFalse);
    });

    test('parses Firestore payload and ignores empty values', () {
      final index = TrafficBotIndex.fromMap({
        'emails': ['Aarav.Kumar11@Gmail.com', '', null],
        'uids': ['UidOne', '  '],
        'warPeopleLast24h': 4,
        'battleCompletedPeopleLast24h': 2,
      });
      expect(index.matches(email: 'aarav.kumar11@gmail.com'), isTrue);
      expect(index.matches(uid: 'UidOne'), isTrue);
      expect(index.matches(uid: 'uidone'), isFalse);
      expect(index.warPeopleLast24h, 4);
      expect(index.battleCompletedPeopleLast24h, 2);
    });

    test('empty map is a no-op', () {
      expect(TrafficBotIndex.fromMap(null).matches(email: 'a@b.com'), isFalse);
      expect(TrafficBotIndex.empty.matches(uid: 'x'), isFalse);
      expect(TrafficBotIndex.fromMap(null).warPeopleLast24h, 0);
      expect(TrafficBotIndex.fromMap(null).battleCompletedPeopleLast24h, 0);
    });

    test('parses warPeopleLast24h from num', () {
      expect(
        TrafficBotIndex.fromMap({'warPeopleLast24h': 2.0}).warPeopleLast24h,
        2,
      );
      expect(
        TrafficBotIndex.fromMap({'warPeopleLast24h': 'nope'}).warPeopleLast24h,
        0,
      );
      expect(
        TrafficBotIndex.fromMap({
          'battleCompletedPeopleLast24h': 3.0,
        }).battleCompletedPeopleLast24h,
        3,
      );
    });
  });
}
