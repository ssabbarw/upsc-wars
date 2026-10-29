import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../analytics/analytics.dart';
import '../analytics/analytics_events.dart';
import 'catalog_providers.dart';
import 'prefs_provider.dart';

/// True while [persistAppLanguage] is applying a new EN / हि choice.
class LanguageSwitchBusy extends Notifier<bool> {
  @override
  bool build() => false;

  void setBusy(bool value) => state = value;
}

final languageSwitchBusyProvider =
    NotifierProvider<LanguageSwitchBusy, bool>(LanguageSwitchBusy.new);

/// Normalizes persisted question/UI language to `en` or `hi`.
String normalizeAppLanguage(String? lang) {
  if (lang == 'hi') return 'hi';
  return 'en';
}

/// Watches the saved language; uses [fallback] while prefs are loading.
String watchAppLanguage(WidgetRef ref, {String fallback = 'en'}) {
  return ref
      .watch(prefsServiceProvider)
      .maybeWhen(
        data: (prefs) => normalizeAppLanguage(prefs.language),
        orElse: () => fallback,
      );
}

/// Persists the user's EN / Hindi choice for future tests and reviews.
Future<void> persistAppLanguage(WidgetRef ref, String lang) async {
  final normalized = normalizeAppLanguage(lang);
  final prefs = await ref.read(prefsServiceProvider.future);
  final previous = normalizeAppLanguage(prefs.language);
  prefs.languageChosen = true;
  if (previous == normalized) return;

  final busy = ref.read(languageSwitchBusyProvider.notifier);
  busy.setBusy(true);
  final started = Stopwatch()..start();
  try {
    prefs.language = normalized;
    ref.invalidate(appLanguageProvider);
    await ref.read(appLanguageProvider.future);
    await Analytics.track(
      ref,
      AppLanguageSwitchedEvent(fromLanguage: previous, toLanguage: normalized),
    );
    // Hold the overlay for at least a second so a fast switch still reads as
    // a deliberate change. Longer switches keep it up until they finish.
    const minimum = Duration(seconds: 1);
    final remaining = minimum - started.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  } finally {
    busy.setBusy(false);
  }
}
