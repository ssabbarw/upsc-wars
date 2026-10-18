import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/database/user_db.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../daily_war/domain/daily_war_copy.dart';
import '../../daily_war/domain/daily_war_models.dart';
import '../../test_engine/domain/usecases/create_session_use_case.dart';

/// Creates a 10-question drill — tonight's War topics when given, else [subject].
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
    List<DailyWarTopicRef> warTopics = const [],
    String analyticsFeatureKey = DailyDrillConstants.analyticsKey,
  }) async {
    final attempted = await userDb.sessionQuestionsDao
        .getAllAttemptedQuestionUuids();
    var picked = warTopics.isNotEmpty
        ? await _pickWarTopics(warTopics, attempted)
        : const <Question>[];
    if (picked.isEmpty) {
      picked = subject == DailyDrillConstants.defaultSubject
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
    }
    if (picked.isEmpty) {
      throw StateError('No questions available for $subject');
    }

    final sessionSubject = warTopics.isNotEmpty
        ? DailyWarCopy.sessionSubjectSlug(warTopics.first.subjectSlug)
        : subject;

    return createSession.execute(
      SessionConfig(
        subject: sessionSubject,
        mode: 'learning',
        questionCount: picked.length,
        isTimed: false,
        timeLimitSecs: null,
        language: normalizeAppLanguage(prefsService.language),
        specificQuestionUuids: picked.map((q) => q.uuid).toList(),
        analyticsFeatureKey: analyticsFeatureKey,
      ),
    );
  }

  Future<List<Question>> _pickWarTopics(
    List<DailyWarTopicRef> topics,
    Set<String> attempted,
  ) async {
    final per = (DailyDrillConstants.questionCount / topics.length).ceil();
    final picked = <Question>[];
    final seen = <String>{};
    for (final t in topics) {
      final batch = await userDb.questionsDao.getUnseenFirstByTopic(
        subject: DailyWarCopy.sessionSubjectSlug(t.subjectSlug),
        topic: t.topic,
        limit: per,
        attemptedQuestionUuids: attempted,
      );
      for (final q in batch) {
        if (seen.add(q.uuid)) picked.add(q);
        if (picked.length >= DailyDrillConstants.questionCount) {
          return picked.take(DailyDrillConstants.questionCount).toList();
        }
      }
    }
    return picked;
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
