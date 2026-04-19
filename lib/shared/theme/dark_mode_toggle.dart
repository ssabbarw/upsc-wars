import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/prefs_provider.dart';

/// Writes dark mode to prefs and refreshes [prefsServiceProvider].
Future<void> setDarkModeEnabled({
  required WidgetRef ref,
  required bool darkModeEnabled,
}) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.darkModeEnabled = darkModeEnabled;
  ref.invalidate(prefsServiceProvider);
  await ref.read(prefsServiceProvider.future);
}
