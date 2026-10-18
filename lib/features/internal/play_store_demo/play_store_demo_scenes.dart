import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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

/// Real Modern History MCQ — facts verified (Charter Act 1833 / Regulating Act 1773).
const playStoreDemoExplanation = QuestionTranslation(
  finalExplanation:
      'Warren Hastings feels right because he was the first Governor-General — '
      'and he was. But of Bengal, not India. The Charter Act of 1833 reorganized '
      'British territories and created the post of Governor-General of India for '
      'the first time. Bentinck was appointed to that new, broader post.\n\n'
      'Most aspirants have memorised "Hastings = first Governor-General" without '
      'attaching the word "Bengal" to it. UPSC counts on exactly that.\n\n'
      'Value Addition: Hastings → first GG of Bengal (Regulating Act, 1773); '
      'Bentinck → first GG of India (Charter Act, 1833); '
      'Mountbatten → first GG of independent India (1947); '
      'Canning → first Viceroy (1858).',
  statementAnalysis: [
    StatementAnalysisVm(
      statement: '(a) Warren Hastings',
      isCorrect: false,
      reason:
          'First Governor-General of Bengal (Regulating Act, 1773) — not India.',
    ),
    StatementAnalysisVm(
      statement: '(b) Lord William Bentinck',
      isCorrect: true,
      reason: 'First Governor-General of India (Charter Act, 1833).',
    ),
    StatementAnalysisVm(
      statement: '(c) Lord Mountbatten',
      isCorrect: false,
      reason: 'First Governor-General of independent India (1947).',
    ),
    StatementAnalysisVm(
      statement: '(d) Lord Canning',
      isCorrect: false,
      reason: 'First Viceroy of India (1858) — a different title after 1857.',
    ),
  ],
  eliminationLogic: [
    'Eliminate (a) — Hastings held the Bengal post, not the all-India one created in 1833.',
    'Eliminate (c) — Mountbatten is post-independence, a full century later.',
    'Eliminate (d) — Canning was the first Viceroy, a different title entirely, created after 1857.',
    'Retain (b) — Bentinck is the only option tied to the Charter Act of 1833 and the all-India post.',
  ],
  strongDistractor:
      'Warren Hastings — Feels right because he was the first GG, '
      'but of Bengal — not India.',
  upscTrapExplanation:
      'Entity-Swap trap: every option is the "first" of something real. '
      'UPSC changed one word — Governor-General of Bengal vs of India — '
      'and that one word decides everything. '
      'Related: Geographic Swap moves a fact to the wrong place; '
      'Entity-Swap moves it to the wrong person or post. '
      'Hastings / Bentinck / Mountbatten / Canning each held a real "first" title; '
      'only Bentinck matches "first Governor-General of India".',
  conceptsUsed: [
    'Entity-Swap',
    'Geographic Swap',
    'Charter Act 1833',
    'Regulating Act 1773',
    'Governor-General vs Viceroy',
  ],
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
      PlayStoreDemoBeat.explanationBody => const _ExplanationScene(
        forceDeepDive: false,
        forceTab: 0,
        scrollMode: _ExplanationScrollMode.none,
        highlightWatchOut: false,
        highlightTrap: false,
      ),
      // First deep-dive swipe: Elimination (skip Statements), scroll + Watch out glow.
      PlayStoreDemoBeat.explanationElimination => const _ExplanationScene(
        forceDeepDive: true,
        forceTab: 1,
        scrollMode: _ExplanationScrollMode.animate,
        highlightWatchOut: true,
        highlightTrap: false,
      ),
      // Stay at bottom — jump with no animation (already there after Elimination).
      PlayStoreDemoBeat.explanationTrap => const _ExplanationScene(
        forceDeepDive: true,
        forceTab: 2,
        scrollMode: _ExplanationScrollMode.jump,
        highlightWatchOut: false,
        highlightTrap: true,
      ),
      PlayStoreDemoBeat.dangerZoneMap => const _DangerZoneMapScene(
        initialTab: 0,
        autoSwitchToStrong: true,
      ),
      PlayStoreDemoBeat.dangerZoneStrong => const _DangerZoneMapScene(
        initialTab: 1,
        autoSwitchToStrong: false,
      ),
      PlayStoreDemoBeat.gamesHub => const _GamesHubScene(),
      PlayStoreDemoBeat.gameTimelineSorter =>
        const _TimelineSorterTrailerScene(),
      PlayStoreDemoBeat.gameFactOrBluff => const _FactOrBluffScene(),
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
              'Recording starts…',
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

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Q. 12  ·  Modern History',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Who was the first Governor-General of India?',
              style: AppTextStyles.h3().copyWith(
                color: scheme.onSurface,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            // Trap pick: Hastings feels right — but it's Bengal, not India.
            const _FakeOption(
              label: 'A',
              text: 'Warren Hastings',
              selected: true,
            ),
            // Exam-mode inline strip under the selected option.
            const _DemoExamConfidenceStrip(
              selectedTier: AnswerConfidence.verySure,
            ),
            const SizedBox(height: 8),
            const _FakeOption(label: 'B', text: 'Lord William Bentinck'),
            const SizedBox(height: 8),
            const _FakeOption(label: 'C', text: 'Lord Mountbatten'),
            const SizedBox(height: 8),
            const _FakeOption(label: 'D', text: 'Lord Canning'),
          ],
        ),
      ),
    );
  }
}

/// Visual twin of [ExamOptionConfidenceStrip] for the promo demo (no session).
class _DemoExamConfidenceStrip extends StatelessWidget {
  const _DemoExamConfidenceStrip({required this.selectedTier});

  final String selectedTier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence: ${AnswerConfidence.examShortLabel(selectedTier)}',
            style: AppTextStyles.caption().copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DemoTierToggle(
                    label: 'Sure',
                    selected: selectedTier == AnswerConfidence.verySure,
                    accent: AppColors.correct,
                    onSurface: AppColors.onPrimary,
                    labelUnselected: isDark
                        ? AppColors.correctTextDark
                        : AppColors.correctText,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DemoTierToggle(
                    label: 'Educated\nguess',
                    selected: selectedTier == AnswerConfidence.somewhatSure,
                    accent: AppColors.warning,
                    onSurface: Colors.white,
                    labelUnselected: isDark
                        ? AppColors.warningTextDark
                        : AppColors.warningText,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DemoTierToggle(
                    label: 'Pure guess',
                    selected: selectedTier == AnswerConfidence.guessing,
                    accent: AppColors.info,
                    onSurface: AppColors.onPrimary,
                    labelUnselected: isDark
                        ? AppColors.infoTextDark
                        : AppColors.infoText,
                    isDark: isDark,
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

class _DemoTierToggle extends StatelessWidget {
  const _DemoTierToggle({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onSurface,
    required this.labelUnselected,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color onSurface;
  final Color labelUnselected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? accent
        : accent.withValues(alpha: isDark ? 0.38 : 0.42);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: selected
            ? accent
            : accent.withValues(alpha: isDark ? 0.07 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: borderColor, width: selected ? 2.5 : 1),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: isDark ? 0.42 : 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Align(
          alignment: Alignment.center,
          child: Row(
            children: [
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.check_rounded, size: 18, color: onSurface),
                ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm().copyWith(
                    color: selected ? onSurface : labelUnselected,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    height: 1.2,
                    fontSize: 11,
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

enum _ExplanationScrollMode { none, animate, jump }

class _ExplanationScene extends HookWidget {
  const _ExplanationScene({
    required this.forceDeepDive,
    required this.forceTab,
    required this.scrollMode,
    required this.highlightWatchOut,
    required this.highlightTrap,
  });

  final bool forceDeepDive;
  final int forceTab;
  final _ExplanationScrollMode scrollMode;
  final bool highlightWatchOut;
  final bool highlightTrap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scrollController = useScrollController();

    useEffect(() {
      if (scrollMode == _ExplanationScrollMode.none) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scrollMode == _ExplanationScrollMode.animate) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
        if (!scrollController.hasClients) return;
        final max = scrollController.position.maxScrollExtent;
        if (scrollMode == _ExplanationScrollMode.jump) {
          scrollController.jumpTo(max);
          return;
        }
        await scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
        );
      });
      return null;
    }, [scrollMode, forceTab, forceDeepDive, highlightWatchOut, highlightTrap]);

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
              'Modern History · Governor-General',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Who was the first Governor-General of India?',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
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
                      'Picked (a) Hastings · Sure · Wrong — Danger Zone',
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
              demoHighlightWatchOut: highlightWatchOut,
              demoHighlightTrap: highlightTrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerZoneMapScene extends HookWidget {
  const _DangerZoneMapScene({
    this.initialTab = 0,
    this.autoSwitchToStrong = false,
  });

  final int initialTab;
  final bool autoSwitchToStrong;

  static const _dangerTopics = <(String, String)>[
    ('Governor-General & Viceroy', '38%'),
    ('Charter Acts', '41%'),
    ('Company Rule', '44%'),
    ('Revolt of 1857', '47%'),
    ('Land Revenue Systems', '49%'),
    ('Early Nationalism 1885–1905', '52%'),
    ('Peasant Movements', '48%'),
    ('British Education Policy', '51%'),
  ];

  static const _strongTopics = <(String, String)>[
    ('Socio-religious Reform', '82%'),
    ('Freedom Struggle 1919–47', '79%'),
    ('Gandhian Movements', '85%'),
    ('Indian National Congress', '81%'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tab = useState(initialTab.clamp(0, 1));
    final dangerAccent = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
    final strongAccent = isDark
        ? AppColors.correctTextDark
        : AppColors.correctText;

    useEffect(() {
      tab.value = initialTab.clamp(0, 1);
      if (!autoSwitchToStrong || initialTab != 0) return null;
      final t = Timer(const Duration(milliseconds: 2200), () {
        tab.value = 1;
      });
      return t.cancel;
    }, [initialTab, autoSwitchToStrong]);

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Modern History',
                style: AppTextStyles.h2().copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mapped from your attempts',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _DzTabBar(index: tab.value, onChanged: (i) => tab.value = i),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: tab.value == 0
                      ? _DzDangerTab(
                          key: const ValueKey('dz-danger'),
                          accent: dangerAccent,
                          isDark: isDark,
                          topics: _dangerTopics,
                        )
                      : _DzStrongTab(
                          key: const ValueKey('dz-strong'),
                          accent: strongAccent,
                          isDark: isDark,
                          topics: _strongTopics,
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

class _DzTabBar extends StatelessWidget {
  const _DzTabBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DzTabChip(
              label: 'Danger Zone',
              selected: index == 0,
              selectedColor: AppColors.wrong,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _DzTabChip(
              label: 'Strong topics',
              selected: index == 1,
              selectedColor: AppColors.correct,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _DzTabChip extends StatelessWidget {
  const _DzTabChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label().copyWith(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DzDangerTab extends StatelessWidget {
  const _DzDangerTab({
    super.key,
    required this.accent,
    required this.isDark,
    required this.topics,
  });

  final Color accent;
  final bool isDark;
  final List<(String, String)> topics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.warning_amber_rounded, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'In the Danger Zone?',
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You are often confidently wrong in these topics. '
            'Revise to improve your score.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final t in topics)
                  _AccuracyTopicRow(name: t.$1, accuracy: t.$2, accent: accent),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Revise Danger Zone'),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

class _DzStrongTab extends StatelessWidget {
  const _DzStrongTab({
    super.key,
    required this.accent,
    required this.isDark,
    required this.topics,
  });

  final Color accent;
  final bool isDark;
  final List<(String, String)> topics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        color: isDark
            ? AppColors.correct.withValues(alpha: 0.10)
            : AppColors.correctBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your strong topics',
                  style: AppTextStyles.h3().copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Educated guesses land here. Take smarter risks.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          for (final t in topics)
            _AccuracyTopicRow(name: t.$1, accuracy: t.$2, accent: accent),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.casino_outlined, size: 18, color: accent),
            label: Text(
              'Practice with more risk',
              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: accent.withValues(alpha: 0.55)),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyTopicRow extends StatelessWidget {
  const _AccuracyTopicRow({
    required this.name,
    required this.accuracy,
    required this.accent,
  });

  final String name;
  final String accuracy;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.body().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Accuracy',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                accuracy,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
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

class _TimelineEvent {
  const _TimelineEvent({required this.label, required this.year});
  final String label;
  final String year;
}

/// Animated Timeline Sorter trailer (dummy board — auto-plays in the demo).
class _TimelineSorterTrailerScene extends HookWidget {
  const _TimelineSorterTrailerScene();

  static const _events = <_TimelineEvent>[
    _TimelineEvent(label: 'Regulating Act', year: '1773'),
    _TimelineEvent(label: 'Charter Act (GG of India)', year: '1833'),
    _TimelineEvent(label: 'Revolt of 1857', year: '1857'),
    _TimelineEvent(label: 'Government of India Act', year: '1919'),
    _TimelineEvent(label: 'Indian Independence', year: '1947'),
  ];

  static const _shuffled = [2, 0, 4, 1, 3];
  static const _sorted = [0, 1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final sorted = useState(false);
    final revealed = useState(false);

    useEffect(() {
      var cancelled = false;
      Future<void>(() async {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (cancelled) return;
        sorted.value = true; // all cards slide in parallel
        await Future<void>.delayed(const Duration(milliseconds: 480));
        if (cancelled) return;
        revealed.value = true;
      });
      return () => cancelled = true;
    }, const []);

    final order = sorted.value ? _sorted : _shuffled;

    return ColoredBox(
      color: RgColors.pageBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: RgColors.pageBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: RgColors.ink,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timeline Sorter',
                            style: RgText.display(
                              size: 18,
                              weight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Modern History · Set 1/10',
                            style: RgText.body(size: 12, color: RgColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FREEDOM & COMPANY RULE',
                  style: RgText.mono(
                    size: 10,
                    letterSpacingEm: 0.08,
                    color: RgColors.mutedSoft,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  revealed.value
                      ? '5 of 5 in order — nice.'
                      : 'Sort the following from earliest to latest.',
                  style: RgText.body(size: 11, color: RgColors.mutedSoft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const rowPitch = 52.0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (
                        var eventIndex = 0;
                        eventIndex < _events.length;
                        eventIndex++
                      )
                        AnimatedPositioned(
                          key: ValueKey(eventIndex),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          top: order.indexOf(eventIndex) * rowPitch,
                          left: 0,
                          right: 0,
                          height: rowPitch - 7,
                          child: _TimelineTrailerRow(
                            event: _events[eventIndex],
                            revealed: revealed.value,
                            lifted: false,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: AnimatedOpacity(
              opacity: revealed.value ? 1 : 0.55,
              duration: const Duration(milliseconds: 280),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: RgColors.teal,
                  borderRadius: BorderRadius.circular(RgRadius.pill),
                ),
                alignment: Alignment.center,
                child: Text(
                  revealed.value ? 'Next set →' : 'Check',
                  style: RgText.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: RgColors.onDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTrailerRow extends StatelessWidget {
  const _TimelineTrailerRow({
    super.key,
    required this.event,
    required this.revealed,
    required this.lifted,
  });

  final _TimelineEvent event;
  final bool revealed;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: revealed ? 10 : 11,
      ),
      decoration: BoxDecoration(
        color: revealed ? RgColors.correctBg : RgColors.card,
        borderRadius: BorderRadius.circular(RgRadius.md),
        border: Border.all(
          color: revealed ? RgColors.correctBorder : RgColors.border,
        ),
        boxShadow: lifted
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            revealed ? Icons.check_circle_rounded : Icons.drag_handle_rounded,
            size: 16,
            color: revealed ? RgColors.tealDeep : RgColors.dragHandle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.label,
              style: RgText.body(size: 12.5, weight: FontWeight.w600),
            ),
          ),
          if (revealed)
            Text(
              event.year,
              style: RgText.mono(size: 11, color: RgColors.tealDeep),
            ),
        ],
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
                      style: RgText.mono(size: 13, color: RgColors.warningText),
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
                  'Lord William Bentinck was the first '
                  'Governor-General of India under the Charter Act of 1833.',
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
                        side: const BorderSide(
                          color: RgColors.wrong,
                          width: 1.5,
                        ),
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

class _EndCardScene extends StatelessWidget {
  const _EndCardScene();

  /// Most important first; rendered as two columns of small text.
  static const _features = <String>[
    'Danger Zone',
    'Detailed Explanations',
    'Elimination Techniques',
    'Trap Analysis',
    'Statement Analysis',
    'Static War',
    'Revision Games',
    'Online Battles',
    'Open Challenge',
    'Highlight Important Lines',
  ];

  @override
  Widget build(BuildContext context) {
    final mid = (_features.length + 1) ~/ 2;
    final left = _features.sublist(0, mid);
    final right = _features.sublist(mid);

    return ColoredBox(
      color: DwColors.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Find your Danger Zone.\nRevise smarter.',
                  textAlign: TextAlign.center,
                  style: DwText.body(color: DwColors.onDarkMuted),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _FeatureColumn(items: left)),
                    const SizedBox(width: 12),
                    Expanded(child: _FeatureColumn(items: right)),
                  ],
                ),
                const SizedBox(height: 22),
                const _StoreBadge(
                  background: Color(0xFF01875F),
                  icon: _PlayStoreMark(size: 28),
                  eyebrow: 'GET IT ON',
                  title: 'Google Play',
                ),
                const SizedBox(height: 12),
                const _StoreBadge(
                  background: Color(0xFF000000),
                  icon: Icon(Icons.apple, size: 30, color: Colors.white),
                  eyebrow: 'Download on the',
                  title: 'App Store',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureColumn extends StatelessWidget {
  const _FeatureColumn({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '·  ',
                  style: DwText.dm(
                    size: 11,
                    weight: FontWeight.w700,
                    color: DwColors.teal,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: DwText.dm(
                      size: 11,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.25,
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

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({
    required this.background,
    required this.icon,
    required this.eyebrow,
    required this.title,
  });

  final Color background;
  final Widget icon;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: background == Colors.black
            ? Border.all(color: Colors.white.withValues(alpha: 0.22))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: DwText.dm(
                  size: 9,
                  weight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Text(
                title,
                style: DwText.dm(
                  size: 18,
                  weight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayStoreMark extends StatelessWidget {
  const _PlayStoreMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlayStoreMarkPainter()),
    );
  }
}

class _PlayStoreMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    Path tri(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    final tip = Offset(w * 0.08, midY);
    final top = Offset(w * 0.92, h * 0.08);
    final bottom = Offset(w * 0.92, h * 0.92);
    final midRight = Offset(w * 0.55, midY);

    // Google Play–ish triangle segments.
    canvas.drawPath(
      tri(tip, top, midRight),
      Paint()..color = const Color(0xFF00A0FF),
    );
    canvas.drawPath(
      tri(tip, midRight, bottom),
      Paint()..color = const Color(0xFFFFD500),
    );
    canvas.drawPath(
      tri(midRight, top, Offset(w * 0.92, midY)),
      Paint()..color = const Color(0xFFFF3A44),
    );
    canvas.drawPath(
      tri(midRight, Offset(w * 0.92, midY), bottom),
      Paint()..color = const Color(0xFF00D46A),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
