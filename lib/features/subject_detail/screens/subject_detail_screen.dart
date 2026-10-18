import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../domain/subject_insights.dart';
import '../domain/subject_mock_prep_insights.dart';
import '../domain/subject_scored_accuracy_summary.dart';
import '../providers/subject_detail_providers.dart';
import '../providers/subject_insights_providers.dart';
import '../providers/subject_mock_prep_provider.dart';
import '../providers/subject_scored_accuracy_provider.dart';
import '../widgets/danger_zone_summary_card.dart';
import '../widgets/mock_prep_why_bottom_sheet.dart';
import '../widgets/topic_entry_bottom_sheet.dart';
import '../../../l10n/l10n.dart';

class SubjectDetailScreen extends ConsumerWidget {
  const SubjectDetailScreen({super.key, required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final subjectDef = SubjectConstants.bySlug(subject);
    final subjectIcon = subjectDef?.materialIcon ?? Icons.school_outlined;
    final displayName = subjectDef?.displayName ?? subject;

    final infoAsync = ref.watch(subjectInfoProvider(subject));
    final insightsAsync = ref.watch(subjectInsightsProvider(subject));

    final hPadding = AppBreakpoints.fullScreenHPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: hPadding,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  subject: subject,
                  displayName: displayName,
                  subjectIcon: subjectIcon,
                  borderColor: borderColor,
                  infoAsync: infoAsync,
                  insightsAsync: insightsAsync,
                  scheme: scheme,
                  isDark: isDark,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _PerformanceSummarySection(
                    subject: subject,
                    borderColor: borderColor,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _NewTestSection(
                    subject: subject,
                    displayName: displayName,
                    borderColor: borderColor,
                    infoAsync: infoAsync,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _PerformanceInsightsSection(
                    subject: subject,
                    displayName: displayName,
                    borderColor: borderColor,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _HistorySection(
                    subject: subject,
                    borderColor: borderColor,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Center(
                    child: ContactUsTextButton(
                      leadingText: context.l10n.subjFeedbackLead,
                      linkLabel: context.l10n.subjGetInTouch,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared section chrome ─────────────────────────────────────────────────────

class _ScreenSectionHeader extends StatelessWidget {
  const _ScreenSectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _SubjectPanel extends StatelessWidget {
  const _SubjectPanel({required this.borderColor, required this.child});

  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: child,
    );
  }
}

/// Mock-prep cards: warning tint (revise) vs success tint (safe).
class _MockPrepThemedPanel extends StatelessWidget {
  const _MockPrepThemedPanel({required this.isRevise, required this.child});

  final bool isRevise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isRevise) {
      final borderColor = isDark
          ? AppColors.wrongTextDark
          : AppColors.wrongText;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.wrongBgDark.withValues(alpha: 0.32)
              : AppColors.wrongBg.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor.withValues(alpha: isDark ? 0.52 : 0.46),
            width: 1,
          ),
        ),
        child: child,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.correctBgDark.withValues(alpha: 0.28)
            : AppColors.correctBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDark ? AppColors.correctTextDark : AppColors.correctText)
              .withValues(alpha: 0.32),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _SubjectInsightEmptyPanel extends StatelessWidget {
  const _SubjectInsightEmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
    required this.borderColor,
    this.accentTint,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color borderColor;

  /// When set, border and fill pick up warning (revise) or success (safe).
  final Color? accentTint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = accentTint;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tint != null
            ? tint.withValues(alpha: isDark ? 0.12 : 0.14)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: tint != null
              ? tint.withValues(alpha: 0.45)
              : borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: tint ?? scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
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

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({
    required this.subject,
    required this.displayName,
    required this.subjectIcon,
    required this.borderColor,
    required this.infoAsync,
    required this.insightsAsync,
    required this.scheme,
    required this.isDark,
  });

  final String subject;
  final String displayName;
  final IconData subjectIcon;
  final Color borderColor;
  final AsyncValue<SubjectInfo?> infoAsync;
  final AsyncValue<SubjectInsights> insightsAsync;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: scheme.onSurface,
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.2 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(subjectIcon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  displayName,
                  style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                ),
              ),
              Material(
                color: AppColors.transparent,
                child: InkWell(
                  onTap: () async {
                    await setDarkModeEnabled(
                      ref: ref,
                      darkModeEnabled: !isDark,
                    );
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: borderColor, width: 0.5),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'topics':
                      context.push(
                        '/subject/${Uri.encodeComponent(subject)}/topics',
                      );
                    case 'history':
                      context.push(
                        '/subject/${Uri.encodeComponent(subject)}/history',
                      );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'topics',
                    child: Text(
                      context.l10n.subjBrowseTopicsLower,
                      style: AppTextStyles.bodySm(),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'history',
                    child: Text('Test history', style: AppTextStyles.bodySm()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Practice Section ────────────────────────────────────────────────────────────

class _NewTestSection extends ConsumerWidget {
  const _NewTestSection({
    required this.subject,
    required this.displayName,
    required this.borderColor,
    required this.infoAsync,
  });

  final String subject;
  final String displayName;
  final Color borderColor;
  final AsyncValue<SubjectInfo?> infoAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = infoAsync.asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScreenSectionHeader(
          title: 'NEW TEST',
          subtitle: context.l10n.subjNewTestBody,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PracticeCard(
          icon: Icons.edit_note_rounded,
          iconColor: AppColors.primary,
          title: context.l10n.subjStartAndMark,
          subtitle: context.l10n.subjAllTopicsIn(displayName),
          borderColor: borderColor,
          isDark: isDark,
          onTap: () {
            if (info == null) return;
            showTestConfigBottomSheet(
              context: context,
              args: TestConfigSheetArgs(
                subject: subject,
                subjectDisplayName: displayName,
                availableQuestionCount: info.questionCount,
                topicCountWhenSubjectOnly: info.topicCount,
                onSessionCreated: (id) => context.push('/test/$id'),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _PracticeCard(
          icon: Icons.format_list_bulleted_rounded,
          iconColor: AppColors.info,
          title: context.l10n.subjBrowseTopics,
          subtitle: info != null
              ? context.l10n.subjPracticeTopicsCount(info.topicCount)
              : context.l10n.subjPracticeTopics,
          borderColor: borderColor,
          isDark: isDark,
          onTap: () =>
              context.push('/subject/${Uri.encodeComponent(subject)}/topics'),
        ),
      ],
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconBg = isDark
        ? iconColor.withValues(alpha: 0.22)
        : iconColor.withValues(alpha: 0.12);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── History hub (opens paginated subject history) ─────────────────────────────

class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.subject, required this.borderColor});

  final String subject;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countAsync = ref.watch(subjectCompletedSessionCountProvider(subject));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScreenSectionHeader(
          title: 'HISTORY',
          subtitle: context.l10n.subjHistoryBody,
        ),
        const SizedBox(height: AppSpacing.sm),
        countAsync.when(
          loading: () => Container(
            height: 72,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          error: (_, _) => _SubjectPanel(
            borderColor: borderColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.subjSessionCountFailed,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    subjectCompletedSessionCountProvider(subject),
                  ),
                  child: Text(
                    context.l10n.commonRetry,
                    style: AppTextStyles.label(),
                  ),
                ),
              ],
            ),
          ),
          data: (count) => _PracticeCard(
            icon: Icons.history_rounded,
            iconColor: AppColors.info,
            title: context.l10n.subjViewHistory,
            subtitle: count == 0
                ? context.l10n.subjNoSessionsYet
                : context.l10n.subjCompletedSessions(count),
            borderColor: borderColor,
            isDark: isDark,
            onTap: () => context.push(
              '/subject/${Uri.encodeComponent(subject)}/history',
            ),
          ),
        ),
      ],
    );
  }
}

/// Advice + danger-zone breakdown need at least one scored attempt marked
/// Sure or Educated guess in this subject.
bool _subjectHasConfidenceLabelsForInsights(SubjectScoredAccuracySummary s) =>
    s.sureTotal > 0 || s.educatedGuessTotal > 0;

class _PerformanceSummarySection extends ConsumerWidget {
  const _PerformanceSummarySection({
    required this.subject,
    required this.borderColor,
  });

  final String subject;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accuracyAsync = ref.watch(subjectScoredAccuracyProvider(subject));
    final scheme = Theme.of(context).colorScheme;

    return accuracyAsync.when(
      loading: () => const _SubjectStatsCardSkeleton(),
      error: (_, _) => _SubjectPanel(
        borderColor: borderColor,
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.subjStatsFailed,
                style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(subjectScoredAccuracyProvider(subject)),
              child: Text(
                context.l10n.commonRetry,
                style: AppTextStyles.label(),
              ),
            ),
          ],
        ),
      ),
      data: (summary) =>
          _SubjectScoredSummaryCard(summary: summary, borderColor: borderColor),
    );
  }
}

class _PerformanceInsightsSection extends ConsumerWidget {
  const _PerformanceInsightsSection({
    required this.subject,
    required this.displayName,
    required this.borderColor,
  });

  final String subject;
  final String displayName;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accuracyAsync = ref.watch(subjectScoredAccuracyProvider(subject));
    final insightsAsync = ref.watch(subjectInsightsProvider(subject));
    final mockPrepAsync = ref.watch(subjectMockPrepInsightsProvider(subject));
    final scheme = Theme.of(context).colorScheme;

    return accuracyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (summary) {
        final showInsightBlocks = _subjectHasConfidenceLabelsForInsights(
          summary,
        );

        if (!showInsightBlocks) {
          return Text(
            context.l10n.subjMarkHint,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            mockPrepAsync.when(
              loading: () => _MockPrepInsightsSkeleton(
                borderColor: borderColor,
                displayName: displayName,
              ),
              error: (e, _) => _MockPrepLoadError(
                borderColor: borderColor,
                onRetry: () =>
                    ref.invalidate(subjectMockPrepInsightsProvider(subject)),
              ),
              data: (mock) => _AdviceForSubjectMockPrepGroup(
                displayName: displayName,
                mock: mock,
                borderColor: borderColor,
                subject: subject,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            insightsAsync.when(
              loading: () => _InsightsSkeleton(borderColor: borderColor),
              error: (e, _) => _InsightsLoadError(
                borderColor: borderColor,
                onRetry: () => ref.invalidate(subjectInsightsProvider(subject)),
              ),
              data: (insights) => _ConfidenceBreakdownSection(
                subject: subject,
                displayName: displayName,
                borderColor: borderColor,
                insights: insights,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.subjStatsSharpen,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SubjectStatsCardSkeleton extends StatelessWidget {
  const _SubjectStatsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}

class _SubjectScoredSummaryCard extends StatelessWidget {
  const _SubjectScoredSummaryCard({
    required this.summary,
    required this.borderColor,
  });

  final SubjectScoredAccuracySummary summary;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.correctTextDark : AppColors.correctText;
    final fill = isDark
        ? AppColors.correctBgDark.withValues(alpha: 0.22)
        : AppColors.primaryLight;
    final hasAttempts = summary.scoredAttempted > 0;
    final accColor = isDark ? AppColors.correctTextDark : AppColors.correctText;
    final wrongStatColor = isDark
        ? AppColors.wrongTextDark
        : AppColors.wrongText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: border.withValues(alpha: isDark ? 0.45 : 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAttempts)
            Text(
              context.l10n.subjNoAttemptsYet,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            )
          else ...[
            Text.rich(
              TextSpan(
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurface,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '${summary.accuracyPercent!.round()}%',
                    style: TextStyle(
                      color: accColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: context.l10n.subjAccuracySuffix,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  ',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: '${summary.uniqueQuestionsAttempted}',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: context.l10n.subjMcqsAttempted,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _sureLine(summary, scheme, wrongStatColor),
            const SizedBox(height: AppSpacing.sm),
            _guessLine(summary, scheme, wrongStatColor),
          ],
        ],
      ),
    );
  }

  Widget _sureLine(
    SubjectScoredAccuracySummary s,
    ColorScheme scheme,
    Color wrongRed,
  ) {
    if (s.sureTotal == 0) {
      return Text(
        appL10n.subjSureNone,
        style: AppTextStyles.caption().copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      );
    }
    final pct = s.wrongWhenSurePercent!;
    final countColor = wrongRed.withValues(alpha: 0.92);
    return Text.rich(
      TextSpan(
        style: AppTextStyles.bodySm().copyWith(height: 1.35),
        children: [
          TextSpan(
            text: 'Sure → ',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          TextSpan(
            text: appL10n.commonWrongLower,
            style: TextStyle(color: wrongRed, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ': ',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          TextSpan(
            text: '${pct.round()}%',
            style: TextStyle(
              color: wrongRed,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          TextSpan(
            text: '  (${s.sureWrong}/${s.sureTotal})',
            style: TextStyle(color: countColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _guessLine(
    SubjectScoredAccuracySummary s,
    ColorScheme scheme,
    Color wrongRed,
  ) {
    if (s.educatedGuessTotal == 0) {
      return Text(
        appL10n.subjGuessNone,
        style: AppTextStyles.caption().copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      );
    }
    final pct = s.wrongWhenEducatedGuessPercent!;
    final countColor = wrongRed.withValues(alpha: 0.92);
    return Text.rich(
      TextSpan(
        style: AppTextStyles.bodySm().copyWith(height: 1.35),
        children: [
          TextSpan(
            text: 'Educated guess → ',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          TextSpan(
            text: appL10n.commonWrongLower,
            style: TextStyle(color: wrongRed, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ': ',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          TextSpan(
            text: '${pct.round()}%',
            style: TextStyle(
              color: wrongRed,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          TextSpan(
            text: '  (${s.educatedGuessWrong}/${s.educatedGuessTotal})',
            style: TextStyle(color: countColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBreakdownSection extends StatelessWidget {
  const _ConfidenceBreakdownSection({
    required this.subject,
    required this.displayName,
    required this.borderColor,
    required this.insights,
  });

  final String subject;
  final String displayName;
  final Color borderColor;
  final SubjectInsights insights;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const markWeight = 0.66;
    final sureWrong = insights.dangerZoneSureWrongCount;
    final guessWrong = insights.dangerZoneEducatedGuessWrongCount;
    final sureMarksStr = (sureWrong * markWeight).toStringAsFixed(2);
    final guessMarksStr = (guessWrong * markWeight).toStringAsFixed(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.subjBreakdownTitle,
          style: AppTextStyles.label().copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ConfidenceMiniCard(
                icon: Icons.bolt_rounded,
                iconColor: isDark ? AppColors.wrongTextDark : AppColors.wrong,
                title: context.l10n.dzSureWrong,
                count: sureWrong,
                marksLabel: context.l10n.dzApproxMarks(sureMarksStr),
                subtitle: context.l10n.dzSureWrongBody,
                background: isDark
                    ? AppColors.wrongBgDark.withValues(alpha: 0.35)
                    : AppColors.wrongBg,
                borderColor: borderColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ConfidenceMiniCard(
                icon: Icons.auto_awesome_outlined,
                iconColor: isDark
                    ? AppColors.warningTextDark
                    : AppColors.warningText,
                title: context.l10n.dzEduWrong,
                count: guessWrong,
                marksLabel: context.l10n.dzApproxMarks(guessMarksStr),
                subtitle: context.l10n.dzEduWrongBody,
                background: isDark
                    ? AppColors.warningBgDark.withValues(alpha: 0.35)
                    : AppColors.warningBg,
                borderColor: borderColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: insights.isWellCalibrated
              ? null
              : () => _openDangerZoneDetailSheet(
                  context,
                  subject: subject,
                  displayName: displayName,
                  borderColor: borderColor,
                  insights: insights,
                ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.summaryCtaBlue,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(
            insights.isWellCalibrated
                ? context.l10n.subjNoConfidentWrongs
                : context.l10n.subjReviseQuestions,
            style: AppTextStyles.label().copyWith(color: AppColors.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _ConfidenceMiniCard extends StatelessWidget {
  const _ConfidenceMiniCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.marksLabel,
    required this.subtitle,
    required this.background,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final String marksLabel;
  final String subtitle;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$count',
            style: AppTextStyles.h2().copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.05,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openTopicEntryFromRow(
  BuildContext context,
  WidgetRef ref, {
  required String subject,
  required String subjectDisplayName,
  required String topicKey,
  required String topicDisplayName,
}) async {
  try {
    final topics = await ref.read(subjectTopicsProvider(subject).future);
    TopicInfo? match;
    for (final t in topics) {
      if (t.topic == topicKey) {
        match = t;
        break;
      }
    }
    if (!context.mounted) return;
    if (match == null) {
      AppToast.showText(context, context.l10n.subjTopicNotFound);
      return;
    }
    if (!context.mounted) return;
    await showTopicEntryBottomSheet(
      context: context,
      subject: subject,
      topic: match.topic,
      subjectDisplayName: subjectDisplayName,
      topicDisplayName: match.displayName,
      availableQuestionCount: match.questionCount,
      onTestSessionCreated: (id) => context.push('/test/$id'),
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.showText(
        context,
        context.l10n.subjTopicOpenFailed(e.toString()),
      );
    }
  }
}

void _openDangerZoneDetailSheet(
  BuildContext context, {
  required String subject,
  required String displayName,
  required Color borderColor,
  required SubjectInsights insights,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final bottomPad = MediaQuery.paddingOf(sheetContext).bottom;
      final maxBodyHeight = MediaQuery.sizeOf(sheetContext).height * 0.82;

      return Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl + 4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: scheme.onSurface,
                      tooltip: context.l10n.commonBack,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.subjReviseMcqs,
                            style: AppTextStyles.label().copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayName,
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxBodyHeight),
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    DangerZoneSummaryCard(
                      dangerZoneContextLabel: displayName,
                      subject: subject,
                      insights: insights,
                      borderColor: borderColor,
                      onLearningSessionStarted: (sessionId) {
                        Navigator.pop(sheetContext);
                        if (context.mounted) {
                          context.push('/test/$sessionId');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

bool _mockPrepHasTopicLists(SubjectMockPrepInsights m) =>
    m.hasReviseData || m.hasSafeData;

/// Mock-prep revise + safe cards grouped under one subject-scoped heading.
class _AdviceForSubjectMockPrepGroup extends StatefulWidget {
  const _AdviceForSubjectMockPrepGroup({
    required this.displayName,
    required this.mock,
    required this.borderColor,
    required this.subject,
  });

  final String displayName;
  final String subject;
  final SubjectMockPrepInsights mock;
  final Color borderColor;

  @override
  State<_AdviceForSubjectMockPrepGroup> createState() =>
      _AdviceForSubjectMockPrepGroupState();
}

class _AdviceForSubjectMockPrepGroupState
    extends State<_AdviceForSubjectMockPrepGroup>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _expanded = _mockPrepHasTopicLists(widget.mock);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _AdviceForSubjectMockPrepGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    final had = _mockPrepHasTopicLists(oldWidget.mock);
    final has = _mockPrepHasTopicLists(widget.mock);
    if (had && !has) {
      setState(() => _expanded = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final adviceTitle = context.l10n.subjAdviceFor(
      widget.displayName.toUpperCase(),
    );
    final hasLists = _mockPrepHasTopicLists(widget.mock);
    final subtitle = hasLists
        ? context.l10n.subjAdviceSubtitle
        : context.l10n.subjAdviceEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ScreenSectionHeader(
                      title: adviceTitle,
                      subtitle: subtitle,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              final reviseTab = _tabController.index == 0;
              return TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
                dividerHeight: 1,
                indicatorColor: reviseTab ? AppColors.wrong : AppColors.correct,
                indicatorWeight: 2.5,
                labelColor: scheme.onSurface,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(text: context.l10n.mockReviseTitle),
                  Tab(text: context.l10n.mockSafeTitle),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              return _tabController.index == 0
                  ? _ReviseBeforeNextMockCard(
                      subject: widget.subject,
                      subjectDisplayName: widget.displayName,
                      mock: widget.mock,
                      borderColor: widget.borderColor,
                    )
                  : _MockSafeAreasCard(
                      subject: widget.subject,
                      subjectDisplayName: widget.displayName,
                      mock: widget.mock,
                      borderColor: widget.borderColor,
                    );
            },
          ),
        ],
      ],
    );
  }
}

// ── Mock prep: Revise (30d) + Safe confident topics ───────────────────────────

const int _mockPrepTopicPreviewMax = 5;

class _ReviseBeforeNextMockCard extends StatelessWidget {
  const _ReviseBeforeNextMockCard({
    required this.subject,
    required this.subjectDisplayName,
    required this.mock,
    required this.borderColor,
  });

  final String subject;
  final String subjectDisplayName;
  final SubjectMockPrepInsights mock;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    final divider = accent.withValues(alpha: 0.2);
    final previewRows = mock.reviseTopics
        .take(_mockPrepTopicPreviewMax)
        .toList();

    return _MockPrepThemedPanel(
      isRevise: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 22, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.mockReviseTitle,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.subjReviseTopicsIntro,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _WhyTheseTopicsTile(isRevise: true, borderColor: borderColor),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.subjTopicsToRevise,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!mock.hasReviseData)
            _SubjectInsightEmptyPanel(
              icon: Icons.fact_check_outlined,
              title: context.l10n.subjNoTopicsToList,
              body: context.l10n.subjNoTopicsBody,
              borderColor: borderColor,
              accentTint: accent,
            )
          else ...[
            for (var i = 0; i < previewRows.length; i++) ...[
              if (i > 0)
                Divider(height: AppSpacing.lg, color: divider, thickness: 0.5),
              _ReviseBeforeMockRowWidget(
                subject: subject,
                subjectDisplayName: subjectDisplayName,
                row: previewRows[i],
                statColor: accent,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WhyTheseTopicsTile extends StatelessWidget {
  const _WhyTheseTopicsTile({
    required this.isRevise,
    required this.borderColor,
  });

  final bool isRevise;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.infoBgDark.withValues(alpha: 0.35)
        : AppColors.infoBg;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => showMockPrepWhyBottomSheet(context, isRevise: isRevise),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.subjWhyTopics,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviseBeforeMockRowWidget extends ConsumerWidget {
  const _ReviseBeforeMockRowWidget({
    required this.subject,
    required this.subjectDisplayName,
    required this.row,
    required this.statColor,
  });

  final String subject;
  final String subjectDisplayName;
  final ReviseBeforeMockRow row;
  final Color statColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.subjSureEduWrong(
                  row.sureWrong,
                  row.educatedGuessWrong,
                ),
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: statColor,
            side: BorderSide(color: statColor.withValues(alpha: 0.85)),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          onPressed: () => _openTopicEntryFromRow(
            context,
            ref,
            subject: subject,
            subjectDisplayName: subjectDisplayName,
            topicKey: row.topicKey,
            topicDisplayName: row.displayName,
          ),
          child: Text(
            context.l10n.subjRevisitTopic,
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockSafeAreasCard extends StatelessWidget {
  const _MockSafeAreasCard({
    required this.subject,
    required this.subjectDisplayName,
    required this.mock,
    required this.borderColor,
  });

  final String subject;
  final String subjectDisplayName;
  final SubjectMockPrepInsights mock;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.correctTextDark : AppColors.correctText;
    final divider = accent.withValues(alpha: 0.2);
    final previewRows = mock.safeTopics.take(_mockPrepTopicPreviewMax).toList();

    return _MockPrepThemedPanel(
      isRevise: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, size: 22, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.mockSafeTitle,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.subjSafeIntro,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _WhyTheseTopicsTile(isRevise: false, borderColor: borderColor),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.subjSafeTopics,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!mock.hasSafeData)
            _SubjectInsightEmptyPanel(
              icon: mock.globalConfidentRatePercent == null
                  ? Icons.hourglass_empty_outlined
                  : Icons.insights_outlined,
              title: mock.globalConfidentRatePercent == null
                  ? context.l10n.subjBaselineNotReady
                  : context.l10n.subjNoTopicsQualify,
              body: mock.globalConfidentRatePercent == null
                  ? context.l10n.subjBaselineBody
                  : context.l10n.subjNoQualifyBody,
              borderColor: borderColor,
              accentTint: accent,
            )
          else ...[
            for (var i = 0; i < previewRows.length; i++) ...[
              if (i > 0)
                Divider(height: AppSpacing.lg, color: divider, thickness: 0.5),
              _MockSafeAreaRow(
                subject: subject,
                subjectDisplayName: subjectDisplayName,
                row: previewRows[i],
                statColor: accent,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MockSafeAreaRow extends ConsumerWidget {
  const _MockSafeAreaRow({
    required this.subject,
    required this.subjectDisplayName,
    required this.row,
    required this.statColor,
  });

  final String subject;
  final String subjectDisplayName;
  final SafeAreaRow row;
  final Color statColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.subjConfidentRate(
                  row.ratePercent.toStringAsFixed(1),
                  row.globalRatePercent.toStringAsFixed(1),
                ),
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: statColor,
            side: BorderSide(color: statColor.withValues(alpha: 0.85)),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => _openTopicEntryFromRow(
            context,
            ref,
            subject: subject,
            subjectDisplayName: subjectDisplayName,
            topicKey: row.topicKey,
            topicDisplayName: row.displayName,
          ),
          child: Text(
            context.l10n.subjAttemptMore,
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockPrepLoadError extends StatelessWidget {
  const _MockPrepLoadError({required this.borderColor, required this.onRetry});

  final Color borderColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SubjectPanel(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.subjMockPrepFailed,
            style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry, style: AppTextStyles.label()),
          ),
        ],
      ),
    );
  }
}

class _MockPrepInsightsSkeleton extends StatelessWidget {
  const _MockPrepInsightsSkeleton({
    required this.borderColor,
    required this.displayName,
  });

  final Color borderColor;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ScreenSectionHeader(
                title: context.l10n.subjAdviceFor(displayName.toUpperCase()),
                subtitle: context.l10n.subjAdviceSubtitle,
              ),
            ),
            Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Helpers ──────────────────────────────────────────────────────────────

class _InsightsLoadError extends StatelessWidget {
  const _InsightsLoadError({required this.borderColor, required this.onRetry});

  final Color borderColor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SubjectPanel(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.subjInsightsFailed,
            style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry, style: AppTextStyles.label()),
          ),
        ],
      ),
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}
