import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../analytics/analytics.dart';
import '../analytics/analytics_events.dart';
import 'catalog_providers.dart';
import 'prefs_provider.dart';

/// Normalizes persisted question/UI language to `en` or `hi`.
String normalizeAppLanguage(String? lang) {
  if (lang == 'hi') return 'hi';
  return 'en';
}

/// Watches the saved language; uses [fallback] while prefs are loading.
String watchAppLanguage(WidgetRef ref, {String fallback = 'en'}) {
  return ref.watch(prefsServiceProvider).maybeWhen(
    data: (prefs) => normalizeAppLanguage(prefs.language),
    orElse: () => fallback,
  );
}

/// Persists the user's EN / Hindi choice for future tests and reviews.
Future<void> persistAppLanguage(WidgetRef ref, String lang) async {
  final normalized = normalizeAppLanguage(lang);
  final prefs = await ref.read(prefsServiceProvider.future);
  final previous = normalizeAppLanguage(prefs.language);
  if (previous == normalized) return;
  prefs.language = normalized;
  ref.invalidate(appLanguageProvider);
  await Analytics.track(
    ref,
    AppLanguageSwitchedEvent(
      fromLanguage: previous,
      toLanguage: normalized,
    ),
  );
}
