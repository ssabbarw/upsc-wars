import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_wars/features/daily_ca/data/daily_ca_leaderboard_cache.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_rank_models.dart';

void main() {
  test('frozen board round-trips on disk; live board is not stored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = DailyCaLeaderboardCache(prefs);

    const live = DailyCaLeaderboard(
      dateId: '2026-08-27',
      top: [
        DailyCaLeaderboardEntry(
          uid: 'a',
          displayName: 'A',
          score: 18,
          elapsedMs: 1000,
          air: 1,
        ),
      ],
      participantCount: 1,
      questionCount: 10,
      status: 'live',
    );
    await cache.putFrozen(live);
    expect(cache.get('2026-08-27'), isNull);

    const frozen = DailyCaLeaderboard(
      dateId: '2026-08-26',
      top: [
        DailyCaLeaderboardEntry(
          uid: 'a',
          displayName: 'A',
          score: 18,
          elapsedMs: 1000,
          air: 1,
        ),
      ],
      participantCount: 12,
      questionCount: 10,
      status: 'frozen',
    );
    await cache.putFrozen(frozen);
    final got = cache.get('2026-08-26');
    expect(got, isNotNull);
    expect(got!.isFrozen, isTrue);
    expect(got.top.single.displayName, 'A');
    expect(got.participantCount, 12);
  });
}
