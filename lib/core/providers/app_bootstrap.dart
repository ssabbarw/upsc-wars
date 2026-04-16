import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/question_bank_setup.dart';
import 'prefs_provider.dart';

part 'app_bootstrap.g.dart';

/// Ensures SharedPreferences is ready and the question bank file is copied on first launch.
@Riverpod(keepAlive: true)
Future<void> appBootstrap(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  await QuestionBankSetup.ensureReady(prefs);
}
