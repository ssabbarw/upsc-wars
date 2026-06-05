import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/features/test_engine/domain/usecases/create_session_use_case.dart';

import '../../../core/constants/timed_exam_debug_constants.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';

/// Creates the 7-question Get Started diagnostic spread across 2–3 topics.
class CreateGetStartedSessionUseCase {
  const CreateGetStartedSessionUseCase({
    required this.createSession,
    required this.userDb,
  });

  final CreateSessionUseCase createSession;
  final UserDatabase userDb;

  static const analyticsKey = 'get_started_diagnostic';
  static const defaultSubject = 'Polity';
  static const questionCount = 7;

  Future<String> execute({required String subject}) async {
    final attempted = await userDb.sessionQuestionsDao
        .getAllAttemptedQuestionUuids();
    final picked = await userDb.questionsDao.getUnseenFirstBySubjectSpreadTopics(
      subject: subject,
      questionCount: questionCount,
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
        language: 'en',
        specificQuestionUuids: picked.map((q) => q.uuid).toList(),
        analyticsFeatureKey: analyticsKey,
      ),
    );
  }
}

final createGetStartedSessionUseCaseProvider =
    FutureProvider<CreateGetStartedSessionUseCase>((ref) async {
      final create = await ref.watch(createSessionUseCaseProvider.future);
      final db = ref.watch(userDatabaseProvider);
      return CreateGetStartedSessionUseCase(
        createSession: create,
        userDb: db,
      );
    });
