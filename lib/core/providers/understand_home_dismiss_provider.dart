import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'prefs_provider.dart';

/// Dismiss keys for items inside the Home "Understand UPSC Wars" block.
abstract final class UnderstandHomeDismissKeys {
  static const push = 'push';
  static const demo = 'demo';

  static String video(int version) => 'video_v$version';
}

/// In-memory hides for this process. Cleared when the app process restarts.
class UnderstandHomeSessionHidden extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void hide(String key) {
    if (state.contains(key)) return;
    state = {...state, key};
  }
}

final understandHomeSessionHiddenProvider =
    NotifierProvider<UnderstandHomeSessionHidden, Set<String>>(
      UnderstandHomeSessionHidden.new,
    );

/// True when [key] should not render (permanent prefs or session soft-hide).
///
/// [prefs] may be null while SharedPreferences is still loading — session hide
/// still applies so a dismiss does not flash the item back.
bool isUnderstandHomeHidden(
  PrefsService? prefs,
  Set<String> session,
  String key,
) {
  if (session.contains(key)) return true;
  if (prefs != null && prefs.understandHomeDismissCount(key) >= 2) {
    return true;
  }
  return false;
}

typedef UnderstandHomeDismissSideEffect =
    FutureOr<void> Function(PrefsService prefs, int newCount);

/// Hides [key] in the UI immediately. Prefs + optional side effects run in the
/// background so dismiss never waits on disk I/O.
void dismissUnderstandHomeItem(
  WidgetRef ref,
  String key, {
  UnderstandHomeDismissSideEffect? afterPersist,
}) {
  ref.read(understandHomeSessionHiddenProvider.notifier).hide(key);
  unawaited(_persistDismiss(ref, key, afterPersist));
}

Future<void> _persistDismiss(
  WidgetRef ref,
  String key,
  UnderstandHomeDismissSideEffect? afterPersist,
) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  final current = prefs.understandHomeDismissCount(key);
  final next = current >= 2 ? 2 : current + 1;
  if (next != current) {
    prefs.setUnderstandHomeDismissCount(key, next);
  }
  if (afterPersist != null) {
    await afterPersist(prefs, next);
  }
}
