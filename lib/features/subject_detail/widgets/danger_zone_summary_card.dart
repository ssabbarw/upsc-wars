import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../domain/subject_insights.dart';
import '../providers/subject_danger_zone_revise_uuids.dart';

/// Danger Zone card: counts + Revise for Sure / Educated guess (lifetime).
///
/// [dangerZoneContextLabel] is shown as "Danger zone of **{label}**".
/// When [topic] is set, revise lists and session are scoped to that topic.
class DangerZoneSummaryCard extends HookConsumerWidget {
  const DangerZoneSummaryCard({
    super.key,
    required this.dangerZoneContextLabel,
    required this.subject,
    this.topic,
    required this.insights,
    required this.borderColor,
    this.onLearningSessionStarted,
  });

  final String dangerZoneContextLabel;
  final String subject;
  final String? topic;
  final SubjectInsights insights;
  final Color borderColor;

  /// If set, called instead of [context.push] after a learning session is created (e.g. close a parent bottom sheet first).
  final void Function(String sessionId)? onLearningSessionStarted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = insights.dangerZoneWrongCount;
    final calm = insights.isWellCalibrated;
    final sureWrong = insights.dangerZoneSureWrongCount;
    final guessWrong = insights.dangerZoneEducatedGuessWrongCount;
    const markWeight = 0.66;
    final sureMarksStr = (sureWrong * markWeight).toStringAsFixed(2);
    final guessMarksStr = (guessWrong * markWeight).toStringAsFixed(2);
    final revBusy = useState<String?>(null);

    final accent = calm
        ? (isDark ? AppColors.correctTextDark : AppColors.correctText)
        : (isDark ? AppColors.wrongTextDark : AppColors.wrongText);

    Future<void> navigateToTest(String sessionId) async {
      final custom = onLearningSessionStarted;
      if (custom != null) {
        custom(sessionId);
      } else if (context.mounted) {
        context.push('/test/$sessionId');
      }
    }

    Future<void> startRevise(String key, String confidence, String analyticsKey) async {
      if (revBusy.value != null) return;
      revBusy.value = key;
      try {
        final db = ref.read(userDatabaseProvider);
        final scopedTopic = topic;
        final uuids = scopedTopic != null
            ? await queryTopicDangerZoneReviseUuids(
                db,
                subject: subject,
                topic: scopedTopic,
                confidence: confidence,
              )
            : await querySubjectDangerZoneReviseUuids(
                db,
                subject: subject,
                confidence: confidence,
              );
        if (!context.mounted) return;
        if (uuids.isEmpty) {
          AppToast.showText(context, 'No questions in this category.');
          return;
        }
        final create = await ref.read(createSessionUseCaseProvider.future);
        final lang = await ref.read(appLanguageProvider.future);
        final id = await create.execute(
          SessionConfig(
            subject: subject,
            topic: scopedTopic,
            mode: 'learning',
            questionCount: uuids.length,
            isTimed: false,
            timeLimitSecs: null,
            language: lang,
            specificQuestionUuids: uuids,
            analyticsFeatureKey: analyticsKey,
            dangerReviseHistoryConfidence: confidence,
          ),
        );
        if (context.mounted) await navigateToTest(id);
      } catch (e) {
        if (context.mounted) {
        AppToast.showText(context, 'Could not start session: $e');
        }
      } finally {
        if (context.mounted) revBusy.value = null;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ColoredBox(
        color: scheme.surface,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 0.5),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                3 + AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger zone of $dangerZoneContextLabel',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Wrong answers with Sure or Educated-guess (all-time)',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (calm)
                    Text(
                      'No Sure or Educated-guess wrong answers yet.',
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.onSurface,
                      ),
                    )
                  else ...[
                    Text(
                      'Total: $count wrong · about ${insights.dangerZoneMarks.toStringAsFixed(2)} marks (0.66 each if counted)',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DangerZoneBreakdownTile(
                      accent: isDark ? AppColors.wrongTextDark : AppColors.wrong,
                      barColor: isDark
                          ? AppColors.wrongTextDark
                          : AppColors.wrongText,
                      surface: isDark
                          ? AppColors.wrongBgDark
                          : AppColors.wrongBg,
                      borderColor: borderColor,
                      icon: Icons.bolt_rounded,
                      title: 'Sure — wrong',
                      subtitle: 'You marked Sure and answered incorrectly.',
                      count: sureWrong,
                      marksLabel: '≈ $sureMarksStr marks',
                      isReviseLoading: revBusy.value == 'sure',
                      onRevise: sureWrong == 0 || revBusy.value != null
                          ? null
                          : () => startRevise(
                                'sure',
                                AnswerConfidence.verySure,
                                topic != null
                                    ? 'topic_danger_sure'
                                    : 'subject_danger_sure',
                              ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DangerZoneBreakdownTile(
                      accent: isDark
                          ? AppColors.warningTextDark
                          : AppColors.warning,
                      barColor: isDark
                          ? AppColors.warningTextDark
                          : AppColors.warningText,
                      surface: isDark
                          ? AppColors.warningBgDark
                          : AppColors.warningBg,
                      borderColor: borderColor,
                      icon: Icons.auto_awesome_outlined,
                      title: 'Educated guess — wrong',
                      subtitle: 'You marked Educated guess and answered incorrectly.',
                      count: guessWrong,
                      marksLabel: '≈ $guessMarksStr marks',
                      isReviseLoading: revBusy.value == 'guess',
                      onRevise: guessWrong == 0 || revBusy.value != null
                          ? null
                          : () => startRevise(
                                'guess',
                                AnswerConfidence.somewhatSure,
                                topic != null
                                    ? 'topic_danger_guess'
                                    : 'subject_danger_guess',
                              ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerZoneBreakdownTile extends StatelessWidget {
  const _DangerZoneBreakdownTile({
    required this.accent,
    required this.barColor,
    required this.surface,
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.marksLabel,
    required this.isReviseLoading,
    required this.onRevise,
  });

  final Color accent;
  final Color barColor;
  final Color surface;
  final Color borderColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final String marksLabel;
  final bool isReviseLoading;
  final VoidCallback? onRevise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(color: barColor, child: const SizedBox(width: 3)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 20, color: accent),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.caption().copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$count',
                                style: AppTextStyles.h2().copyWith(
                                  fontSize: 22,
                                  color: barColor,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                marksLabel,
                                textAlign: TextAlign.end,
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: FilledButton.tonal(
                onPressed: isReviseLoading ? null : onRevise,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
                child: isReviseLoading
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      )
                    : Text(
                        'Revise',
                        style: AppTextStyles.label(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
