import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/subject_detail/domain/subject_mcq_pattern.dart';

void main() {
  test('merges hyphen and underscore slugs of the same pattern', () {
    final picked = pickWeakestMcqPattern(const [
      (type: 'multi_statement_count', wrong: 2, attempted: 4),
      (type: 'how-many', wrong: 2, attempted: 2),
      (type: 'direct', wrong: 1, attempted: 10),
    ]);

    expect(picked?.pattern, UpscMcqPattern.howMany);
    expect(picked?.wrong, 4);
    expect(picked?.attempted, 6);
  });

  test('picks the higher wrong rate once a pattern has enough attempts', () {
    final picked = pickWeakestMcqPattern(const [
      (type: 'assertion_reason', wrong: 4, attempted: 5),
      (type: 'multi_statement_count', wrong: 8, attempted: 20),
    ]);

    expect(picked?.pattern, UpscMcqPattern.assertionReason);
    expect(picked?.wrongPercent, 80);
  });

  test('ignores a tiny sample when another pattern is qualified', () {
    final picked = pickWeakestMcqPattern(const [
      (type: 'match-the-column', wrong: 1, attempted: 1),
      (type: 'multi-statement-correct', wrong: 3, attempted: 6),
    ]);

    expect(picked?.pattern, UpscMcqPattern.statementCombination);
  });

  test('falls back to the most wrongs when every sample is thin', () {
    final picked = pickWeakestMcqPattern(const [
      (type: 'assertion-reason', wrong: 1, attempted: 1),
      (type: 'direct', wrong: 2, attempted: 2),
    ]);

    expect(picked?.pattern, UpscMcqPattern.direct);
    expect(picked?.wrong, 2);
  });

  test('returns null when nothing was answered wrong', () {
    expect(
      pickWeakestMcqPattern(const [(type: 'direct', wrong: 0, attempted: 8)]),
      isNull,
    );
  });

  test('breaks rate ties toward more wrong answers', () {
    final picked = pickWeakestMcqPattern(const [
      (type: 'assertion-reason', wrong: 3, attempted: 6),
      (type: 'how-many', wrong: 6, attempted: 12),
    ]);

    expect(picked?.pattern, UpscMcqPattern.howMany);
  });

  test('ranks every pattern that has a wrong', () {
    final ranked = rankMcqPatterns(const [
      (type: 'direct', wrong: 1, attempted: 10),
      (type: 'assertion-reason', wrong: 4, attempted: 5),
      (type: 'direct', wrong: 0, attempted: 2),
    ]);
    expect(ranked.map((s) => s.pattern), [
      UpscMcqPattern.assertionReason,
      UpscMcqPattern.direct,
    ]);
  });
}
