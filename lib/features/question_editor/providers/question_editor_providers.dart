import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/services/question_corrections_sync_service.dart';
import '../data/question_editor_repository.dart';

part 'question_editor_providers.g.dart';

@Riverpod(keepAlive: true)
Future<QuestionEditorRepository> questionEditorRepository(Ref ref) async {
  final db = ref.watch(userDatabaseProvider);
  final testEngine = await ref.watch(testEngineRepositoryProvider.future);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return QuestionEditorRepository(
    db: db,
    testEngine: testEngine,
    syncService: QuestionCorrectionsSyncService(userDb: db, prefs: prefs),
  );
}

@Riverpod(keepAlive: true)
Future<QuestionCorrectionsSyncService> questionCorrectionsSyncService(
  Ref ref,
) async {
  final db = ref.watch(userDatabaseProvider);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return QuestionCorrectionsSyncService(userDb: db, prefs: prefs);
}
