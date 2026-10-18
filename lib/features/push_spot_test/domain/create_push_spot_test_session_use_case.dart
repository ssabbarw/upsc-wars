import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/deep_link/share_link_parser.dart';
import '../../../core/database/user_db.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../test_engine/domain/usecases/create_session_use_case.dart';
import '../push_spot_test_catalog_resolve.dart';
import '../push_spot_test_constants.dart';

/// Builds a 1-question learning session for push / spot-test entry.
class CreatePushSpotTestSessionUseCase {
  CreatePushSpotTestSessionUseCase({
    required this.createSession,
    required this.userDb,
    required this.prefsService,
  });

  final CreateSessionUseCase createSession;
  final UserDatabase userDb;
  final PrefsService prefsService;

  Future<String> execute({
    String subject = '',
    String topic = '',
    String? subTopic,
    String? questionUuid,
  }) async {
    final uuid = questionUuid?.trim();
    if (uuid != null && uuid.isNotEmpty) {
      if (!isUuid(uuid)) {
        throw StateError('Invalid question UUID: $uuid');
      }
      final rows = await userDb.questionsDao.getByUuidsInOrder([uuid]);
      if (rows.isEmpty) {
        throw StateError('Question not found on device: $uuid');
      }
      final q = rows.first;
      return createSession.execute(
        SessionConfig(
          subject: q.subject,
          topic: q.topic,
          subTopic: q.subTopic,
          mode: 'learning',
          questionCount: 1,
          isTimed: false,
          language: normalizeAppLanguage(prefsService.language),
          specificQuestionUuids: [q.uuid],
          analyticsFeatureKey: PushSpotTestConstants.analyticsKey,
        ),
      );
    }

    final subjRaw = subject.trim();
    final topRaw = topic.trim();
    if (subjRaw.isEmpty || topRaw.isEmpty) {
      throw StateError('Subject and topic are required without question_uuid');
    }

    final subj = resolvePushSpotTestSubject(subjRaw);
    final top = await resolvePushSpotTestTopic(
      questionsDao: userDb.questionsDao,
      subject: subj,
      topicRaw: topRaw,
    );
    if (top == null) {
      throw StateError(
        'No topic "$topRaw" under $subj. Use an exact catalog topic name '
        'or question_uuid.',
      );
    }

    final attempted = await userDb.sessionQuestionsDao
        .getAllAttemptedQuestionUuids();
    final subInput = subTopic?.trim();
    final sub = subInput == null || subInput.isEmpty
        ? null
        : await resolvePushSpotTestSubTopic(
            questionsDao: userDb.questionsDao,
            subject: subj,
            topic: top,
            subTopicRaw: subInput,
          );
    List<Question> picked;
    if (sub != null && sub.isNotEmpty) {
      picked = await userDb.questionsDao.getUnseenFirstByTopicSubTopic(
        subject: subj,
        topic: top,
        subTopic: sub,
        limit: PushSpotTestConstants.spotQuestionCount,
        attemptedQuestionUuids: attempted,
      );
      if (picked.isEmpty) {
        picked = await userDb.questionsDao.getUnseenFirstByTopic(
          subject: subj,
          topic: top,
          limit: PushSpotTestConstants.spotQuestionCount,
          attemptedQuestionUuids: attempted,
        );
      }
    } else {
      picked = await userDb.questionsDao.getUnseenFirstByTopic(
        subject: subj,
        topic: top,
        limit: PushSpotTestConstants.spotQuestionCount,
        attemptedQuestionUuids: attempted,
      );
    }
    if (picked.isEmpty) {
      throw StateError('No questions available for $subj / $top');
    }

    return createSession.execute(
      SessionConfig(
        subject: subj,
        topic: top,
        subTopic: sub,
        mode: 'learning',
        questionCount: picked.length,
        isTimed: false,
        language: normalizeAppLanguage(prefsService.language),
        specificQuestionUuids: picked.map((q) => q.uuid).toList(),
        analyticsFeatureKey: PushSpotTestConstants.analyticsKey,
      ),
    );
  }
}

final createPushSpotTestSessionUseCaseProvider =
    FutureProvider<CreatePushSpotTestSessionUseCase>((ref) async {
      final create = await ref.watch(createSessionUseCaseProvider.future);
      final userDb = ref.watch(userDatabaseProvider);
      final prefs = await ref.watch(prefsServiceProvider.future);
      return CreatePushSpotTestSessionUseCase(
        createSession: create,
        userDb: userDb,
        prefsService: prefs,
      );
    });
