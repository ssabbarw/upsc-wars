import 'package:flutter/material.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../daily_war/theme/daily_war_theme.dart';
import '../../history/widgets/explanation_card.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import '../../onboarding/widgets/onboarding_thesis_page.dart';
import 'play_store_demo_script.dart';

/// Sample explanation rich enough to show all deep-dive tabs.
const playStoreDemoExplanation = QuestionTranslation(
  finalExplanation:
      'The Basic Structure doctrine limits Parliament\'s power to amend '
      'the Constitution. Fundamental features — supremacy of the Constitution, '
      'separation of powers, and judicial review — cannot be abrogated.\n\n'
      'Value Addition: Kesavananda Bharati (1973) is the landmark; later cases '
      'refined which features fall inside the Basic Structure.',
  statementAnalysis: [
    StatementAnalysisVm(
      statement: 'Parliament can amend any part of the Constitution.',
      isCorrect: false,
      reason: 'Amending power is wide but not absolute under Basic Structure.',
    ),
    StatementAnalysisVm(
      statement: 'Judicial review is part of the Basic Structure.',
      isCorrect: true,
      reason: 'Courts protect constitutional supremacy via judicial review.',
    ),
    StatementAnalysisVm(
      statement: 'Fundamental rights can never be amended.',
      isCorrect: false,
      reason: 'Rights can be amended, but not destroyed in substance.',
    ),
  ],
  eliminationLogic: [
    'Drop options that treat amending power as unlimited.',
    'Keep options that preserve judicial review / constitutional supremacy.',
    'Eliminate absolute wording like "never" unless the text supports it.',
  ],
  strongDistractor:
      'Unlimited amending power|Sounds close to Article 368 but ignores Basic Structure limits.',
  upscTrapExplanation:
      'UPSC often mixes "Parliament is supreme in amendment" with "no limits". '
      'The trap is treating amending power as absolute.',
  conceptsUsed: ['Basic Structure', 'Judicial review', 'Article 368'],
);

class PlayStoreDemoScene extends StatelessWidget {
  const PlayStoreDemoScene({required this.beat, super.key});

  final PlayStoreDemoBeat beat;

  @override
  Widget build(BuildContext context) {
    return switch (beat) {
      PlayStoreDemoBeat.ready => const _ReadyScene(),
      PlayStoreDemoBeat.thesis => const _ThesisScene(),
      PlayStoreDemoBeat.confidence => const _ConfidenceScene(),
      PlayStoreDemoBeat.dangerZoneIntro => const _DangerZoneIntroScene(),
      PlayStoreDemoBeat.explanationBody => const _ExplanationScene(
        forceDeepDive: false,
        forceTab: 0,
      ),
      PlayStoreDemoBeat.explanationStatements => const _ExplanationScene(
        forceDeepDive: true,
        forceTab: 0,
      ),
      PlayStoreDemoBeat.explanationElimination => const _ExplanationScene(
        forceDeepDive: true,
        forceTab: 1,
      ),
      PlayStoreDemoBeat.explanationTrap => const _ExplanationScene(
        forceDeepDive: true,
        forceTab: 2,
      ),
      PlayStoreDemoBeat.dangerZoneMap => const _DangerZoneMapScene(),
      PlayStoreDemoBeat.gamesHub => const _GamesHubScene(),
      PlayStoreDemoBeat.gameMemoryPairs => const _MemoryPairsScene(),
      PlayStoreDemoBeat.gameFactOrBluff => const _FactOrBluffScene(),
      PlayStoreDemoBeat.warLive => const _WarLiveScene(),
      PlayStoreDemoBeat.warAir => const _WarAirScene(),
      PlayStoreDemoBeat.endCard => const _EndCardScene(),
    };
  }
}

class _ReadyScene extends StatelessWidget {
  const _ReadyScene();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B5C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'UPSC Wars',
              style: DwText.dm(
                size: 28,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo starting…',
              style: DwText.body(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThesisScene extends StatelessWidget {
  const _ThesisScene();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: RgColors.pageBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: OnboardingThesisPage(
            onContinue: () {},
            showContinueButton: false,
          ),
        ),
      ),
    );
  }
}

class _ConfidenceScene extends StatelessWidget {
  const _ConfidenceScene();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Q. 12  ·  Polity',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Which of the following is part of the Basic Structure '
                'of the Constitution?',
                style: AppTextStyles.h3().copyWith(
                  color: scheme.onSurface,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              _FakeOption(label: 'A', text: 'Judicial review', selected: true),
              const SizedBox(height: 10),
              const _FakeOption(label: 'B', text: 'Unlimited amending power'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? scheme.surfaceContainerHigh
                      : scheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'How sure are you?',
                      style: AppTextStyles.h3().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pick before you see the answer — this builds your '
                      'Danger Zone map.',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () {},
                      child: Text(
                        AnswerConfidence.examShortLabel(
                          AnswerConfidence.verySure,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () {},
                      child: Text(
                        AnswerConfidence.examShortLabel(
                          AnswerConfidence.somewhatSure,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        AnswerConfidence.examShortLabel(
                          AnswerConfidence.guessing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeOption extends StatelessWidget {
  const _FakeOption({
    required this.label,
    required this.text,
    this.selected = false,
  });

  final String label;
  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : scheme.outlineVariant.withValues(alpha: 0.6),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.label().copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZoneIntroScene extends StatelessWidget {
  const _DangerZoneIntroScene();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.wrongTextDark : AppColors.wrong;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'What is Danger Zone?',
                      style: AppTextStyles.h3().copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Where you feel sure — and still get it wrong.',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DzBullet(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.wrong,
                      title: 'Confident & wrong',
                      body: 'Sure / Educated guess → incorrect',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DzBullet(
                      icon: Icons.lightbulb_outline_rounded,
                      iconColor: AppColors.primary,
                      title: 'Guess & right',
                      body: 'Pure guess → correct',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryDeep.withValues(alpha: 0.25)
                            : AppColors.primaryLight.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'Map unlocked — open it to see these by subject.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DzBullet extends StatelessWidget {
  const _DzBullet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                body,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExplanationScene extends StatelessWidget {
  const _ExplanationScene({
    required this.forceDeepDive,
    required this.forceTab,
  });

  final bool forceDeepDive;
  final int forceTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Explanation',
              style: AppTextStyles.h3().copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Polity · Basic Structure',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.wrong.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.wrong.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.wrong,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Marked Sure · Incorrect — Danger Zone',
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ExplanationCard(
              translation: playStoreDemoExplanation,
              showStatements: true,
              demoForceDeepDive: forceDeepDive,
              demoForceTab: forceTab,
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerZoneMapScene extends StatelessWidget {
  const _DangerZoneMapScene();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.wrongTextDark : AppColors.wrongText;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Polity',
                style: AppTextStyles.h2().copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Danger zone of Polity',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                  color: isDark
                      ? AppColors.wrong.withValues(alpha: 0.08)
                      : AppColors.wrongBg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: accent,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: AppTextStyles.h3().copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '18',
                          style: AppTextStyles.h2().copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confident mistakes to revise first',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DzStat(
                            label: 'Sure wrong',
                            value: '11',
                            marks: '7.26',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DzStat(
                            label: 'Educated guess',
                            value: '7',
                            marks: '4.62',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Revise Sure wrongs'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Top topics',
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              const _TopicRow(name: 'Basic Structure', count: 5),
              const _TopicRow(name: 'Fundamental Rights', count: 4),
              const _TopicRow(name: 'Parliament', count: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _DzStat extends StatelessWidget {
  const _DzStat({
    required this.label,
    required this.value,
    required this.marks,
  });

  final String label;
  final String value;
  final String marks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3().copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          Text(
            '~$marks marks',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.body().copyWith(color: scheme.onSurface),
            ),
          ),
          Text(
            '$count',
            style: AppTextStyles.label().copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.wrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _GamesHubScene extends StatelessWidget {
  const _GamesHubScene();

  static const _games = <(IconData, String, String, Color, bool)>[
    (
      Icons.grid_view_rounded,
      'Memory Pairs',
      'Match terms to answers — train recall.',
      RgColors.info,
      false,
    ),
    (
      Icons.timeline_rounded,
      'Timeline Sorter',
      'Put events in the right order.',
      RgColors.warning,
      false,
    ),
    (
      Icons.rule_rounded,
      'Odd One Out',
      'Pick the odd one out.',
      RgColors.wrong,
      false,
    ),
    (
      Icons.bolt_rounded,
      'Fact or Bluff',
      'Ten seconds. Trust your gut.',
      RgColors.teal,
      false,
    ),
    (
      Icons.hub_rounded,
      'Connect the Dots',
      'Find the hidden link.',
      RgColors.tealDeep,
      false,
    ),
    (
      Icons.military_tech_rounded,
      '1v1 Duel',
      'One phone, two players, fastest wins.',
      RgColors.teal,
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: RgColors.pageBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Revision Games',
              style: RgText.display(size: 26, weight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Short drills that stick — between full tests.',
              style: RgText.body(color: RgColors.muted),
            ),
            const SizedBox(height: 18),
            for (final g in _games) ...[
              _GameTile(
                icon: g.$1,
                title: g.$2,
                description: g.$3,
                badgeColor: g.$4,
                highlighted: g.$5,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.badgeColor,
    required this.highlighted,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color badgeColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? RgColors.ink : RgColors.card,
        borderRadius: BorderRadius.circular(RgRadius.lg),
        border: Border.all(
          color: highlighted ? Colors.transparent : RgColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: highlighted
                  ? badgeColor.withValues(alpha: 0.25)
                  : badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RgRadius.md),
            ),
            child: Icon(
              icon,
              color: highlighted ? RgColors.onDark : badgeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: RgText.display(
                    size: 15,
                    weight: FontWeight.w700,
                    color: highlighted ? RgColors.onDark : RgColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: RgText.body(
                    size: 12,
                    color: highlighted
                        ? RgColors.onDark.withValues(alpha: 0.7)
                        : RgColors.muted,
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

class _MemoryPairsScene extends StatelessWidget {
  const _MemoryPairsScene();

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Basic Structure', true, false),
      ('??', false, true),
      ('Kesavananda', false, false),
      ('??', false, false),
      ('Art. 368', true, false),
      ('??', false, false),
    ];

    return ColoredBox(
      color: RgColors.pageBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Memory Pairs',
                style: RgText.display(size: 24, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Match terms to answers',
                style: RgText.body(color: RgColors.muted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final c in cards)
                      _FlipCard(
                        label: c.$1,
                        matched: c.$2,
                        faceUp: c.$3 || c.$2,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.label,
    required this.matched,
    required this.faceUp,
  });

  final String label;
  final bool matched;
  final bool faceUp;

  @override
  Widget build(BuildContext context) {
    final bg = matched
        ? RgColors.correctBg
        : faceUp
        ? RgColors.card
        : RgColors.ink;
    final fg = matched || faceUp ? RgColors.ink : RgColors.onDark;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(RgRadius.lg),
        border: Border.all(
          color: matched ? RgColors.correctBorder : RgColors.border,
        ),
      ),
      child: Text(
        faceUp || matched ? label : '●',
        textAlign: TextAlign.center,
        style: RgText.display(size: 14, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _FactOrBluffScene extends StatelessWidget {
  const _FactOrBluffScene();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: RgColors.pageBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Fact or Bluff',
                    style: RgText.display(size: 22, weight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: RgColors.warningBg,
                      borderRadius: BorderRadius.circular(RgRadius.pill),
                    ),
                    child: Text(
                      '8s',
                      style: RgText.mono(
                        size: 13,
                        color: RgColors.warningText,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: RgColors.card,
                  borderRadius: BorderRadius.circular(RgRadius.xl),
                  border: Border.all(color: RgColors.border),
                ),
                child: Text(
                  'The Basic Structure doctrine was first laid down '
                  'in Kesavananda Bharati v. State of Kerala (1973).',
                  textAlign: TextAlign.center,
                  style: RgText.display(
                    size: 18,
                    weight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: RgColors.teal,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(
                        'FACT',
                        style: RgText.display(
                          size: 16,
                          weight: FontWeight.w800,
                          color: RgColors.onDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RgColors.wrong,
                        side: const BorderSide(color: RgColors.wrong, width: 1.5),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(
                        'BLUFF',
                        style: RgText.display(
                          size: 16,
                          weight: FontWeight.w800,
                          color: RgColors.wrong,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarLiveScene extends StatelessWidget {
  const _WarLiveScene();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DwColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DwColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DwColors.borderOnDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DwColors.crimson,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LIVE',
                            style: DwText.dm(
                              size: 11,
                              weight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '9:00 PM IST',
                          style: DwText.meta(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DAILY WAR',
                      style: DwText.eyebrow(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All-India Prelims night',
                      style: DwText.dm(
                        size: 22,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Polity · Economy · Environment',
                      style: DwText.body(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: DwColors.crimson,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text('Enter War', style: DwText.cta()),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarAirScene extends StatelessWidget {
  const _WarAirScene();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DwColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('War results', style: DwText.dm(size: 18, weight: FontWeight.w700)),
              const SizedBox(height: 28),
              Text('ALL-INDIA RANK', style: DwText.meta()),
              const SizedBox(height: 4),
              Text('142', style: DwText.heroNumber()),
              Text('of 12,480', style: DwText.body()),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _AirStat(label: 'PERCENTILE', value: '98.9'),
                  ),
                  Expanded(
                    child: _AirStat(label: 'SCORE', value: '16.66/20'),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: DwColors.teal,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text('View leaderboard', style: DwText.cta()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AirStat extends StatelessWidget {
  const _AirStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DwText.meta()),
        const SizedBox(height: 4),
        Text(
          value,
          style: DwText.dm(size: 20, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EndCardScene extends StatelessWidget {
  const _EndCardScene();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DwColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UPSC Wars',
              style: DwText.dm(
                size: 34,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Find your Danger Zone.\nProve it in Daily War.',
              textAlign: TextAlign.center,
              style: DwText.body(color: DwColors.onDarkMuted),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: DwColors.crimson,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Get it on Google Play',
                style: DwText.cta(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
