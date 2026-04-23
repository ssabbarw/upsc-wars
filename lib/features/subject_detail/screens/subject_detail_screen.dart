import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../domain/subject_mock_prep_insights.dart';
import '../domain/subject_scored_accuracy_summary.dart';
import '../providers/subject_detail_providers.dart';
import '../providers/subject_insights_providers.dart';
import '../providers/subject_mock_prep_provider.dart';
import '../providers/subject_scored_accuracy_provider.dart';
import '../widgets/danger_zone_summary_card.dart';
import '../widgets/mock_prep_why_bottom_sheet.dart';

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

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
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
                scheme: scheme,
                isDark: isDark,
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
                child: _PracticeSection(
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
                child: _HistoryHubSection(
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
                child: _InsightsSection(
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
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: const Center(
                  child: ContactUsTextButton(leadingText: 'Any questions? '),
                ),
              ),
            ),
          ],
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.warningBgDark.withValues(alpha: 0.35)
              : AppColors.warningBg.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: (isDark ? AppColors.warningTextDark : AppColors.warningText)
                .withValues(alpha: 0.38),
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
    required this.scheme,
    required this.isDark,
  });

  final String subject;
  final String displayName;
  final IconData subjectIcon;
  final Color borderColor;
  final AsyncValue<SubjectInfo?> infoAsync;
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
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          infoAsync.when(
            loading: () => _HeaderStatsSkeleton(borderColor: borderColor),
            error: (_, _) => const SizedBox.shrink(),
            data: (info) => info == null
                ? const SizedBox.shrink()
                : _HeaderStats(info: info, borderColor: borderColor),
          ),
        ],
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.info, required this.borderColor});
  final SubjectInfo info;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasAttempts = info.attemptCount > 0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${info.topicCount} topics',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (hasAttempts) ...[
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _accuracyBg(info.accuracyPercent),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${(info.accuracyPercent ?? 0).toStringAsFixed(0)}% accuracy',
              style: AppTextStyles.caption().copyWith(
                color: _accuracyFg(info.accuracyPercent),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _accuracyBg(double? pct) {
    if (pct == null) return AppColors.gray100;
    if (pct >= 75) return AppColors.correctBg;
    if (pct >= 50) return AppColors.warningBg;
    return AppColors.wrongBg;
  }

  Color _accuracyFg(double? pct) {
    if (pct == null) return AppColors.gray600;
    if (pct >= 75) return AppColors.correctText;
    if (pct >= 50) return AppColors.warningText;
    return AppColors.wrongText;
  }
}

class _HeaderStatsSkeleton extends StatelessWidget {
  const _HeaderStatsSkeleton({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 140,
          height: 14,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          width: 90,
          height: 24,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ],
    );
  }
}

// ── Practice Section ────────────────────────────────────────────────────────────

class _PracticeSection extends ConsumerWidget {
  const _PracticeSection({
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
        const _ScreenSectionHeader(
          title: 'PRACTICE',
          subtitle:
              'Start a test across the full subject, or open a specific topic.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _PracticeCard(
          icon: Icons.shuffle_rounded,
          iconColor: AppColors.primary,
          title: 'Start a test',
          subtitle: 'Questions from all topics in $displayName',
          isPrimary: true,
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
          title: 'Browse Topics',
          subtitle: info != null
              ? 'Practice specific topics (${info.topicCount} topics)'
              : 'Practice specific topics',
          isPrimary: false,
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
    required this.isPrimary,
    required this.borderColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isPrimary;
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
            border: Border.all(
              color: isPrimary ? AppColors.primary : borderColor,
              width: isPrimary ? 1.5 : 0.5,
            ),
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

class _HistoryHubSection extends ConsumerWidget {
  const _HistoryHubSection({required this.subject, required this.borderColor});

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
        const _ScreenSectionHeader(
          title: 'TEST HISTORY',
          subtitle: 'List of Completed sessions for this subject.',
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
                    'Could not load session count.',
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
                  child: Text('Retry', style: AppTextStyles.label()),
                ),
              ],
            ),
          ),
          data: (count) => _PracticeCard(
            icon: Icons.history_rounded,
            iconColor: AppColors.info,
            title: 'View test history',
            subtitle: count == 0
                ? 'No completed sessions yet'
                : '$count completed session${count == 1 ? '' : 's'} · paginated',
            isPrimary: false,
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

// ── Subject accuracy + Sure calibration (under INSIGHTS) ─────────────────────

class _SubjectAccuracyInsightsStrip extends StatelessWidget {
  const _SubjectAccuracyInsightsStrip({
    required this.summary,
    required this.borderColor,
  });

  final SubjectScoredAccuracySummary summary;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sureLabel = AnswerConfidence.examShortLabel(
      AnswerConfidence.verySure,
    );
    final guessLabel = AnswerConfidence.examShortLabel(
      AnswerConfidence.somewhatSure,
    );

    final String line1;
    if (summary.scoredAttempted == 0) {
      line1 = '📊 No scored data yet — finish a test to populate this.';
    } else {
      final acc = summary.accuracyPercent!;
      line1 =
          '📊 ${summary.scoredAttempted} Attemped · ${acc.round()}% accuracy ';
    }

    final String line2;
    if (summary.sureTotal == 0) {
      line2 = '⚡ $sureLabel — not used yet';
    } else {
      final pct = summary.wrongWhenSurePercent!.round();
      line2 =
          '⚡ $sureLabel → $pct% wrong '
          '(${summary.sureWrong}/${summary.sureTotal})';
    }

    final String line3;
    if (summary.educatedGuessTotal == 0) {
      line3 = '🧠 $guessLabel — not used yet';
    } else {
      final pct = summary.wrongWhenEducatedGuessPercent!.round();
      line3 =
          '🧠 $guessLabel → $pct% wrong '
          '(${summary.educatedGuessWrong}/${summary.educatedGuessTotal})';
    }

    return _SubjectPanel(
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line1,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            line2,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            line3,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insights Section ────────────────────────────────────────────────────────────

class _InsightsSection extends ConsumerWidget {
  const _InsightsSection({
    required this.subject,
    required this.displayName,
    required this.borderColor,
  });

  final String subject;
  final String displayName;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(subjectInsightsProvider(subject));
    final mockPrepAsync = ref.watch(subjectMockPrepInsightsProvider(subject));
    final accuracyAsync = ref.watch(subjectScoredAccuracyProvider(subject));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScreenSectionHeader(
          title: 'INSIGHTS FROM $displayName',
          subtitle: 'Keep attempting more questions to get better insights.',
        ),
        const SizedBox(height: AppSpacing.sm),
        accuracyAsync.when(
          loading: () => Container(
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          error: (e, _) => _SubjectPanel(
            borderColor: borderColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '⚠️ Could not load accuracy.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(subjectScoredAccuracyProvider(subject)),
                  child: Text('Retry', style: AppTextStyles.label()),
                ),
              ],
            ),
          ),
          data: (summary) => _SubjectAccuracyInsightsStrip(
            summary: summary,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        insightsAsync.when(
          loading: () => _InsightsSkeleton(borderColor: borderColor),
          error: (e, _) => _InsightsLoadError(
            borderColor: borderColor,
            onRetry: () => ref.invalidate(subjectInsightsProvider(subject)),
          ),
          data: (insights) => DangerZoneSummaryCard(
            dangerZoneContextLabel: displayName,
            subject: subject,
            insights: insights,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '📈 More scored answers → sharper stats here',
          style: AppTextStyles.caption().copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Mock-prep revise + safe cards grouped under one subject-scoped heading.
class _AdviceForSubjectMockPrepGroup extends StatefulWidget {
  const _AdviceForSubjectMockPrepGroup({
    required this.displayName,
    required this.mock,
    required this.borderColor,
  });

  final String displayName;
  final SubjectMockPrepInsights mock;
  final Color borderColor;

  @override
  State<_AdviceForSubjectMockPrepGroup> createState() =>
      _AdviceForSubjectMockPrepGroupState();
}

class _AdviceForSubjectMockPrepGroupState
    extends State<_AdviceForSubjectMockPrepGroup>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final TabController _tabController;
  late final ScrollController _reviseScrollController;
  late final ScrollController _safeScrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reviseScrollController = ScrollController();
    _safeScrollController = ScrollController();
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _expanded) {
        _scheduleNudgeForCurrentTab();
      }
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _scheduleNudgeForCurrentTab();
  }

  void _scheduleNudgeForCurrentTab() {
    if (!_expanded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _tabController.index == 0
          ? _reviseScrollController
          : _safeScrollController;
      unawaited(_nudgeScrollIfScrollable(c));
    });
  }

  Future<void> _nudgeScrollIfScrollable(ScrollController c) async {
    if (!c.hasClients) return;
    final max = c.position.maxScrollExtent;
    if (max < 16) return;
    final delta = (max * 0.14).clamp(10.0, 48.0);
    try {
      await c.animateTo(
        delta,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
      if (!mounted || !c.hasClients) return;
      await c.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      // Controller disposed mid-animation.
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _reviseScrollController.dispose();
    _safeScrollController.dispose();
    super.dispose();
  }

  double _tabViewHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.40;
    return h.clamp(260.0, 460.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final adviceTitle = 'ADVICE FOR ${widget.displayName.toUpperCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.xxl),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded) {
                _scheduleNudgeForCurrentTab();
              }
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ScreenSectionHeader(
                      title: adviceTitle,
                      subtitle:
                          'Mock prep: where to revise vs where confident play is strong.',
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
          const SizedBox(height: AppSpacing.sm),
          _SubjectPanel(
            borderColor: widget.borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Revise'),
                    Tab(text: 'Safe areas'),
                  ],
                ),
                SizedBox(
                  height: _tabViewHeight(context),
                  child: TabBarView(
                    controller: _tabController,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      _ReviseBeforeNextMockCard(
                        mock: widget.mock,
                        borderColor: widget.borderColor,
                        scrollController: _reviseScrollController,
                      ),
                      _MockSafeAreasCard(
                        mock: widget.mock,
                        borderColor: widget.borderColor,
                        scrollController: _safeScrollController,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Mock prep: Revise (30d) + Safe confident topics ───────────────────────────

class _MockPrepSubheading extends StatelessWidget {
  const _MockPrepSubheading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTextStyles.caption().copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Advice plus inline "Read why?" in the same text flow (same line when width allows).
class _MockPrepReadWhyLine extends StatelessWidget {
  const _MockPrepReadWhyLine({required this.sentence, required this.isRevise});

  final String sentence;
  final bool isRevise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = AppTextStyles.caption().copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    final linkStyle = AppTextStyles.caption().copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      height: 1.4,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );
    final textBeforeLink = sentence.trim().endsWith(' ')
        ? sentence.trim()
        : '${sentence.trim()} ';

    return Text.rich(
      TextSpan(
        style: bodyStyle,
        children: [
          TextSpan(text: textBeforeLink),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () =>
                  showMockPrepWhyBottomSheet(context, isRevise: isRevise),
              child: Text('Read why?', style: linkStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviseBeforeNextMockCard extends StatelessWidget {
  const _ReviseBeforeNextMockCard({
    required this.mock,
    required this.borderColor,
    required this.scrollController,
  });

  final SubjectMockPrepInsights mock;
  final Color borderColor;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.warningTextDark : AppColors.warningText;
    final divider = accent.withValues(alpha: 0.2);

    return _MockPrepThemedPanel(
      isRevise: true,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Revise Before Your Next Mock',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('Advice'),
          _MockPrepReadWhyLine(
            sentence:
                'You are likely to lose marks here due to overconfidence '
                'and risky guessing.',
            isRevise: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('Topics to revise'),
          const SizedBox(height: AppSpacing.xs),
          if (!mock.hasReviseData)
            _SubjectInsightEmptyPanel(
              icon: Icons.fact_check_outlined,
              title: 'No topics to list',
              body:
                  'No topic in this subject has enough wrong answers marked '
                  '“Very sure” or “Somewhat sure” to show here yet. As that '
                  'pattern shows up, you will see it broken down by type of '
                  'confidence.',
              borderColor: borderColor,
              accentTint: accent,
            )
          else ...[
            for (var i = 0; i < mock.reviseTopics.length; i++) ...[
              if (i > 0)
                Divider(height: AppSpacing.lg, color: divider, thickness: 0.5),
              _ReviseBeforeMockRowWidget(
                row: mock.reviseTopics[i],
                statColor: accent,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReviseBeforeMockRowWidget extends StatelessWidget {
  const _ReviseBeforeMockRowWidget({
    required this.row,
    required this.statColor,
  });

  final ReviseBeforeMockRow row;
  final Color statColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          'Sure: ${row.sureWrong} wrong'
          ' · Educated guess: ${row.educatedGuessWrong} wrong',
          style: AppTextStyles.caption().copyWith(
            color: statColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MockSafeAreasCard extends StatelessWidget {
  const _MockSafeAreasCard({
    required this.mock,
    required this.borderColor,
    required this.scrollController,
  });

  final SubjectMockPrepInsights mock;
  final Color borderColor;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.correctTextDark : AppColors.correctText;
    final divider = accent.withValues(alpha: 0.2);

    return _MockPrepThemedPanel(
      isRevise: false,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, size: 20, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Safe Areas for Higher Attempts',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('Advice'),
          _MockPrepReadWhyLine(
            sentence:
                'You can trust your judgment more in these topics during mocks.',
            isRevise: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('List of Topics'),
          if (!mock.hasSafeData)
            _SubjectInsightEmptyPanel(
              icon: mock.globalConfidentRatePercent == null
                  ? Icons.hourglass_empty_outlined
                  : Icons.insights_outlined,
              title: mock.globalConfidentRatePercent == null
                  ? 'Baseline not ready'
                  : 'No topics qualify yet',
              body: mock.globalConfidentRatePercent == null
                  ? 'We need a solid sample of scored answers where you were '
                        'very or somewhat sure. Keep using confidence on tests so '
                        'we can set your global rate and list topics that beat it.'
                  : 'In this subject, no topic is clearly above your overall '
                        'confident-correct rate yet. The list will update as you '
                        'add more very sure or somewhat sure attempts.',
              borderColor: borderColor,
              accentTint: accent,
            )
          else ...[
            for (var i = 0; i < mock.safeTopics.length; i++) ...[
              if (i > 0)
                Divider(height: AppSpacing.lg, color: divider, thickness: 0.5),
              _MockSafeAreaRow(row: mock.safeTopics[i], statColor: accent),
            ],
          ],
        ],
      ),
    );
  }
}

class _MockSafeAreaRow extends StatelessWidget {
  const _MockSafeAreaRow({required this.row, required this.statColor});

  final SafeAreaRow row;
  final Color statColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          'When confident: ${row.ratePercent.toStringAsFixed(1)}% right'
          ' · Your overall: ${row.globalRatePercent.toStringAsFixed(1)}%',
          style: AppTextStyles.caption().copyWith(
            color: statColor,
            fontWeight: FontWeight.w500,
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
            'Could not load mock-prep tips.',
            style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            child: Text('Retry', style: AppTextStyles.label()),
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
                title: 'ADVICE FOR ${displayName.toUpperCase()}',
                subtitle:
                    'Mock prep: where to revise vs where confident play is strong.',
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
            'Could not load insights.',
            style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: onRetry,
            child: Text('Retry', style: AppTextStyles.label()),
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
