import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/shared/widgets/selectable_copy_search_text.dart';

class QuestionTranslation {
  const QuestionTranslation({
    required this.finalExplanation,
    required this.statementAnalysis,
    required this.eliminationLogic,
    required this.strongDistractor,
    required this.upscTrapExplanation,
    required this.conceptsUsed,
  });

  final String? finalExplanation;
  final List<StatementAnalysisVm> statementAnalysis;
  final List<String> eliminationLogic;
  final String? strongDistractor;
  final String? upscTrapExplanation;
  final List<String> conceptsUsed;
}

class StatementAnalysisVm {
  const StatementAnalysisVm({
    required this.statement,
    required this.isCorrect,
    required this.reason,
  });

  final String statement;
  final bool isCorrect;
  final String reason;
}

List<String> _nonEmptyEliminationSteps(List<String> raw) => [
  for (final s in raw)
    if (s.trim().isNotEmpty) s,
];

bool _hasEliminationContent(
  QuestionTranslation t,
  ({String title, String reason})? watchOut,
) {
  if (watchOut != null) return true;
  return _nonEmptyEliminationSteps(t.eliminationLogic).isNotEmpty;
}

bool _hasTrapContent(QuestionTranslation t) {
  if ((t.upscTrapExplanation ?? '').trim().isNotEmpty) return true;
  return t.conceptsUsed.any((c) => c.trim().isNotEmpty);
}

class ExplanationCard extends HookConsumerWidget {
  const ExplanationCard({
    required this.translation,
    required this.showStatements,
    this.demoForceDeepDive,
    this.demoForceTab,
    this.demoHighlightWatchOut = false,
    this.demoHighlightTrap = false,
    super.key,
  });

  final QuestionTranslation translation;
  final bool showStatements;

  /// When non-null (Play Store demo), forces the deep-dive section open/closed.
  final bool? demoForceDeepDive;

  /// When non-null (Play Store demo), forces the active deep-dive tab index.
  final int? demoForceTab;

  /// Play Store demo: pulse/glow the Elimination "Watch out" card.
  final bool demoHighlightWatchOut;

  /// Play Store demo: pulse/glow the Trap panel and bold key trap names.
  final bool demoHighlightTrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deepDiveOpen = useState(demoForceDeepDive ?? false);
    final hasStatements =
        showStatements && translation.statementAnalysis.isNotEmpty;
    final explanation = (translation.finalExplanation ?? '').trim();
    final split = explanation.split('\n\nValue Addition:');
    final body = split.first.trim();
    final valueAdd = split.length > 1
        ? split.sublist(1).join('\n\nValue Addition:').trim()
        : '';
    final watchOut = _parseWatchOut(translation.strongDistractor);
    final hasElimination = _hasEliminationContent(translation, watchOut);
    final hasTrap = _hasTrapContent(translation);
    final tabs = <String>[
      if (hasStatements) 'Statements',
      if (hasElimination) 'Elimination',
      if (hasTrap) 'Trap',
    ];
    final hasDeepDive = tabs.isNotEmpty;
    final activeTab = useState(demoForceTab ?? 0);
    final primary = const Color(0xFF1D9E75);

    useEffect(() {
      final forceOpen = demoForceDeepDive;
      if (forceOpen != null) deepDiveOpen.value = forceOpen;
      final forceTab = demoForceTab;
      if (forceTab != null) activeTab.value = forceTab;
      return null;
    }, [demoForceDeepDive, demoForceTab]);

    useEffect(() {
      if (activeTab.value >= tabs.length) {
        activeTab.value = 0;
      }
      return null;
    }, [tabs.join('|')]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableCopySearchText(
          body,
          style: TextStyle(
            fontSize: 13,
            height: 1.65,
            color: scheme.onSurface,
          ),
        ),
        if (valueAdd.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Value addition',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableCopySearchText(
                  valueAdd,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasDeepDive) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                deepDiveOpen.value = !deepDiveOpen.value;
                if (!deepDiveOpen.value) activeTab.value = 0;
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Deep dive',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      deepDiveOpen.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (deepDiveOpen.value) ...[
              Row(
                children: [
                  for (var i = 0; i < tabs.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => activeTab.value = i,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: activeTab.value == i
                                    ? primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                              top: BorderSide(
                                color: scheme.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            tabs[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: activeTab.value == i
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: activeTab.value == i
                                  ? primary
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _TabBody(
                  tab: tabs[activeTab.value],
                  translation: translation,
                  watchOut: watchOut,
                  isDark: isDark,
                  highlightWatchOut: demoHighlightWatchOut,
                  highlightTrap: demoHighlightTrap,
                ),
              ),
            ],
          ],
        ],
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.tab,
    required this.translation,
    required this.watchOut,
    required this.isDark,
    this.highlightWatchOut = false,
    this.highlightTrap = false,
  });

  final String tab;
  final QuestionTranslation translation;
  final ({String title, String reason})? watchOut;
  final bool isDark;
  final bool highlightWatchOut;
  final bool highlightTrap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (tab) {
      case 'Statements':
        return Column(
          children: [
            for (var i = 0; i < translation.statementAnalysis.length; i++)
              _StatementRow(
                index: i + 1,
                item: translation.statementAnalysis[i],
              ),
          ],
        );
      case 'Elimination':
        final eliminationSteps = _nonEmptyEliminationSteps(
          translation.eliminationLogic,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (watchOut != null) ...[
              _WatchOutCard(
                title: watchOut!.title,
                reason: watchOut!.reason,
                isDark: isDark,
                highlight: highlightWatchOut,
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < eliminationSteps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableCopySearchText(
                        eliminationSteps[i],
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      default:
        final trapText = (translation.upscTrapExplanation ?? '').trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (trapText.isNotEmpty)
              highlightTrap
                  ? _TrapHighlightCard(text: trapText, isDark: isDark)
                  : SelectableCopySearchText(
                      trapText,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.65,
                        color: scheme.onSurface,
                      ),
                    ),
            if (translation.conceptsUsed.any((c) => c.trim().isNotEmpty)) ...[
              if (trapText.isNotEmpty) const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in translation.conceptsUsed)
                    if (tag.trim().isNotEmpty)
                      _TrapConceptChip(
                        tag: tag,
                        emphasize: highlightTrap && _isFeaturedTrapName(tag),
                      ),
                ],
              ),
            ],
          ],
        );
    }
  }
}

bool _isFeaturedTrapName(String tag) {
  final t = tag.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  return t.contains('entityswap') || t.contains('geographicswap');
}

class _TrapConceptChip extends StatelessWidget {
  const _TrapConceptChip({required this.tag, required this.emphasize});

  final String tag;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!emphasize) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SelectableCopySearchText(
          tag,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE24B4A).withValues(alpha: 0.14),
        border: Border.all(color: const Color(0xFFE24B4A), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE24B4A).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE24B4A),
        ),
      ),
    );
  }
}

class _TrapHighlightCard extends HookWidget {
  const _TrapHighlightCard({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  static const _phrases = [
    'Entity-Swap',
    'Entity Swap',
    'Geographic Swap',
    'Geographic-Swap',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      controller.repeat(reverse: true);
      return null;
    }, const []);

    final scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    final glow = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    final baseStyle = TextStyle(
      fontSize: 13,
      height: 1.6,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFF7CFCF) : const Color(0xFF501313),
    );
    final hiStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w900,
      color: const Color(0xFFE24B4A),
      backgroundColor: const Color(0xFFE24B4A).withValues(alpha: 0.16),
    );

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A1515) : const Color(0xFFFCE9E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE24B4A), width: 2),
      ),
      child: Text.rich(
        TextSpan(children: _highlightSpans(text, baseStyle, hiStyle)),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE24B4A).withValues(alpha: glow.value),
                  blurRadius: 18 + (glow.value * 10),
                  spreadRadius: 1 + (glow.value * 2),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: card,
    );
  }

  static List<InlineSpan> _highlightSpans(
    String text,
    TextStyle base,
    TextStyle highlight,
  ) {
    final matches = <(int, int, String)>[];
    for (final phrase in _phrases) {
      var start = 0;
      final lower = text.toLowerCase();
      final needle = phrase.toLowerCase();
      while (true) {
        final i = lower.indexOf(needle, start);
        if (i < 0) break;
        matches.add((i, i + phrase.length, text.substring(i, i + phrase.length)));
        start = i + phrase.length;
      }
    }
    matches.sort((a, b) => a.$1.compareTo(b.$1));

    if (matches.isEmpty) {
      return [TextSpan(text: text, style: base)];
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in matches) {
      if (m.$1 < cursor) continue;
      if (m.$1 > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.$1), style: base));
      }
      spans.add(TextSpan(text: m.$3, style: highlight));
      cursor = m.$2;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({required this.index, required this.item});
  final int index;
  final StatementAnalysisVm item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = item.isCorrect
        ? (isDark ? const Color(0xFF2F5B35) : const Color(0xFFC0DD97))
        : (isDark ? const Color(0xFF6A2C2C) : const Color(0xFFF7C1C1));
    final pillText = item.isCorrect
        ? (isDark ? const Color(0xFFD4F4D9) : const Color(0xFF173404))
        : (isDark ? const Color(0xFFF7CFCF) : const Color(0xFF501313));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableCopySearchText(
                  item.statement,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.isCorrect ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: pillText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: SelectableCopySearchText(
              item.reason,
              style: TextStyle(
                fontSize: 12,
                height: 1.55,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchOutCard extends HookWidget {
  const _WatchOutCard({
    required this.title,
    required this.reason,
    required this.isDark,
    required this.highlight,
  });

  final String title;
  final String reason;
  final bool isDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      if (highlight) {
        controller.repeat(reverse: true);
      } else {
        controller.stop();
        controller.value = 0;
      }
      return null;
    }, [highlight]);

    final scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    final glow = Tween<double>(begin: 0.28, end: 0.7).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF39290E) : const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(8),
        border: highlight
            ? Border.all(color: const Color(0xFFBA7517), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableCopySearchText(
            'Watch out - $title',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              color: isDark
                  ? const Color(0xFFF4D39E)
                  : const Color(0xFF854F0B),
            ),
          ),
          const SizedBox(height: 4),
          SelectableCopySearchText(
            reason,
            style: TextStyle(
              fontSize: highlight ? 14 : 12,
              height: 1.55,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              color: isDark
                  ? const Color(0xFFF4D39E)
                  : const Color(0xFF633806),
            ),
          ),
        ],
      ),
    );

    if (!highlight) return card;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBA7517).withValues(alpha: glow.value),
                  blurRadius: 18 + (glow.value * 10),
                  spreadRadius: 1 + (glow.value * 2),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}

({String title, String reason})? _parseWatchOut(String? strongDistractor) {
  if (strongDistractor == null || strongDistractor.trim().isEmpty) return null;
  final text = strongDistractor.trim();
  final emDash = text.split('—');
  if (emDash.length >= 2) {
    return (
      title: emDash.first.trim(),
      reason: emDash.sublist(1).join('—').trim(),
    );
  }
  final hyphenDash = text.split(' - ');
  if (hyphenDash.length >= 2) {
    return (
      title: hyphenDash.first.trim(),
      reason: hyphenDash.sublist(1).join(' - ').trim(),
    );
  }
  return (title: 'Option', reason: text);
}
