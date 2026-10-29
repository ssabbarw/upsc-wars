import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme/app_colors.dart';

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

const appLanguageSwitchMinimum = Duration(seconds: 2);

/// Shows the language-switch loader, then persists [lang].
///
/// The loader stays up for at least [appLanguageSwitchMinimum], or longer when
/// applying the language takes more time. Call this after the toggle has
/// already flipped its selected segment.
Future<void> switchAppLanguage(
  BuildContext context,
  WidgetRef ref,
  String lang,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final normalized = normalizeAppLanguage(lang);
  final prefs = await ref.read(prefsServiceProvider.future);
  if (!context.mounted) return;
  if (normalizeAppLanguage(prefs.language) == normalized) {
    prefs.languageChosen = true;
    return;
  }

  final started = Stopwatch()..start();
  // Paint the new EN / हि selection before covering the screen.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  final route = PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    barrierColor: const Color(0x8C111111),
    barrierLabel: 'Switching language',
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) {
      return const PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.white,
            elevation: 6,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  unawaited(navigator.push(route));
  try {
    await WidgetsBinding.instance.endOfFrame;
    await persistAppLanguage(ref, lang, showLoader: false);
  } finally {
    final remaining = appLanguageSwitchMinimum - started.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (route.isActive) navigator.removeRoute(route);
  }
}

/// Persists the user's EN / Hindi choice for future tests and reviews.
///
/// Prefer [switchAppLanguage] from a language control so the loader is visible.
/// [showLoader] keeps the app-level overlay up for at least two seconds.
Future<void> persistAppLanguage(
  WidgetRef ref,
  String lang, {
  bool showLoader = true,
}) async {
  final normalized = normalizeAppLanguage(lang);
  final prefs = await ref.read(prefsServiceProvider.future);
  final previous = normalizeAppLanguage(prefs.language);
  prefs.languageChosen = true;
  if (previous == normalized) return;

  final busy = ref.read(languageSwitchBusyProvider.notifier);
  final started = Stopwatch()..start();
  if (showLoader) {
    busy.setBusy(true);
    // Paint the overlay before the locale rebuild.
    await WidgetsBinding.instance.endOfFrame;
  }
  try {
    prefs.language = normalized;
    ref.invalidate(appLanguageProvider);
    await ref.read(appLanguageProvider.future);
    try {
      await Analytics.track(
        ref,
        AppLanguageSwitchedEvent(
          fromLanguage: previous,
          toLanguage: normalized,
        ),
      );
    } catch (_) {
      // A failed analytics call must not roll back the language switch.
    }
  } finally {
    if (showLoader) {
      const minimum = Duration(seconds: 2);
      final remaining = minimum - started.elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
      busy.setBusy(false);
    }
  }
}
