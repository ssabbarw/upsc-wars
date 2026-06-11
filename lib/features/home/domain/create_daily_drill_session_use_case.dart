import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/constants/timed_exam_debug_constants.dart';
import '../../../core/database/user_db.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../test_engine/domain/usecases/create_session_use_case.dart';

/// Creates a timed 10-question daily practice drill for [subject].
class CreateDailyDrillSessionUseCase {
  const CreateDailyDrillSessionUseCase({
    required this.createSession,
    required this.userDb,
    required this.prefsService,
  });

  final CreateSessionUseCase createSession;
  final UserDatabase userDb;
  final PrefsService prefsService;

  Future<String> execute({
    required String subject,
    String analyticsFeatureKey = DailyDrillConstants.analyticsKey,
  }) async {
    final attempted =
        await userDb.sessionQuestionsDao.getAllAttemptedQuestionUuids();
    final picked = subject == DailyDrillConstants.defaultSubject
        ? await userDb.questionsDao.getUnseenFirstRandomMixed(
            limit: DailyDrillConstants.questionCount,
            attemptedQuestionUuids: attempted,
          )
        : await userDb.questionsDao.getUnseenFirstBySubjectSpreadTopics(
            subject: subject,
            questionCount: DailyDrillConstants.questionCount,
            maxTopics: 3,
            attemptedQuestionUuids: attempted,
          );
    if (picked.isEmpty) {
      throw StateError('No questions available for $subject');
    }

    return createSession.execute(
      SessionConfig(
        subject: subject,
        mode: 'exam',
        questionCount: picked.length,
        isTimed: true,
        timeLimitSecs: picked.length * kDebugSecondsPerQuestion,
        language: normalizeAppLanguage(prefsService.language),
        specificQuestionUuids: picked.map((q) => q.uuid).toList(),
        analyticsFeatureKey: analyticsFeatureKey,
      ),
    );
  }
}

final createDailyDrillSessionUseCaseProvider =
    FutureProvider<CreateDailyDrillSessionUseCase>((ref) async {
      final create = await ref.watch(createSessionUseCaseProvider.future);
      final db = ref.watch(userDatabaseProvider);
      final prefs = await ref.watch(prefsServiceProvider.future);
      return CreateDailyDrillSessionUseCase(
        createSession: create,
        userDb: db,
        prefsService: prefs,
      );
    });
