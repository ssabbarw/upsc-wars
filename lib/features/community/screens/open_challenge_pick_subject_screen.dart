import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/timed_exam_debug_constants.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/test_config_sheet_widgets.dart';
import '../open_challenge/open_challenge_before_you_start_panel.dart';
import '../open_challenge/open_challenge_create_availability.dart';
import '../open_challenge/open_challenge_launch_exam.dart';
import '../providers/open_challenge_providers.dart';
import '../../../l10n/l10n.dart';

class OpenChallengePickSubjectScreen extends ConsumerStatefulWidget {
  const OpenChallengePickSubjectScreen({super.key});

  @override
  ConsumerState<OpenChallengePickSubjectScreen> createState() =>
      _OpenChallengePickSubjectScreenState();
}

class _OpenChallengePickSubjectScreenState
    extends ConsumerState<OpenChallengePickSubjectScreen> {
  String? _selectedSubject;
  var _starting = false;

  static const _miscSubjectKey = 'misc';
  static const _tileWidth = 108.0;
  static const _tileHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectTestListProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfaceSecondaryDark
          : AppColors.surfaceSecondaryLight,
      appBar: AppBar(
        title: Text(context.l10n.ocCreateChallenge, style: AppTextStyles.h3()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ColoredBox(
              color: isDark
                  ? AppColors.surfacePrimaryDark
                  : AppColors.surfacePrimaryLight,
              child: subjectsAsync.when(
                data: (subjects) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.ocPickSubject,
                        style: AppTextStyles.h1().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.ocPickSubtitle(
                          (10 * kDebugSecondsPerQuestion / 60).round(),
                        ),
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.l10n.commonSubject,
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              SizedBox(
                                width: _tileWidth,
                                height: _tileHeight,
                                child: SubjectPickChipTile(
                                  label: 'Misc',
                                  selected: _selectedSubject == _miscSubjectKey,
                                  onTap: () => setState(
                                    () => _selectedSubject = _miscSubjectKey,
                                  ),
                                  scheme: scheme,
                                  isDark: isDark,
                                ),
                              ),
                              for (final subject in subjects)
                                SizedBox(
                                  width: _tileWidth,
                                  height: _tileHeight,
                                  child: SubjectPickChipTile(
                                    label: subject.displayName,
                                    selected:
                                        _selectedSubject == subject.subject,
                                    onTap: () => setState(
                                      () => _selectedSubject = subject.subject,
                                    ),
                                    scheme: scheme,
                                    isDark: isDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              context.l10n.ocPickNote,
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OpenChallengeBeforeYouStartPanel(scheme: scheme),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    context.l10n.ocSubjectsFailed,
                    style: AppTextStyles.body(),
                  ),
                ),
              ),
            ),
          ),
          Material(
            elevation: 8,
            shadowColor: AppColors.gray900.withValues(alpha: 0.08),
            color: isDark
                ? AppColors.surfacePrimaryDark
                : AppColors.surfacePrimaryLight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SafeArea(
                top: false,
                child: ref
                    .watch(openChallengeCreateAvailabilityProvider)
                    .when(
                      loading: () => FilledButton(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          context.l10n.ocStartMyAttempt,
                          style: AppTextStyles.label().copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      error: (_, _) => _pickSubjectStartColumn(
                        scheme: scheme,
                        blocked: false,
                        avail: null,
                      ),
                      data: (OpenChallengeCreateAvailability avail) =>
                          _pickSubjectStartColumn(
                            scheme: scheme,
                            blocked: !avail.allowed,
                            avail: avail,
                          ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickSubjectStartColumn({
    required ColorScheme scheme,
    required bool blocked,
    required OpenChallengeCreateAvailability? avail,
  }) {
    final canStart = !blocked && _selectedSubject != null && !_starting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blocked && avail != null) ...[
          Text(
            avail.pickSubjectCopy,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Tooltip(
          message: blocked && avail != null
              ? avail.tooltipLine
              : context.l10n.ocBeginTimed,
          child: FilledButton(
            onPressed: canStart ? _onStartChallenge : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: _starting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text(
                    context.l10n.ocStartMyAttempt,
                    style: AppTextStyles.label().copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _onStartChallenge() async {
    final subject = _selectedSubject;
    if (subject == null || _starting) return;
    final prefs = await ref.read(prefsServiceProvider.future);
    if (!OpenChallengeCreateAvailability.fromPrefs(prefs).allowed) return;
    if (!mounted) return;
    setState(() => _starting = true);
    try {
      if (!mounted) return;
      await launchOpenChallengeExam(
        ref,
        context,
        OpenChallengeExamArgs.create(subject: subject),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}
