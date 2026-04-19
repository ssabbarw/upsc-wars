import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/session_summary.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/accuracy_percentage_text.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../../shared/widgets/test_config_bottom_sheet.dart';
import '../../history/providers/history_filters_provider.dart';
import '../domain/subject_insights.dart';
import '../providers/subject_detail_providers.dart';
import '../providers/subject_insights_providers.dart';

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
    final historyAsync = ref.watch(subjectHistoryProvider(subject));

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
                  AppSpacing.xxl,
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
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  0,
                ),
                child: _HistorySection(
                  historyAsync: historyAsync,
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
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  0,
                ),
                child: _InsightsSection(
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
                child: const Center(child: ContactUsTextButton()),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
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
              const SizedBox(height: AppSpacing.xs),
              if (!hasAttempts)
                Text(
                  'No practice yet — start your first test!',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                AccuracyPercentageText(
                  attemptCount: info.attemptCount,
                  accuracyPercent: info.accuracyPercent,
                  tier: info.accuracyTier,
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = infoAsync.asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRACTICE',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
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

// ── History Section ─────────────────────────────────────────────────────────────

class _HistorySection extends ConsumerWidget {
  const _HistorySection({
    required this.historyAsync,
    required this.subject,
    required this.displayName,
    required this.borderColor,
    required this.infoAsync,
  });

  final AsyncValue<List<SessionSummary>> historyAsync;
  final String subject;
  final String displayName;
  final Color borderColor;
  final AsyncValue<SubjectInfo?> infoAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TEST HISTORY',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        historyAsync.when(
          loading: () => _HistorySkeleton(borderColor: borderColor),
          error: (_, _) => Text(
            'Could not load history.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return _HistoryEmpty(
                subject: subject,
                displayName: displayName,
                infoAsync: infoAsync,
                borderColor: borderColor,
              );
            }
            final visible = sessions.take(10).toList();
            return Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.cardListGap),
                  _SessionRow(session: visible[i], borderColor: borderColor),
                ],
                if (sessions.length > 10) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      '+ ${sessions.length - 10} more sessions',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({
    required this.subject,
    required this.displayName,
    required this.infoAsync,
    required this.borderColor,
  });

  final String subject;
  final String displayName;
  final AsyncValue<SubjectInfo?> infoAsync;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = infoAsync.asData?.value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_outlined,
            size: 32,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No test history yet.',
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start a test to see your results here.',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: info == null
                ? null
                : () {
                    if (!context.mounted) return;
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
            child: Text('Start a test', style: AppTextStyles.label()),
          ),
        ],
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.cardListGap),
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.borderColor});

  final SessionSummary session;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLearning = session.mode == 'learning';
    final modeLabel = isLearning ? 'Learning' : 'Exam';
    final modeColor = isLearning ? AppColors.primary : AppColors.info;
    final modeBg = isLearning ? AppColors.correctBg : AppColors.infoBg;

    final accuracy = session.accuracy;
    final correct = session.correct;
    final total = session.questionCount;
    final scoreText = accuracy != null && correct != null
        ? '$correct/$total correct · ${accuracy.toStringAsFixed(0)}%'
        : '$total questions';

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => context.push('/history/${session.sessionId}'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: modeBg,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            modeLabel,
                            style: AppTextStyles.caption().copyWith(
                              color: modeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _relativeDate(session.createdAt),
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      scoreText,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (session.topic != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        session.topic!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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

  String _relativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('d MMM y').format(dt);
  }
}

// ── Insights Section ────────────────────────────────────────────────────────────

class _InsightsSection extends ConsumerWidget {
  const _InsightsSection({required this.subject, required this.borderColor});

  final String subject;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final insightsAsync = ref.watch(subjectInsightsProvider(subject));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INSIGHTS',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        insightsAsync.when(
          loading: () => _InsightsSkeleton(borderColor: borderColor),
          error: (e, _) => _InsightsLoadError(
            borderColor: borderColor,
            onRetry: () => ref.invalidate(subjectInsightsProvider(subject)),
          ),
          data: (insights) => Column(
            children: [
              _DangerZoneSummaryCard(
                subject: subject,
                insights: insights,
                borderColor: borderColor,
              ),
              const SizedBox(height: AppSpacing.sm),
              _TopicPercentileCard(
                insights: insights,
                borderColor: borderColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Card 1: Danger Zone summary (30 days) ───────────────────────────────────────

class _DangerZoneSummaryCard extends ConsumerWidget {
  const _DangerZoneSummaryCard({
    required this.subject,
    required this.insights,
    required this.borderColor,
  });

  final String subject;
  final SubjectInsights insights;
  final Color borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = insights.dangerZoneCountLast30Days;
    final calm = insights.isWellCalibratedThisMonth;

    final (accent, bg) = calm
        ? (
            isDark ? AppColors.correctTextDark : AppColors.correctText,
            isDark ? AppColors.correctBgDark : AppColors.correctBg,
          )
        : (
            isDark ? AppColors.wrongTextDark : AppColors.wrongText,
            isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
          );

    // Rounded corners require a uniform border color on BoxDecoration; the
    // left accent is drawn separately so we keep the same look without the
    // framework assertion.
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
                    'Danger Zone',
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Confidently wrong (last 30 days)',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: calm
                            ? Text(
                                '🟢 Well calibrated this month',
                                style: AppTextStyles.bodyMd().copyWith(
                                  color: scheme.onSurface,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚠️ $count Danger Zone question${count == 1 ? '' : 's'}',
                                    style: AppTextStyles.bodyMd().copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Would cost ${insights.dangerZoneMarksLast30.toStringAsFixed(2)} marks',
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (!calm)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.h2().copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!calm) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          ref
                              .read(historyFilterStateProvider.notifier)
                              .setSubject(subject);
                          context.push('/history');
                        },
                        child: Text(
                          'Review all in History',
                          style: AppTextStyles.label(),
                        ),
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

// ── Card 2: Topic risk (percentile bands, 30 days) ─────────────────────────────

class _TopicPercentileCard extends StatelessWidget {
  const _TopicPercentileCard({
    required this.insights,
    required this.borderColor,
  });
  final SubjectInsights insights;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topic Risk Ranking',
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Where you are confidently wrong lately (percentile bands)',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!insights.hasTopicData)
            const _InsightsEmptyHint(
              message: 'No Danger Zone data by topic in the last 30 days yet.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < insights.topicPercentiles.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AppSpacing.lg,
                      color: borderColor,
                      thickness: 0.5,
                    ),
                  _TopicPercentileRow(row: insights.topicPercentiles[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TopicPercentileRow extends StatelessWidget {
  const _TopicPercentileRow({required this.row});
  final TopicPercentileRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(row.tier.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            row.topic,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${row.dangerCount} · ${row.tier.label}',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 0.5),
      ),
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

class _InsightsEmptyHint extends StatelessWidget {
  const _InsightsEmptyHint({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      message,
      style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Container(
            height: i == 0 ? 100 : 140,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ],
      ],
    );
  }
}
