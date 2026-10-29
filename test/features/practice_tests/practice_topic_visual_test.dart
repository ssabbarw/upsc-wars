import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/practice_tests/domain/practice_topic_visual.dart';

void main() {
  test('maps known economy topics to distinct icons', () {
    expect(
      practiceTopicVisual(
        'Capital Markets and Financial System',
        isDark: false,
      ).icon,
      Icons.show_chart_rounded,
    );
    expect(
      practiceTopicVisual(
        'Climate and Sustainability Finance',
        isDark: false,
      ).icon,
      Icons.eco_rounded,
    );
    expect(
      practiceTopicVisual('Money and Banking', isDark: false).icon,
      Icons.account_balance_rounded,
    );
    expect(
      practiceTopicVisual('Agriculture', isDark: false).icon,
      Icons.agriculture_rounded,
    );
    expect(
      practiceTopicVisual('External Sector', isDark: false).icon,
      Icons.public_rounded,
    );
  });

  test('unknown topics get a stable generic icon', () {
    final first = practiceTopicVisual('Some Unique Topic X', isDark: false);
    final again = practiceTopicVisual('Some Unique Topic X', isDark: false);
    expect(first.icon, again.icon);
    expect(first.accent, again.accent);
  });
}
