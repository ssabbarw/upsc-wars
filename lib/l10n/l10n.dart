import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.someString` — app UI strings in English or Hindi.
///
/// Brand / feature names (CA Shots, Traps, Prelims, Test Series, Danger Zone,
/// Daily War, Battle, Pulse, Streak, Leaderboard, Daily CA, Games ...) and the
/// home greeting are kept in English in both locales on purpose. Do not
/// translate them.
extension AppL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Current UI locale for code that has no [BuildContext] (domain classes,
/// services). Kept in sync with the app language by the root `MaterialApp`.
///
/// Prefer `context.l10n` inside widgets: it also rebuilds the widget when the
/// language changes. This is only evaluated at call time.
abstract final class AppL10n {
  static Locale locale = const Locale('en');

  static AppLocalizations get current => lookupAppLocalizations(locale);
}

AppLocalizations get appL10n => AppL10n.current;
