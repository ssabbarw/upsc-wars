import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/series_stats.dart';
import '../../domain/test_series_models.dart';
import '../../providers/series_sample_question_provider.dart';
import '../series_dashboard_widgets.dart';
import '../series_test_row.dart';
import 'series_tone.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/series_rules.dart';

/// Tab indexes of the series home, for the "see all" buttons.
abstract final class SeriesBrowseTab {
  static const overview = 0;
  static const fullLength = 1;
  static const subjects = 2;
  static const pyqAndCa = 3;
}

String _plural(int n, String one, [String? many]) =>
    '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// "24th May" style in English; the ordinal suffix does not exist in Hindi,
/// so Hindi gets a plain localized day + month.
String _prelimsDateLabel(DateTime d) => AppL10n.locale.languageCode == 'hi'
    ? DateFormat('d MMM').format(d)
    : '${d.day}rd ${_months[d.month - 1]}';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// ─────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────

class IntroHero extends StatelessWidget {
  const IntroHero({super.key, required this.bundle, required this.isHindi});

  final SeriesBundle bundle;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prelims = bundle.info.prelimsDate;
    final daysLeft = prelims?.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.introHeroStartDark, AppColors.introHeroEndDark]
              : const [AppColors.introHeroStart, AppColors.introHeroEnd],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.35 : 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.info.displayTitle(hindi: isHindi),
                      style: AppTextStyles.h1().copyWith(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.tsHeroTagline,
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const _HeroArt(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TonePill(
                label: 'English + हिन्दी',
                tone: SeriesTone.green,
                icon: Icons.translate_rounded,
              ),
              TonePill(
                label: 'Detailed explanations',
                tone: SeriesTone.purple,
                icon: Icons.auto_stories_rounded,
              ),
              TonePill(
                label: 'Smart analysis',
                tone: SeriesTone.blue,
                icon: Icons.insights_rounded,
              ),
            ],
          ),
          if (prelims != null && daysLeft != null && daysLeft > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: isDark ? 0.5 : 0.75),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${context.l10n.tsPrelimsOn(_prelimsDateLabel(prelims))} ·  ${context.l10n.tsDaysToGo(daysLeft)}',
                      style: AppTextStyles.labelSm().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Exam paper with a gold medal, drawn in code so it needs no asset and
/// follows the theme.
class _HeroArt extends StatelessWidget {
  const _HeroArt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget row(Widget box) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          box,
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );

    Widget tick(IconData icon, Color color) => Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 11, color: AppColors.onPrimary),
    );

    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 8,
            top: 10,
            child: Transform.rotate(
              angle: -0.14,
              child: Container(
                width: 74,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 2,
            child: Container(
              width: 74,
              height: 96,
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray900.withValues(
                      alpha: isDark ? 0.5 : 0.14,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  row(tick(Icons.check_rounded, AppColors.primary)),
                  row(tick(Icons.check_rounded, AppColors.primary)),
                  row(
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.gray200,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  row(tick(Icons.close_rounded, AppColors.wrong)),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold,
                    border: Border.all(color: AppColors.warning, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gray900.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.introHeroStart,
                    size: 26,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: 0.25,
                        child: Container(
                          width: 11,
                          height: 18,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Transform.rotate(
                        angle: -0.25,
                        child: Container(
                          width: 11,
                          height: 18,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────
// Test counts
// ─────────────────────────────────────────────────────────────────────────

class IntroCounts extends StatelessWidget {
  const IntroCounts({super.key, required this.bundle});

  final SeriesBundle bundle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flt = bundle.ofKind(SeriesTestKind.fullLength).length;
    final subject = bundle.ofKind(SeriesTestKind.staticTest).length;
    final ca = bundle.ofKind(SeriesTestKind.currentAffairs).length;
    final blue = seriesToneColors(SeriesTone.blue, isDark: isDark);

    Color numberColor(SeriesTone t) {
      final c = seriesToneColors(t, isDark: isDark);
      return isDark ? c.fg : c.accent;
    }

    Widget stat(int value, String label, Color color) => Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTextStyles.h1().copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    Widget divider() => Container(
      width: 1,
      height: 36,
      color: scheme.outlineVariant.withValues(alpha: 0.6),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: introCardDecoration(context),
          child: Row(
            children: [
              stat(
                bundle.tests.length,
                context.l10n.tsTotalTests,
                numberColor(SeriesTone.green),
              ),
              divider(),
              stat(flt, 'Full-length mocks', numberColor(SeriesTone.blue)),
              divider(),
              stat(subject, 'Subject tests', numberColor(SeriesTone.purple)),
            ],
          ),
        ),
        if (ca > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: introCardDecoration(context, tone: SeriesTone.blue),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ToneIconBadge(
                  icon: Icons.newspaper_rounded,
                  tone: SeriesTone.blue,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plural(ca, 'Current Affairs test'),
                        style: AppTextStyles.h3().copyWith(
                          color: blue.fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.tsFreshMonthly,
                        style: AppTextStyles.bodySm().copyWith(color: blue.fg),
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

// ─────────────────────────────────────────────────────────────────────────
// Free PYQ tests
// ─────────────────────────────────────────────────────────────────────────

class IntroFreePyq extends StatelessWidget {
  const IntroFreePyq({
    super.key,
    required this.bundle,
    required this.stats,
    required this.onSeeAll,
  });

  final SeriesBundle bundle;
  final SeriesStats stats;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = seriesToneColors(SeriesTone.green, isDark: isDark);
    final pyq = bundle.ofKind(SeriesTestKind.pyqMix);
    if (pyq.isEmpty) return const SizedBox.shrink();
    final freeTotal = bundle.tests.where((t) => t.isFree).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: introCardDecoration(context, tone: SeriesTone.green),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ToneIconBadge(
                icon: Icons.history_edu_rounded,
                tone: SeriesTone.green,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free PYQ tests',
                      style: AppTextStyles.h2().copyWith(
                        color: green.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.tsFreePyqDesc,
                      style: AppTextStyles.bodySm().copyWith(color: green.fg),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final t in pyq.take(3))
            SeriesTestRow(bundle: bundle, test: t, owned: false, stats: stats),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: onSeeAll,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(context.l10n.tsSeeAllPyq(pyq.length)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: green.fg,
              side: BorderSide(color: green.accent),
            ),
          ),
          if (freeTotal > pyq.length) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                context.l10n.tsFreeInAll(freeTotal),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption().copyWith(color: green.fg),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Explanations
// ─────────────────────────────────────────────────────────────────────────

class IntroExplanations extends ConsumerWidget {
  const IntroExplanations({super.key, required this.onSeeExample});

  final VoidCallback onSeeExample;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Also warms the sample question so the sheet opens instantly.
    final sample = ref.watch(seriesSampleQuestionProvider).asData?.value;
    final hint = sample == null
        ? null
        : sample.isCurrentAffairs
        ? context.l10n.tsFromYesterdayCa
        : context.l10n.tsSampleGs;

    Widget tile(SeriesTone tone, IconData icon, String title, String body) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: introCardDecoration(context, tone: tone),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToneIconBadge(icon: icon, tone: tone, size: 36),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.label().copyWith(
                    color: seriesToneColors(
                      tone,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ).fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntroSectionTitle(
          context.l10n.tsExplTeach,
          subtitle: context.l10n.tsExplTeachSub,
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(
                SeriesTone.green,
                Icons.fact_check_rounded,
                'Statement analysis',
                context.l10n.tsStmtDesc,
              ),
              const SizedBox(width: AppSpacing.md),
              tile(
                SeriesTone.red,
                Icons.warning_amber_rounded,
                'Strong distractor',
                context.l10n.tsDistractorDesc,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(
                SeriesTone.blue,
                Icons.content_cut_rounded,
                'Elimination technique',
                context.l10n.tsElimDesc,
              ),
              const SizedBox(width: AppSpacing.md),
              tile(
                SeriesTone.purple,
                Icons.lightbulb_rounded,
                'Value addition',
                context.l10n.tsValueAddDesc,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onSeeExample,
          icon: const Icon(Icons.visibility_rounded, size: 20),
          label: Text(context.l10n.tsSeeRealExample),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              hint,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Smart tools
// ─────────────────────────────────────────────────────────────────────────

class IntroSmartTools extends StatelessWidget {
  const IntroSmartTools({super.key, required this.onSeeAnalysisExample});

  final VoidCallback onSeeAnalysisExample;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntroSectionTitle(
          context.l10n.tsSmarterTitle,
          subtitle: context.l10n.tsSmarterSub,
        ),
        _ToolCard(
          tone: SeriesTone.blue,
          icon: Icons.bookmark_added_rounded,
          title: context.l10n.tsToolQueueTitle,
          body: context.l10n.tsToolQueueBody,
          visual: _QueueVisual(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ToolCard(
          tone: SeriesTone.red,
          icon: Icons.radar_rounded,
          title: context.l10n.tsToolBlindTitle,
          body: context.l10n.tsToolBlindBody,
          visual: _BlindSpotVisual(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ToolCard(
          tone: SeriesTone.purple,
          icon: Icons.bar_chart_rounded,
          title: context.l10n.tsToolTopicTitle,
          body: context.l10n.tsToolTopicBody,
          visual: const _SubjectVisual(),
          ctaLabel: context.l10n.tsSeeExample,
          onCta: onSeeAnalysisExample,
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    required this.visual,
    this.ctaLabel,
    this.onCta,
  });

  final SeriesTone tone;
  final IconData icon;
  final String title;
  final String body;
  final Widget visual;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = seriesToneColors(tone, isDark: isDark);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: introCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ToneIconBadge(icon: icon, tone: tone, size: 42),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: AppTextStyles.bodyMd().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.bg.withValues(alpha: isDark ? 0.55 : 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                visual,
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Example view',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (ctaLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.insights_rounded, size: 18),
              label: Text(ctaLabel!),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: c.fg,
                side: BorderSide(color: c.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueueVisual extends StatelessWidget {
  const _QueueVisual();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Fundamental Rights', 'Polity', 'Wrong', SeriesTone.red),
      ('Indian Monsoon', 'Geography', 'Bookmarked', SeriesTone.purple),
      ('Inflation', 'Economy', 'Wrong', SeriesTone.red),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final r in rows)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.$1,
                        style: AppTextStyles.bodySm().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        r.$2,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TonePill(
                  label: r.$3 == 'Wrong'
                      ? context.l10n.resultsMatrixWrong
                      : context.l10n.testBookmarked,
                  tone: r.$4,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BlindSpotVisual extends StatelessWidget {
  const _BlindSpotVisual();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget cell(
      SeriesTone tone,
      String situation,
      String verdict,
      String action,
    ) {
      final c = seriesToneColors(tone, isDark: isDark);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: c.accent.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                situation,
                style: AppTextStyles.caption().copyWith(
                  color: c.fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                verdict,
                style: AppTextStyles.label().copyWith(
                  color: isDark ? c.fg : c.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action,
                style: AppTextStyles.caption().copyWith(
                  color: c.fg,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(
                SeriesTone.green,
                context.l10n.tsSureRight,
                'Safe area',
                context.l10n.tsSafeAction,
              ),
              const SizedBox(width: AppSpacing.sm),
              cell(
                SeriesTone.red,
                context.l10n.tsSureWrong,
                'Blind spot',
                context.l10n.tsBlindAction,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(
                SeriesTone.amber,
                context.l10n.tsGuessRight,
                'Lucky',
                context.l10n.tsLuckyAction,
              ),
              const SizedBox(width: AppSpacing.sm),
              cell(
                SeriesTone.blue,
                context.l10n.tsGuessWrong,
                'Known gap',
                context.l10n.tsGapAction,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectVisual extends StatelessWidget {
  const _SubjectVisual();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const rows = [
      ('Polity', 0.81, Icons.account_balance_rounded),
      ('Geography', 0.67, Icons.public_rounded),
      ('Modern History', 0.46, Icons.history_edu_rounded),
    ];
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(r.$3, size: 18, color: seriesAccuracyColor(r.$2)),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 96,
                  child: Text(
                    r.$1,
                    style: AppTextStyles.bodySm().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: r.$2,
                      minHeight: 8,
                      backgroundColor: scheme.surface,
                      color: seriesAccuracyColor(r.$2),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${(r.$2 * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.labelSm().copyWith(
                      color: seriesAccuracyColor(r.$2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Exam realism
// ─────────────────────────────────────────────────────────────────────────

class IntroExamRealism extends StatelessWidget {
  const IntroExamRealism({super.key, required this.bundle});

  final SeriesBundle bundle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tile(SeriesTone tone, IconData icon, String title, String body) {
      final c = seriesToneColors(tone, isDark: isDark);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: introCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToneIconBadge(icon: icon, tone: tone, size: 34),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.label().copyWith(
                  color: c.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntroSectionTitle(
          context.l10n.tsPractiseLike,
          subtitle: context.l10n.tsMocksMirror,
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(
                SeriesTone.blue,
                Icons.timer_rounded,
                context.l10n.ts100q2h(
                  SeriesRules.fltQuestions,
                  SeriesRules.fltHours,
                ),
                context.l10n.tsTimedPaper,
              ),
              const SizedBox(width: AppSpacing.md),
              tile(
                SeriesTone.amber,
                Icons.calculate_rounded,
                context.l10n.tsRealMarking,
                context.l10n.tsMarkingSkip,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile(
                SeriesTone.green,
                Icons.flag_rounded,
                context.l10n.tsOneScored,
                context.l10n.tsThenReview,
              ),
              const SizedBox(width: AppSpacing.md),
              tile(
                SeriesTone.purple,
                Icons.translate_rounded,
                'English + हिन्दी',
                context.l10n.tsBothLangs,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Wrap-up
// ─────────────────────────────────────────────────────────────────────────

class IntroWrapUp extends StatelessWidget {
  const IntroWrapUp({super.key, required this.bundle, required this.onTryFree});

  final SeriesBundle bundle;
  final VoidCallback onTryFree;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = seriesToneColors(SeriesTone.green, isDark: isDark);

    Widget line(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 20, color: green.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMd().copyWith(color: green.fg),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: introCardDecoration(context, tone: SeriesTone.green),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.gold,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.tsOnePayGood,
                  style: AppTextStyles.h2().copyWith(
                    color: green.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          line(context.l10n.tsWrapTests(bundle.tests.length)),
          line(context.l10n.tsWrapExpl),
          line(context.l10n.tsWrapQueue),
          line(context.l10n.tsWrapNoExpiry),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.tsNotSure,
            style: AppTextStyles.bodySm().copyWith(color: green.fg),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onTryFree,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(context.l10n.tsTryFreePyq),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              foregroundColor: green.fg,
              side: BorderSide(color: green.accent),
            ),
          ),
        ],
      ),
    );
  }
}
