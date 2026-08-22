import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/features/weak_areas/widgets/trap_pattern_visual.dart';

void main() {
  test('maps each catalog trap to a distinct icon', () {
    const types = [
      'entity-swap',
      'scope-extension',
      'conflation',
      'temporal-swap',
      'partial-truth',
      'reversed-causation',
      'plausible-fabrication',
      'geographic-swap',
      'negation-trap',
      'negative-framing',
    ];

    final icons = types.map((t) => TrapPatternVisual.of(t).icon).toSet();
    expect(icons, hasLength(types.length));
  });

  test('falls back to a generic icon and primary accent', () {
    final visual = TrapPatternVisual.of('mystery-trap');
    expect(visual.icon, Icons.psychology_alt_rounded);
    expect(visual.accent, AppColors.primary);
  });
}
