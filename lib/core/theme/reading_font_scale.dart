import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/prefs_provider.dart';

/// Saved size for question statements and explanation copy.
///
/// App chrome — buttons, navigation, settings labels — stays on the theme size.
abstract final class ReadingFontScale {
  static const steps = <double>[0.9, 1.0, 1.15, 1.35, 1.55];
  static const labels = <String>[
    'Small',
    'Default',
    'Medium',
    'Large',
    'Extra large',
  ];

  static int indexFor(double scale) {
    var best = 1;
    var bestDist = double.infinity;
    for (var i = 0; i < steps.length; i++) {
      final d = (steps[i] - scale).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  static double snap(double scale) => steps[indexFor(scale)];

  static TextStyle apply(TextStyle style, double scale) {
    final size = style.fontSize;
    if (size == null || (scale - 1).abs() < 0.001) return style;
    return style.copyWith(fontSize: size * scale);
  }
}

class ReadingFontScaleNotifier extends Notifier<double> {
  @override
  double build() {
    final stored = ref.watch(
      prefsServiceProvider.select((async) => async.value?.readingFontScale),
    );
    return ReadingFontScale.snap(stored ?? 1);
  }

  void setIndex(int index) {
    final next = ReadingFontScale
        .steps[index.clamp(0, ReadingFontScale.steps.length - 1)];
    if ((state - next).abs() < 0.001) return;
    state = next;
    final prefs = ref.read(prefsServiceProvider).value;
    if (prefs != null) {
      prefs.readingFontScale = next;
      return;
    }
    unawaited(_persist(next));
  }

  Future<void> _persist(double next) async {
    final prefs = await ref.read(prefsServiceProvider.future);
    if ((state - next).abs() > 0.001) return;
    prefs.readingFontScale = next;
  }
}

final readingFontScaleProvider =
    NotifierProvider<ReadingFontScaleNotifier, double>(
      ReadingFontScaleNotifier.new,
    );

class ReadingFontScaleHost extends ConsumerWidget {
  const ReadingFontScaleHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(readingFontScaleProvider);
    return _ReadingFontScaleData(scale: scale, child: child);
  }
}

class _ReadingFontScaleData extends InheritedWidget {
  const _ReadingFontScaleData({required this.scale, required super.child});

  final double scale;

  @override
  bool updateShouldNotify(_ReadingFontScaleData oldWidget) =>
      oldWidget.scale != scale;
}

extension ReadingFontBuildContext on BuildContext {
  double get readingFontScale =>
      dependOnInheritedWidgetOfExactType<_ReadingFontScaleData>()?.scale ?? 1;

  /// Scales [style] for a question statement or explanation. No-op at 1.0.
  TextStyle readingFont(TextStyle style) =>
      ReadingFontScale.apply(style, readingFontScale);
}
