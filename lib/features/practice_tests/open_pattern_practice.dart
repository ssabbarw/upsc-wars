import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/domain/entities/session_config.dart';
import '../../core/providers/catalog_providers.dart';
import '../../core/providers/user_database_provider.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/app_toast.dart';
import '../subject_detail/domain/subject_mcq_pattern.dart';
import 'providers/practice_subject_insights_provider.dart';

Future<void> openPatternPractice(
  BuildContext context,
  WidgetRef ref, {
  required String subject,
  required SubjectMcqPatternStat pattern,
}) async {
  final db = ref.read(userDatabaseProvider);
  final uuids = await loadPatternPracticeUuids(
    db,
    subject: subject,
    pattern: pattern,
  );
  if (!context.mounted) return;
  if (uuids.isEmpty) {
    AppToast.showText(context, context.l10n.practicePatternsNoQuestions);
    return;
  }
  try {
    final create = await ref.read(createSessionUseCaseProvider.future);
    final lang = await ref.read(appLanguageProvider.future);
    final id = await create.execute(
      SessionConfig(
        subject: subject,
        mode: 'learning',
        questionCount: uuids.length,
        isTimed: false,
        timeLimitSecs: null,
        language: lang,
        specificQuestionUuids: uuids,
        analyticsFeatureKey: 'practice_pattern_revise',
      ),
    );
    if (!context.mounted) return;
    await context.push('/test/$id');
  } catch (e) {
    if (context.mounted) {
      AppToast.showText(context, context.l10n.dzStartFailed(e.toString()));
    }
  }
}
