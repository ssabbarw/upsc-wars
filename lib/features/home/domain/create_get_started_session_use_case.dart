import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/providers/app_language_helpers.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/features/test_engine/domain/usecases/create_session_use_case.dart';

import '../../daily_ca/data/daily_ca_repository.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';

/// Creates the first-run demo: mixed current-affairs + static, learning mode.
class CreateGetStartedSessionUseCase {
  const CreateGetStartedSessionUseCase({
    required this.createSession,
    required this.userDb,
    required this.prefsService,
    required this.dailyCaRepository,
  });

  final CreateSessionUseCase createSession;
  final UserDatabase userDb;
  final PrefsService prefsService;
  final DailyCaRepository dailyCaRepository;

  static const analyticsKey = 'get_started_diagnostic';
  static const defaultSubject = 'Polity';

  /// Mixed-subject diagnostic (same bank as battles / open-challenge misc).
  static const mixedSubject = 'misc';
  static const questionCount = 8;
  static const currentAffairsCount = 4;

  Future<void> prefetchCurrentAffairs() async {
    for (final day in DailyCaSchedule.recentTestContentDates()) {
      try {
        await dailyCaRepository.ensureCachedForDate(
          DailyCaSchedule.formatIsoDate(day),
        );
      } on Object {
        // Keep going — static bank fills any shortfall.
      }
    }
  }

  Future<String> executeMixed() async {
    final existing = await userDb.sessionsDao
        .getInProgressSessionIdByFeatureKey(analyticsKey);
    if (existing != null) return existing;

    await prefetchCurrentAffairs();

    final attempted = await userDb.sessionQuestionsDao
        .getAllAttemptedQuestionUuids();
    final ca = await userDb.questionsDao.getRecentCurrentAffairs(
      limit: currentAffairsCount,
      excludeUuids: attempted,
    );
    final staticNeeded = questionCount - ca.length;
    final staticQs = staticNeeded <= 0
        ? const <Question>[]
        : await userDb.questionsDao.getUnseenFirstRandomMixed(
            limit: staticNeeded,
            attemptedQuestionUuids: {
              ...attempted,
              for (final q in ca) q.uuid,
            },
          );
    final picked = [...ca, ...staticQs];
    if (picked.isEmpty) {
      throw StateError('No questions available for diagnostic');
    }

    return createSession.execute(
      SessionConfig(
        subject: mixedSubject,
        mode: 'learning',
        questionCount: picked.length,
        isTimed: false,
        timeLimitSecs: null,
        language: normalizeAppLanguage(prefsService.language),
        specificQuestionUuids: picked.map((q) => q.uuid).toList(),
        analyticsFeatureKey: analyticsKey,
      ),
    );
  }

  Future<String> execute({required String subject}) => executeMixed();
}

final createGetStartedSessionUseCaseProvider =
    FutureProvider<CreateGetStartedSessionUseCase>((ref) async {
      final create = await ref.watch(createSessionUseCaseProvider.future);
      final db = ref.watch(userDatabaseProvider);
      final prefs = await ref.watch(prefsServiceProvider.future);
      return CreateGetStartedSessionUseCase(
        createSession: create,
        userDb: db,
        prefsService: prefs,
        dailyCaRepository: ref.watch(dailyCaRepositoryProvider),
      );
    });
