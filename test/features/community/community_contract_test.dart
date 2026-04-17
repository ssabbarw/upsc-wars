import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/community/domain/community_bucket_utils.dart';
import 'package:upsc_wars/features/community/domain/community_legacy_contract.dart';

void main() {
  group('communityUserFromLegacyMap', () {
    test('maps legacy fields with defaults', () {
      final user = communityUserFromLegacyMap('foo@example.com', {
        CommunityLegacyContract.name: 'Foo',
        CommunityLegacyContract.photoUrl: 'https://example.com/a.png',
        CommunityLegacyContract.lastOnlineTime: 1000,
      });

      expect(user.email, 'foo@example.com');
      expect(user.name, 'Foo');
      expect(user.photoUrl, 'https://example.com/a.png');
      expect(user.acceptingBattleInvites, isTrue);
      expect(user.lastOnlineTime, 1000);
    });

    test('falls back to doc id when email missing', () {
      final user = communityUserFromLegacyMap('bar@example.com', {});
      expect(user.email, 'bar@example.com');
      expect(user.name, 'UPSC Warrior');
      expect(user.lastOnlineTime, 0);
    });
  });

  group('CommunityBucketUtils', () {
    test('returns expected bucket for hour ranges', () {
      expect(_bucketAtHour(1), '0');
      expect(_bucketAtHour(4), '3');
      expect(_bucketAtHour(8), '6');
      expect(_bucketAtHour(11), '9');
      expect(_bucketAtHour(14), '12');
      expect(_bucketAtHour(17), '15');
      expect(_bucketAtHour(20), '18');
      expect(_bucketAtHour(23), '21');
    });
  });
}

String _bucketAtHour(int hour) {
  final ts = DateTime(2026, 4, 17, hour).millisecondsSinceEpoch;
  return CommunityBucketUtils.bucketForTimestamp(ts);
}
