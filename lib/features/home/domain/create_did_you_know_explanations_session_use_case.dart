import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/features/test_engine/domain/usecases/create_session_use_case.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';

/// Creates a short learning-mode showcase for Did You Know card 2.
class CreateDidYouKnowExplanationsSessionUseCase {
  const CreateDidYouKnowExplanationsSessionUseCase({
    required this.createSession,
    required this.userDb,
  });

  final CreateSessionUseCase createSession;
  final UserDatabase userDb;

  static const analyticsKey = 'did_you_know_explanations';
  static const defaultSubject = 'Polity';
  static const questionCount = 3;

  Future<String> execute() async {
    final attempted = await userDb.sessionQuestionsDao
        .getAllAttemptedQuestionUuids();
    final picked = await userDb.questionsDao.getUnseenFirstBySubjectSpreadTopics(
      subject: defaultSubject,
      questionCount: questionCount,
      maxTopics: 2,
      attemptedQuestionUuids: attempted,
    );
    if (picked.isEmpty) {
      throw StateError('No questions available for $defaultSubject');
    }

    return createSession.execute(
      SessionConfig(
        subject: defaultSubject,
        mode: 'learning',
        questionCount: picked.length,
        isTimed: false,
        timeLimitSecs: null,
        language: 'en',
        specificQuestionUuids: picked.map((q) => q.uuid).toList(),
        analyticsFeatureKey: analyticsKey,
      ),
    );
  }
}

final createDidYouKnowExplanationsSessionUseCaseProvider =
    FutureProvider<CreateDidYouKnowExplanationsSessionUseCase>((ref) async {
      final create = await ref.watch(createSessionUseCaseProvider.future);
      final db = ref.watch(userDatabaseProvider);
      return CreateDidYouKnowExplanationsSessionUseCase(
        createSession: create,
        userDb: db,
      );
    });
