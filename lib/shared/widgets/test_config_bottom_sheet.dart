import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/domain/entities/session_config.dart';
import '../../core/providers/catalog_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'top_snack_bar.dart';
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
}

Future<void> showTestConfigBottomSheet({
  required BuildContext context,
  required TestConfigSheetArgs args,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: TestConfigBottomSheet(args: args),
    ),
  );
}

class TestConfigBottomSheet extends HookConsumerWidget {
  const TestConfigBottomSheet({super.key, required this.args});

  final TestConfigSheetArgs args;

  static const _presetCounts = [10, 25, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final isExam = useState(args.forceExamMode ? true : true);
    final selectedPreset = useState(args.lockedQuestionCount ?? 25);
    final examTimed = useState(true);
    final learningSecs = useState(60);
    final isSubmitting = useState(false);

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
        selectedPreset.value = effectiveChoices.last;
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
            timeLimitSecs = effectiveCount * 72;
          }
        } else {
          timeLimitSecs = learningSecs.value;
        }
        final config = SessionConfig(
          subject: args.subject,
          topic: args.topic,
          subTopic: args.subTopic,
          mode: isExam.value ? 'exam' : 'learning',
          questionCount: effectiveCount,
          isTimed: isExam.value ? examTimed.value : true,
          timeLimitSecs: timeLimitSecs,
          language: lang,
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

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                args.subjectDisplayName,
                style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (args.topicDisplayName != null) ...[
                Text(
                  args.topicDisplayName!,
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatIntCount(maxQ)} questions available',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ] else
                Text(
                  '${formatIntCount(maxQ)} questions · ${args.topicCountWhenSubjectOnly} topics',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
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
                      child: _ModeOptionCard(
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
                      child: _ModeOptionCard(
                        title: 'Learning',
                        description: 'See explanation after each question.',
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
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Number of questions',
                style: AppTextStyles.label().copyWith(color: scheme.onSurface),
              ),
              if (capped) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Only ${formatIntCount(maxQ)} questions available for this topic.',
                  style: AppTextStyles.caption().copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (maxQ == 0) ...[
                Text(
                  'No questions available for this topic.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ] else if (args.lockedQuestionCount != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
                  child: Text(
                    '${args.lockedQuestionCount} questions (fixed for battle)',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ] else
                Row(
                  children: [
                    for (var i = 0; i < countChoices.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CountTile(
                          label: '${countChoices[i]}',
                          selected: selectedPreset.value == countChoices[i],
                          examMode: isExam.value,
                          isDark: isDark,
                          onTap: () => selectedPreset.value = countChoices[i],
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CountTile(
                        label: 'Custom',
                        selected: false,
                        examMode: isExam.value,
                        isDark: isDark,
                        muted: true,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
              if (isExam.value) ...[
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timed test',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    Switch(
                      value: examTimed.value,
                      onChanged: (v) => examTimed.value = v,
                      activeThumbColor: AppColors.onPrimary,
                      activeTrackColor: AppColors.info,
                    ),
                  ],
                ),
                if (examTimed.value) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _formatExamDuration(effectiveCount),
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
                      child: _LearningTimeTile(
                        label: '45s',
                        selected: learningSecs.value == 45,
                        isDark: isDark,
                        onTap: () => learningSecs.value = 45,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _LearningTimeTile(
                        label: '1 min',
                        selected: learningSecs.value == 60,
                        isDark: isDark,
                        onTap: () => learningSecs.value = 60,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _LearningTimeTile(
                        label: '2 min',
                        selected: learningSecs.value == 120,
                        isDark: isDark,
                        onTap: () => learningSecs.value = 120,
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
    );
  }

  static String _formatExamDuration(int questionCount) {
    final totalSecs = questionCount * 72;
    final minutes = (totalSecs / 60).round();
    return '$minutes minutes total';
  }
}

class _ModeOptionCard extends HookConsumerWidget {
  const _ModeOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.examStyle,
    required this.borderColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final bool examStyle;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late final Color bg;
    late final Color border;
    late final Color titleColor;
    late final Color bodyColor;
    late final Color iconColor;

    if (selected) {
      if (examStyle) {
        bg = isDark ? AppColors.infoBgDark : AppColors.infoBg;
        border = AppColors.info;
        titleColor = isDark ? AppColors.infoTextDark : AppColors.infoText;
        bodyColor = titleColor;
        iconColor = titleColor;
      } else {
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        titleColor = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        bodyColor = titleColor;
        iconColor = titleColor;
        border = AppColors.primary;
      }
    } else {
      bg = scheme.surface;
      border = borderColor;
      titleColor = scheme.onSurface;
      bodyColor = scheme.onSurfaceVariant;
      iconColor = scheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: selected ? 2 : 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.labelSm().copyWith(color: titleColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTextStyles.caption().copyWith(color: bodyColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends HookConsumerWidget {
  const _CountTile({
    required this.label,
    required this.selected,
    required this.examMode,
    required this.isDark,
    this.muted = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool examMode;
  final bool isDark;
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (muted) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

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
      bg = scheme.surface;
      fg = scheme.onSurface;
      border = isDark ? AppColors.borderDark : AppColors.borderLight;
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected ? 2 : 0.5),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm().copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}

class _LearningTimeTile extends HookConsumerWidget {
  const _LearningTimeTile({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? (isDark ? AppColors.primaryDeep : AppColors.primaryLight)
        : scheme.surface;
    final fg = selected
        ? (isDark ? AppColors.onPrimary : AppColors.primaryDeep)
        : scheme.onSurface;
    final border = selected
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: selected ? 2 : 0.5),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm().copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}
