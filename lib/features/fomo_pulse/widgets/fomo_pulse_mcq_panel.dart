import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/admin_dashboard/admin_dashboard_service.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/parsers/question_display_text_composer.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../home/domain/daily_streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../history/widgets/explanation_card.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';
import '../../../l10n/l10n.dart';

/// Tutor-like MCQ: tap option → instant verdict + explanation.
class FomoPulseMcqPanel extends HookConsumerWidget {
  const FomoPulseMcqPanel({
    super.key,
    required this.pulse,
    required this.existingAttempt,
    this.initialSelectedOption,
    this.showNavigationCtas = false,
    this.entrySource = FomoPulseConstants.entryInApp,
  });

  final FomoPulse pulse;
  final FomoPulseAttemptState? existingAttempt;
  final String? initialSelectedOption;
  final bool showNavigationCtas;
  final String entrySource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHi = watchAppLanguage(ref) == 'hi';
    final question = pulse.question.localized(isHi);
    final openedAt = useMemoized(DateTime.now);
    final attemptedOnOpen = existingAttempt?.attempted == true;
    final picked = useState<String?>(existingAttempt?.selectedOption);
    final liveStats = useState<FomoPulseCommunityStats?>(null);

    final selected = picked.value ?? '';
    final revealed = selected.isNotEmpty;
    final isCorrect =
        selected.toLowerCase() == question.correctOption.toLowerCase();
    final stats = liveStats.value ?? pulse.communityStats();
    final valueAddPoints = isHi && pulse.upscPointsHi.isNotEmpty
        ? pulse.upscPointsHi
        : pulse.upscPoints;
    final explanationText = _explanationWithValueAdd(
      question.finalExplanation,
      valueAddPoints,
    );

    Future<void> syncAttempt(String option) async {
      final secs = DateTime.now().difference(openedAt).inSeconds.clamp(1, 600);
      final repo = ref.read(fomoPulseRepositoryProvider);
      final cloud = ref.read(fomoPulseCloudServiceProvider);
      final local = FomoPulseSubmitResult(
        isCorrect: option.toLowerCase() == question.correctOption.toLowerCase(),
        selectedOption: option,
        correctOption: question.correctOption,
        alreadyAttempted: false,
        timeSpentSecs: secs,
      );
      await repo.recordLocalAttempt(
        pulseId: pulse.pulseId,
        result: local,
        updateCommunityCounts: false,
      );
      final prefs = await ref.read(prefsServiceProvider.future);
      DailyStreakService.recordRingClosed(prefs: prefs);
      ref.invalidate(homeStateProvider);
      try {
        final remote = await cloud.submitAttempt(
          pulseId: pulse.pulseId,
          selectedOption: option,
          timeSpentSecs: secs,
        );
        await repo.recordLocalAttempt(pulseId: pulse.pulseId, result: remote);
        if (!context.mounted) return;
        liveStats.value = FomoPulseCommunityStats(
          attemptCount: remote.attemptCount,
          correctCount: remote.correctCount,
        );
        if (!remote.alreadyAttempted) {
          unawaited(AdminDashboardWriterService().recordFomoPulseEngagement());
        }
      } catch (_) {}
      ref.invalidate(fomoPulseDetailProvider(pulse.pulseId));
      unawaited(
        ref.read(fomoPulseHistoryProvider.notifier).refresh(force: true),
      );
    }

    void onPick(String option) {
      if (revealed) return;
      picked.value = option;
      if (!attemptedOnOpen) {
        final right =
            option.toLowerCase() == question.correctOption.toLowerCase();
        liveStats.value = FomoPulseCommunityStats(
          attemptCount: pulse.attemptCount + 1,
          correctCount: pulse.correctCount + (right ? 1 : 0),
        );
        unawaited(syncAttempt(option));
        unawaited(
          Analytics.track(
            ref,
            CaShotAttemptedEvent(
              pulseId: pulse.pulseId,
              source: entrySource,
              correct:
                  option.toLowerCase() == question.correctOption.toLowerCase(),
            ),
          ),
        );
      }
    }

    useEffect(() {
      final option = initialSelectedOption?.trim().toLowerCase();
      if (attemptedOnOpen || option == null || option.isEmpty || revealed) {
        return null;
      }
      onPick(option);
      return null;
    }, [initialSelectedOption, attemptedOnOpen]);

    Widget optionTile(String key, String text) {
      final k = key.toLowerCase();
      final chosen = selected.toLowerCase() == k;
      final correct = question.correctOption.toLowerCase() == k;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final scheme = Theme.of(context).colorScheme;
      final bg = !revealed
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
          : correct
          ? (isDark ? AppColors.correctBgDark : AppColors.correctBg)
          : chosen
          ? (isDark ? AppColors.wrongBgDark : AppColors.wrongBg)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
      final border = !revealed
          ? Colors.transparent
          : correct
          ? AppColors.correct
          : chosen
          ? AppColors.wrong
          : Colors.transparent;
      final fg = !revealed
          ? scheme.onSurface
          : correct
          ? (isDark ? AppColors.correctTextDark : AppColors.correctText)
          : chosen
          ? (isDark ? AppColors.wrongTextDark : AppColors.wrongText)
          : scheme.onSurface;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: revealed ? null : () => onPick(k),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: border,
                  width: revealed && (correct || chosen) ? 1.5 : 0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: revealed
                          ? border.withValues(alpha: 0.14)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      key.toUpperCase(),
                      style: AppTextStyles.labelSm().copyWith(
                        color: revealed ? fg : AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTextStyles.option().copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.stemText,
          style: AppTextStyles.body().copyWith(
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        optionTile('a', question.optionA),
        optionTile('b', question.optionB),
        optionTile('c', question.optionC),
        optionTile('d', question.optionD),
        if (!revealed) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.fpPickSee,
            style: AppTextStyles.caption().copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (revealed) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            isCorrect
                ? context.l10n.fpCorrectBang
                : context.l10n.reviewIncorrect,
            style: AppTextStyles.label().copyWith(
              color: isCorrect ? AppColors.correct : AppColors.wrong,
            ),
          ),
          if (stats != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              stats.breakdownLine,
              style: AppTextStyles.caption().copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ExplanationCard(
                translation: QuestionTranslation(
                  finalExplanation: explanationText,
                  statementAnalysis: [
                    for (final item in question.statementAnalysis)
                      StatementAnalysisVm(
                        statement: item.statement,
                        isCorrect: item.isCorrect,
                        reason: item.reason,
                      ),
                  ],
                  eliminationLogic: question.eliminationLogic,
                  strongDistractor: question.strongDistractor,
                  upscTrapExplanation: question.upscTrapExplanation,
                  conceptsUsed: const [],
                ),
                showStatements: question.statementAnalysis.isNotEmpty,
                demoForceDeepDive: true,
              ),
            ),
          ),
          if (showNavigationCtas) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_outlined),
              label: Text(context.l10n.commonBackToHome),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n.fpBackToShot),
            ),
          ],
        ],
      ],
    );
  }
}

String _explanationWithValueAdd(
  String explanation,
  List<String> valueAddPoints,
) {
  final trimmed = explanation.trim();
  final parts = FinalExplanationParts.split(trimmed);
  if (parts.valueAddition.trim().isNotEmpty) return trimmed;
  if (valueAddPoints.isEmpty) return trimmed;
  final bullets = valueAddPoints
      .where((p) => p.trim().isNotEmpty)
      .map((p) => '• $p')
      .join('\n');
  return FinalExplanationParts.join(
    body: parts.body.isNotEmpty ? parts.body : trimmed,
    valueAddition: bullets,
  );
}
