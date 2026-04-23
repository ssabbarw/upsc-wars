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
import '../domain/subject_mock_prep_insights.dart';
import '../providers/subject_detail_providers.dart';
import '../providers/subject_insights_providers.dart';
import '../providers/subject_mock_prep_provider.dart';
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

// ── Shared section chrome ─────────────────────────────────────────────────────

class _ScreenSectionHeader extends StatelessWidget {
  const _ScreenSectionHeader({
    required this.title,
    this.subtitle,
  });

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
  const _SubjectPanel({
    required this.borderColor,
    required this.child,
  });

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
  const _MockPrepThemedPanel({
    required this.isRevise,
    required this.child,
  });

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
          color:
              (isDark ? AppColors.correctTextDark : AppColors.correctText)
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
          Icon(
            icon,
            size: 22,
            color: tint ?? scheme.onSurfaceVariant,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = infoAsync.asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScreenSectionHeader(
          title: 'PRACTICE',
          subtitle: 'Start a test across the full subject, or open a specific topic.',
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
        const _ScreenSectionHeader(
          title: 'TEST HISTORY',
          subtitle: 'Recent learning and exam sessions for this subject.',
        ),
        const SizedBox(height: AppSpacing.sm),
        historyAsync.when(
          loading: () => _HistorySkeleton(borderColor: borderColor),
          error: (_, _) => _HistoryLoadError(
            borderColor: borderColor,
            scheme: scheme,
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

class _HistoryLoadError extends StatelessWidget {
  const _HistoryLoadError({
    required this.borderColor,
    required this.scheme,
  });

  final Color borderColor;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return _SubjectPanel(
      borderColor: borderColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'We could not load your test history. Try again in a moment.',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScreenSectionHeader(
          title: 'INSIGHTS',
          subtitle: 'Last 30 days, danger zone, and mock prep. A topic is never '
              'in both mock cards: all-time confident wrongs are compared to '
              'confident rights; if equal, we keep it under Revise.',
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
          loading: () => _MockPrepInsightsSkeleton(borderColor: borderColor),
          error: (e, _) => _MockPrepLoadError(
            borderColor: borderColor,
            onRetry: () =>
                ref.invalidate(subjectMockPrepInsightsProvider(subject)),
          ),
          data: (mock) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviseBeforeNextMockCard(
                mock: mock,
                borderColor: borderColor,
              ),
              const SizedBox(height: AppSpacing.sm),
              _MockSafeAreasCard(
                mock: mock,
                borderColor: borderColor,
              ),
            ],
          ),
        ),
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
  const _MockPrepReadWhyLine({
    required this.sentence,
    required this.isRevise,
    required this.mock,
  });

  final String sentence;
  final bool isRevise;
  final SubjectMockPrepInsights mock;

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
              onTap: () => showMockPrepWhyBottomSheet(
                context,
                isRevise: isRevise,
                globalMistakeRatePercent: mock.globalConfidentMistakeRatePercent,
                globalReliableRatePercent: mock.globalConfidentRatePercent,
              ),
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
  });

  final SubjectMockPrepInsights mock;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.warningTextDark : AppColors.warningText;
    final divider = accent.withValues(alpha: 0.2);

    return _MockPrepThemedPanel(
      isRevise: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Revise Before Your Next Mock',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('Advice'),
          _MockPrepReadWhyLine(
            sentence: 'You are likely to lose marks here due to overconfidence '
                'and risky guessing.',
            isRevise: true,
            mock: mock,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Data window: last 30 days',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('Action item'),
          if (!mock.hasReviseData)
            _SubjectInsightEmptyPanel(
              icon: Icons.fact_check_outlined,
              title: 'No topics to list',
              body:
                  'In the last 30 days, no topic in this subject has enough '
                  'wrong answers marked “Very sure” or “Somewhat sure” to '
                  'show here. As that pattern shows up, you will see it broken '
                  'down by type of confidence.',
              borderColor: borderColor,
              accentTint: accent,
            )
          else
            Column(
              children: [
                for (var i = 0; i < mock.reviseTopics.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AppSpacing.lg,
                      color: divider,
                      thickness: 0.5,
                    ),
                  _ReviseBeforeMockRowWidget(
                    row: mock.reviseTopics[i],
                    statColor: accent,
                  ),
                ],
              ],
            ),
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
  });

  final SubjectMockPrepInsights mock;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.correctTextDark : AppColors.correctText;
    final divider = accent.withValues(alpha: 0.2);

    return _MockPrepThemedPanel(
      isRevise: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Safe Areas for Higher Attempts',
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('Advice'),
          _MockPrepReadWhyLine(
            sentence: 'You can trust your judgment more in these topics during mocks.',
            isRevise: false,
            mock: mock,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Compared to your account-wide “confident and correct” rate',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _MockPrepSubheading('Action item'),
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
          else
            Column(
              children: [
                for (var i = 0; i < mock.safeTopics.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AppSpacing.lg,
                      color: divider,
                      thickness: 0.5,
                    ),
                  _MockSafeAreaRow(
                    row: mock.safeTopics[i],
                    statColor: accent,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _MockSafeAreaRow extends StatelessWidget {
  const _MockSafeAreaRow({
    required this.row,
    required this.statColor,
  });

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
  const _MockPrepLoadError({
    required this.borderColor,
    required this.onRetry,
  });

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
  const _MockPrepInsightsSkeleton({required this.borderColor});
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor.withValues(alpha: 0.2)),
            ),
          ),
        ],
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
