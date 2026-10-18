import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/community/domain/open_challenge_models.dart';
import 'package:upsc_wars/features/community/providers/open_challenge_providers.dart';

OpenChallengeListTileModel _tile({
  required String id,
  required int attemptCount,
  int? myScore,
  DateTime? postedAt,
}) {
  return OpenChallengeListTileModel(
    id: id,
    subject: 'polity',
    attemptCount: attemptCount,
    topScore: 8,
    myScore: myScore,
    postedByName: 'Warrior',
    postedByPhotoUrl: '',
    postedAt: postedAt,
    liveUntil: null,
  );
}

void main() {
  group('rankHomeOpenChallenges', () {
    test('a contested challenge outranks a fresher empty one', () {
      final ranked = rankHomeOpenChallenges([
        _tile(
          id: 'fresh',
          attemptCount: 1,
          postedAt: DateTime(2026, 8, 17, 20),
        ),
        _tile(id: 'busy', attemptCount: 9, postedAt: DateTime(2026, 8, 17, 6)),
      ]);
      expect(ranked.map((c) => c.id), ['busy', 'fresh']);
    });

    test('equally contested challenges fall back to newest', () {
      final ranked = rankHomeOpenChallenges([
        _tile(id: 'older', attemptCount: 4, postedAt: DateTime(2026, 8, 16)),
        _tile(id: 'newer', attemptCount: 4, postedAt: DateTime(2026, 8, 17)),
      ]);
      expect(ranked.map((c) => c.id), ['newer', 'older']);
    });

    test('challenges the user already played are dropped', () {
      final ranked = rankHomeOpenChallenges([
        _tile(id: 'played', attemptCount: 20, myScore: 7),
        _tile(id: 'open', attemptCount: 2),
      ]);
      expect(ranked.map((c) => c.id), ['open']);
    });

    test('challenges played on this device are dropped', () {
      final ranked = rankHomeOpenChallenges(
        [
          _tile(id: 'played-as-guest', attemptCount: 20),
          _tile(id: 'open', attemptCount: 2),
        ],
        attempted: {'played-as-guest'},
      );
      expect(ranked.map((c) => c.id), ['open']);
    });

    test('nothing left to play yields an empty slot', () {
      final ranked = rankHomeOpenChallenges([
        _tile(id: 'a', attemptCount: 3, myScore: 5),
        _tile(id: 'b', attemptCount: 3, myScore: 9),
      ]);
      expect(ranked, isEmpty);
    });

    test('a missing timestamp sorts last rather than throwing', () {
      final ranked = rankHomeOpenChallenges([
        _tile(id: 'undated', attemptCount: 2),
        _tile(id: 'dated', attemptCount: 2, postedAt: DateTime(2026, 8, 17)),
      ]);
      expect(ranked.map((c) => c.id), ['dated', 'undated']);
    });
  });
}
