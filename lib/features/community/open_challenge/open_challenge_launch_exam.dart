import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/timed_exam_debug_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../data/open_challenge_repository.dart';
import 'open_challenge_analytics.dart';
import 'open_challenge_exam_context.dart';
import 'open_challenge_exam_registry.dart';

class OpenChallengeExamArgs {
  const OpenChallengeExamArgs._({
    required this.kind,
    required this.subject,
    this.challengeId,
    this.questionUuids,
  });

  factory OpenChallengeExamArgs.create({required String subject}) {
    return OpenChallengeExamArgs._(
      kind: OpenChallengeExamKind.create,
      subject: subject,
    );
  }

  factory OpenChallengeExamArgs.accept({
    required String challengeId,
    required String subject,
    required List<String> questionUuids,
  }) {
    return OpenChallengeExamArgs._(
      kind: OpenChallengeExamKind.accept,
      subject: subject,
      challengeId: challengeId,
      questionUuids: List<String>.from(questionUuids),
    );
  }

  final OpenChallengeExamKind kind;
  final String subject;
  final String? challengeId;
  final List<String>? questionUuids;
}

/// Creates the timed exam session, registers open-challenge context, opens test.
Future<void> launchOpenChallengeExam(
  WidgetRef ref,
  BuildContext context,
  OpenChallengeExamArgs args,
) async {
  try {
    final db = ref.read(userDatabaseProvider);
    final uuids = args.kind == OpenChallengeExamKind.accept
        ? args.questionUuids!
        : await pickTenRandomQuestionUuidsForSubject(
            userDatabase: db,
            subject: args.subject,
          );

    final lang = await ref.read(appLanguageProvider.future);
    final create = await ref.read(createSessionUseCaseProvider.future);
    final sessionId = await create.execute(
      SessionConfig(
        subject: args.subject,
        mode: 'exam',
        questionCount: uuids.length,
        isTimed: true,
        timeLimitSecs: uuids.length * kDebugSecondsPerQuestion,
        language: lang,
        specificQuestionUuids: uuids,
        analyticsFeatureKey: args.kind == OpenChallengeExamKind.create
            ? OpenChallengeAnalytics.create
            : OpenChallengeAnalytics.accept,
      ),
    );

    ref.read(openChallengeExamRegistryProvider).register(
          OpenChallengeExamContext(
            kind: args.kind,
            sessionId: sessionId,
            subjectDisplay: args.subject,
            questionUuids: uuids,
            existingChallengeId: args.challengeId,
          ),
        );

    if (context.mounted) {
      await context.push('/test/$sessionId');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}
