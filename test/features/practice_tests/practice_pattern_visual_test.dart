import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/practice_tests/domain/practice_pattern_visual.dart';
import 'package:upsc_wars/features/subject_detail/domain/subject_mcq_pattern.dart';

SubjectMcqPatternStat _stat(UpscMcqPattern pattern, {String? otherSlug}) {
  return SubjectMcqPatternStat(
    pattern: pattern,
    otherSlug: otherSlug,
    wrong: 1,
    attempted: 2,
  );
}

void main() {
  test('canonical patterns get a distinct stem icon', () {
    expect(
      practicePatternVisual(_stat(UpscMcqPattern.howMany), isDark: false).icon,
      Icons.filter_3_rounded,
    );
    expect(
      practicePatternVisual(
        _stat(UpscMcqPattern.matchFollowing),
        isDark: false,
      ).icon,
      Icons.mediation_rounded,
    );
    expect(
      practicePatternVisual(
        _stat(UpscMcqPattern.assertionReason),
        isDark: false,
      ).icon,
      Icons.account_tree_rounded,
    );
  });

  test('other slugs get a contextual icon', () {
    expect(
      practicePatternVisual(
        _stat(UpscMcqPattern.other, otherSlug: 'fill-in-the-blank'),
        isDark: false,
      ).icon,
      Icons.text_fields_rounded,
    );
    expect(
      practicePatternVisual(
        _stat(UpscMcqPattern.other, otherSlug: 'chronology'),
        isDark: false,
      ).icon,
      Icons.timeline_rounded,
    );
    expect(
      practicePatternVisual(
        _stat(UpscMcqPattern.other, otherSlug: 'odd-one-out'),
        isDark: false,
      ).icon,
      Icons.difference_rounded,
    );
    expect(
      practicePatternVisual(
        _stat(UpscMcqPattern.other, otherSlug: 'identify-the-pair'),
        isDark: false,
      ).icon,
      Icons.looks_two_rounded,
    );
  });
}
