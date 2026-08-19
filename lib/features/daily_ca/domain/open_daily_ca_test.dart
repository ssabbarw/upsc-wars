import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/question_source_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../data/daily_ca_firestore.dart';
import '../data/daily_ca_load_error.dart';
import '../data/daily_ca_repository.dart';
import '../providers/daily_ca_providers.dart';

/// Loads one day's current-affairs MCQs.
///
/// First attempt opens the test config sheet. Revise skips the sheet and starts
/// an untimed learning session on the same questions.
Future<void> openDailyCaTest({
  required BuildContext context,
  required WidgetRef ref,
  required String isoDate,
  required bool isRevise,
  VoidCallback? onFinished,
}) async {
  final firestorePath = DailyCaFirestore.pathForDate(isoDate);
  try {
    final repo = ref.read(dailyCaRepositoryProvider);
    final uuids = await repo.ensureCachedForDate(isoDate);
    if (!context.mounted) return;
    if (uuids.isEmpty) {
      throw DailyCaNotAvailableException(isoDate, firestorePath: firestorePath);
    }

    final analyticsKey = isRevise
        ? '${QuestionSourceConstants.analyticsDailyCurrentAffairs}_revise'
        : QuestionSourceConstants.analyticsDailyCurrentAffairs;

    if (isRevise) {
      final create = await ref.read(createSessionUseCaseProvider.future);
      final lang = await ref.read(appLanguageProvider.future);
      final sessionId = await create.execute(
        SessionConfig(
          subject: QuestionSourceConstants.dailyCaSessionSubject,
          topic: isoDate,
          mode: 'learning',
          questionCount: uuids.length,
          isTimed: false,
          timeLimitSecs: null,
          language: lang,
          specificQuestionUuids: uuids,
          analyticsFeatureKey: analyticsKey,
        ),
      );
      if (!context.mounted) return;
      await context.push('/test/$sessionId');
      if (!context.mounted) return;
      ref.invalidate(dailyCaDayCompletedProvider(isoDate));
      onFinished?.call();
      return;
    }

    final label = DateFormat(
      'd MMM yyyy',
    ).format(DateTime.parse(isoDate));

    await showTestConfigBottomSheet(
      context: context,
      args: TestConfigSheetArgs(
        subject: QuestionSourceConstants.dailyCaSessionSubject,
        topic: isoDate,
        subjectDisplayName: 'Daily Current Affairs',
        topicDisplayName: label,
        availableQuestionCount: uuids.length,
        topicCountWhenSubjectOnly: 1,
        lockedQuestionCount: uuids.length,
        specificQuestionUuids: uuids,
        startButtonLabel: 'Start test',
        analyticsFeatureKey: analyticsKey,
        onSessionCreated: (sessionId) async {
          await context.push('/test/$sessionId');
          if (!context.mounted) return;
          ref.invalidate(dailyCaDayCompletedProvider(isoDate));
          onFinished?.call();
        },
      ),
    );
  } catch (e, st) {
    final message = dailyCaLoadErrorMessage(e);
    developer.log(
      'Daily CA load failed for $isoDate ($firestorePath): $message',
      name: 'openDailyCaTest',
      stackTrace: st,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          dailyCaUserFacingErrorMessage(e),
          style: AppTextStyles.bodySm(),
        ),
      ),
    );
  }
}
