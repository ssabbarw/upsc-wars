import 'package:shared_preferences/shared_preferences.dart';

import 'question_bank_setup_impl_io.dart'
    if (dart.library.html) 'question_bank_setup_impl_web.dart'
    as impl;

/// Copies the asset question bank into documents once (native), or marks ready (web).
class QuestionBankSetup {
  QuestionBankSetup._();

  /// Ensures the SQLite file exists under app documents and [PrefKeys.dbInitialized] is set.
  static Future<void> ensureReady(SharedPreferences prefs) =>
      impl.ensureQuestionBankReady(prefs);
}
