import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/prefs_provider.dart';

/// Writes dark mode to prefs, refreshes [prefsServiceProvider], and shows a
/// short blocking loader while the app rebuilds with the new theme.
Future<void> setDarkModeEnabledWithLoader({
  required BuildContext context,
  required WidgetRef ref,
  required bool darkModeEnabled,
}) async {
  if (!context.mounted) return;

  // Hold the root navigator before any async/invalidate work: the caller's
  // [BuildContext] can unmount after theme rebuild, which would skip [maybePop]
  // and leave this dialog stuck forever.
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: Center(
          child: Card(
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  await WidgetsBinding.instance.endOfFrame;

  try {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.darkModeEnabled = darkModeEnabled;
    ref.invalidate(prefsServiceProvider);
    await ref.read(prefsServiceProvider.future);
    await WidgetsBinding.instance.endOfFrame;
  } finally {
    if (navigator.mounted) {
      navigator.maybePop();
    }
  }
}
