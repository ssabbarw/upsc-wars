import 'package:shared_preferences/shared_preferences.dart';

import '../providers/prefs_provider.dart';

/// On web the bundled DB is loaded via WASM [initializeDatabase]; only prefs here.
Future<void> ensureQuestionBankReady(SharedPreferences prefs) async {
  await prefs.setBool(PrefKeys.dbInitialized, true);
}
