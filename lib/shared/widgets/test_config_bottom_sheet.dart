import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/timed_exam_debug_constants.dart';
import '../../core/domain/entities/session_config.dart';
import '../../core/providers/catalog_providers.dart';
import '../../core/providers/prefs_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'top_snack_bar.dart';
import 'dismissible_modal_sheet.dart';
import 'test_config_sheet_widgets.dart';
import '../extensions/count_formatting.dart';

class TestConfigSheetArgs {
  const TestConfigSheetArgs({
    required this.subject,
    this.topic,
    this.subTopic,
    required this.subjectDisplayName,
    this.topicDisplayName,
    required this.availableQuestionCount,
    required this.topicCountWhenSubjectOnly,
    required this.onSessionCreated,
    this.lockedQuestionCount,
    this.forceExamMode = false,
    this.startButtonLabel,
    this.specificQuestionUuids,
    this.fixedQuestionSetLabel,
    this.analyticsFeatureKey,
  });

  final String subject;
  final String? topic;
  final String? subTopic;
  final String subjectDisplayName;
  final String? topicDisplayName;
  final int availableQuestionCount;
  final int topicCountWhenSubjectOnly;
  final void Function(String sessionId) onSessionCreated;
  final int? lockedQuestionCount;
  final bool forceExamMode;
  final String? startButtonLabel;

  /// When set, the session is built from exactly these UUIDs in order.
  final List<String>? specificQuestionUuids;

  /// Shown in the locked-count panel when [specificQuestionUuids] is set.
  final String? fixedQuestionSetLabel;
  final String? analyticsFeatureKey;
}

Future<void> showTestConfigBottomSheet({
  required BuildContext context,
  required TestConfigSheetArgs args,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) => DismissOnScrimTap(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: TestConfigBottomSheet(args: args),
      ),
    ),
  );
}

class TestConfigBottomSheet extends HookConsumerWidget {
  const TestConfigBottomSheet({super.key, required this.args});

  final TestConfigSheetArgs args;

  static const _presetCounts = [10, 15, 25];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final isExam = useState(args.forceExamMode ? true : true);
    final selectedPreset = useState(args.lockedQuestionCount ?? 10);
    final examTimed = useState(args.forceExamMode ? true : true);
    // null = no limit
    final learningSecs = useState<int?>(60);
    final isSubmitting = useState(false);

    final prefsAsync = ref.watch(prefsServiceProvider);

    final maxQ = args.availableQuestionCount;
    final countChoices = useMemoized(() {
      if (maxQ <= 0) return <int>[];
      final hits = _presetCounts.where((n) => n <= maxQ).toList();
      if (hits.isNotEmpty) return hits;
      return [maxQ];
    }, [maxQ]);

    useEffect(() {
      if (maxQ <= 0) return null;
      final choices = _presetCounts.where((n) => n <= maxQ).toList();
      final effectiveChoices = choices.isNotEmpty ? choices : <int>[maxQ];
      if (selectedPreset.value > maxQ) {
        selectedPreset.value = maxQ;
      }
      if (!effectiveChoices.contains(selectedPreset.value)) {
        selectedPreset.value = effectiveChoices.contains(10)
            ? 10
            : effectiveChoices.first;
      }
      return null;
    }, [maxQ]);

    final effectiveCount = maxQ == 0
        ? 0
        : ((args.lockedQuestionCount ?? selectedPreset.value) > maxQ
              ? maxQ
              : (args.lockedQuestionCount ?? selectedPreset.value));
    final capped = maxQ > 0 && selectedPreset.value > maxQ;

    Future<void> onStart() async {
      if (effectiveCount <= 0 || isSubmitting.value) return;
      isSubmitting.value = true;
      try {
        final uc = await ref.read(createSessionUseCaseProvider.future);
        final lang = await ref.read(appLanguageProvider.future);
        int? timeLimitSecs;
        if (isExam.value) {
          if (examTimed.value) {
            timeLimitSecs = effectiveCount * kDebugSecondsPerQuestion;
          }
        } else {
          timeLimitSecs = learningSecs.value;
        }
        final hasLearningTimer = !isExam.value && learningSecs.value != null;
        final config = SessionConfig(
          subject: args.subject,
          topic: args.topic,
          subTopic: args.subTopic,
          mode: isExam.value ? 'exam' : 'learning',
          questionCount: effectiveCount,
          isTimed: isExam.value ? examTimed.value : hasLearningTimer,
          timeLimitSecs: timeLimitSecs,
          language: lang,
          specificQuestionUuids: args.specificQuestionUuids,
          analyticsFeatureKey: args.analyticsFeatureKey,
        );
        final id = await uc.execute(config);
        if (!context.mounted) return;
        Navigator.of(context).pop();
        args.onSessionCreated(id);
      } catch (_) {
        if (!context.mounted) return;
        showTopSnackBar(
          context,
          content: Text(
            'Something went wrong. Please try again.',
            style: AppTextStyles.bodyMd().copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      } finally {
        if (context.mounted) isSubmitting.value = false;
      }
    }

    Widget confidenceReminder() {
      return prefsAsync.when(
        data: (prefs) {
          if (prefs.confidenceTrackingEnabled) return const SizedBox.shrink();
          return Material(
            color: AppColors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                Future.microtask(() => router.pushNamed('settings'));
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color:
                        (isDark ? AppColors.borderDark : AppColors.borderLight)
                            .withValues(alpha: 0.9),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.psychology_alt_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confidence rating is off',
                            style: AppTextStyles.labelSm().copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Turn it on to track how sure you were before reveal '
                            'and unlock Danger Zone insights.',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, stack) => const SizedBox.shrink(),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.sm,
                    top: AppSpacing.xs,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 40,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.sm,
                  AppSpacing.xxl,
                  AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                args.subjectDisplayName,
                                style: AppTextStyles.h2().copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                              if (args.fixedQuestionSetLabel != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  args.fixedQuestionSetLabel!,
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                              if (args.topicDisplayName != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  args.topicDisplayName!,
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Q count picker inline with the header
                        if (args.lockedQuestionCount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: borderColor,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '${args.lockedQuestionCount} Q',
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else if (maxQ > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < countChoices.length; i++) ...[
                                if (i > 0) const SizedBox(width: AppSpacing.xs),
                                _CompactCountChip(
                                  label: '${countChoices[i]}',
                                  selected: selectedPreset.value ==
                                      countChoices[i],
                                  examMode: isExam.value,
                                  isDark: isDark,
                                  onTap: () =>
                                      selectedPreset.value = countChoices[i],
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                    if (capped) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Only ${formatIntCount(maxQ)} available',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    if (!args.forceExamMode) ...[
                      Text(
                        'Mode',
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TestConfigModeOptionCard(
                              title: 'Exam',
                              description:
                                  'Simulate real conditions. Explanation after test ends.',
                              icon: Icons.timer_outlined,
                              selected: isExam.value,
                              examStyle: true,
                              borderColor: borderColor,
                              onTap: () => isExam.value = true,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TestConfigModeOptionCard(
                              title: 'Learning',
                              description:
                                  'See explanation after each question.',
                              icon: Icons.lightbulb_outline,
                              selected: !isExam.value,
                              examStyle: false,
                              borderColor: borderColor,
                              onTap: () => isExam.value = false,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (maxQ == 0) ...[
                      Text(
                        'No questions available for this topic.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (isExam.value) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      confidenceReminder(),
                      const SizedBox(height: AppSpacing.sm),
                      _TimedTestCard(
                        timed: examTimed.value,
                        duration: _formatExamDuration(effectiveCount),
                        interactive: !args.forceExamMode,
                        onChanged: (v) => examTimed.value = v,
                        borderColor: borderColor,
                        isDark: isDark,
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Time per question',
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TestConfigLearningTimeTile(
                              label: '45s',
                              selected: learningSecs.value == 45,
                              isDark: isDark,
                              onTap: () => learningSecs.value = 45,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TestConfigLearningTimeTile(
                              label: '1 min',
                              selected: learningSecs.value == 60,
                              isDark: isDark,
                              onTap: () => learningSecs.value = 60,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TestConfigLearningTimeTile(
                              label: '2 min',
                              selected: learningSecs.value == 120,
                              isDark: isDark,
                              onTap: () => learningSecs.value = 120,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TestConfigLearningTimeTile(
                              label: 'No limit',
                              selected: learningSecs.value == null,
                              isDark: isDark,
                              onTap: () => learningSecs.value = null,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting.value || effectiveCount <= 0
                            ? null
                            : onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isExam.value
                              ? AppColors.info
                              : AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          disabledBackgroundColor: scheme.surfaceContainerLow,
                          disabledForegroundColor: scheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting.value
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : Text(
                                args.startButtonLabel ??
                                    (isExam.value
                                        ? 'Start exam'
                                        : 'Start learning session'),
                                style: AppTextStyles.label(),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatExamDuration(int questionCount) {
    final totalSecs = questionCount * kDebugSecondsPerQuestion;
    final minutes = (totalSecs / 60).round();
    return '$minutes minutes total';
  }
}

/// Small inline chip shown next to the subject title for question count.
class _CompactCountChip extends StatelessWidget {
  const _CompactCountChip({
    required this.label,
    required this.selected,
    required this.examMode,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool examMode;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    Color border;
    if (selected) {
      if (examMode) {
        bg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
        fg = isDark ? AppColors.infoTextDark : AppColors.infoText;
        border = AppColors.info;
      } else {
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        fg = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        border = AppColors.primary;
      }
    } else {
      bg = scheme.surfaceContainerLow;
      fg = scheme.onSurfaceVariant;
      border = isDark ? AppColors.borderDark : AppColors.borderLight;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border, width: selected ? 1.5 : 0.5),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm().copyWith(color: fg),
        ),
      ),
    );
  }
}

class _TimedTestCard extends StatelessWidget {
  const _TimedTestCard({
    required this.timed,
    required this.duration,
    required this.interactive,
    required this.onChanged,
    required this.borderColor,
    required this.isDark,
  });

  final bool timed;
  final String duration;
  final bool interactive;
  final ValueChanged<bool> onChanged;
  final Color borderColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final infoBg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final infoText = isDark ? AppColors.infoTextDark : AppColors.infoText;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: infoText, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timed test',
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        duration,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: timed,
                  onChanged: interactive ? onChanged : null,
                  activeThumbColor: AppColors.onPrimary,
                  activeTrackColor: AppColors.info,
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: borderColor),
          Container(
            color: infoBg,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: infoText),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Exam mode is a timed test with explanations after it ends.',
                    style: AppTextStyles.caption().copyWith(color: infoText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
