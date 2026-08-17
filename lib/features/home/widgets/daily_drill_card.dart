import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/services/daily_practice_reminder_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/start_daily_drill.dart';
import '../providers/daily_drill_provider.dart';
import 'daily_drill_subject_sheet.dart';

/// Pinned daily practice card — visible after home activation.
class DailyDrillCard extends HookConsumerWidget {
  const DailyDrillCard({super.key, this.emphasized = false});

  /// Time-of-day hero — thicker border so it reads as the one to tap.
  final bool emphasized;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyDrillProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final loading = useState(false);
    final loggedShown = useRef(false);

    useEffect(() {
      if (loggedShown.value) return null;
      final state = async.maybeWhen(data: (s) => s, orElse: () => null);
      if (state == null) return null;
      loggedShown.value = true;
      unawaited(Analytics.track(ref, const DailyDrillCardShownEvent()));
      unawaited(
        Analytics.track(
          ref,
          FeatureViewedEvent(
            featureName: 'daily_drill',
            subject: state.subject,
            source: 'home',
          ),
        ),
      );
      return null;
    }, [async]);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        if (state == null) return const SizedBox.shrink();

        Future<void> startDrill({required String source}) async {
          if (loading.value) return;
          loading.value = true;
          try {
            await startDailyDrill(
              context: context,
              ref: ref,
              subject: state.subject,
              source: source,
              completedToday: state.completedToday,
            );
          } finally {
            loading.value = false;
          }
        }

        Future<void> openSubjectSheet() async {
          final picked = await showDailyDrillSubjectSheet(
            context,
            selectedSubject: state.subject,
          );
          if (picked == null || picked == state.subject) return;
          final prefs = await ref.read(prefsServiceProvider.future);
          prefs.dailyPracticeSubject = picked;
          unawaited(
            Analytics.track(
              ref,
              DailyDrillSubjectChangedEvent(subject: picked),
            ),
          );
          ref.invalidate(dailyDrillProvider);
          unawaited(
            DailyPracticeReminderService.sync(
              prefs: prefs,
              activationComplete: true,
              completedToday: state.completedToday,
            ),
          );
        }

        final subtitle = state.completedToday
            ? 'Done today · tap to practice more'
            : '10 quick MCQs · about 5 minutes';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading.value ? null : () => startDrill(source: 'card'),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDeep.withValues(alpha: 0.2)
                    : AppColors.primaryLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: emphasized
                      ? AppColors.primary
                      : state.completedToday
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : borderColor,
                  width: emphasized
                      ? 2
                      : (state.completedToday ? 1.5 : 0.5),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      state.completedToday
                          ? Icons.check_circle_outline_rounded
                          : Icons.bolt_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATIC PRACTICE',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          state.subjectDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd().copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.completedToday ? 'Practice more' : 'Start drill',
                          style: AppTextStyles.labelSm().copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: 'Change subject',
                    visualDensity: VisualDensity.compact,
                    onPressed: loading.value ? null : openSubjectSheet,
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (loading.value)
                    const Padding(
                      padding: EdgeInsets.only(left: AppSpacing.xs),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
