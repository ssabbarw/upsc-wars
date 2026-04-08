import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

class ExplanationCard extends HookConsumerWidget {
  const ExplanationCard({
    required this.translation,
    required this.showStatements,
    super.key,
  });

  final QuestionTranslation translation;
  final bool showStatements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deepDiveOpen = useState(false);
    final hasStatements =
        showStatements && translation.statementAnalysis.isNotEmpty;
    final tabs =
        hasStatements
            ? const ['Statements', 'Elimination', 'Trap']
            : const ['Elimination', 'Trap'];
    final activeTab = useState(0);
    final primary = const Color(0xFF1D9E75);

    final explanation = (translation.finalExplanation ?? '').trim();
    final split = explanation.split('\n\nValue Addition:');
    final body = split.first.trim();
    final valueAdd =
        split.length > 1
            ? split.sublist(1).join('\n\nValue Addition:').trim()
            : '';
    final watchOut = _parseWatchOut(translation.strongDistractor);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.65,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (valueAdd.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Value addition',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.4,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          valueAdd,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.6,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: () {
              deepDiveOpen.value = !deepDiveOpen.value;
              if (!deepDiveOpen.value) activeTab.value = 0;
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F5),
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Deep dive',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    deepDiveOpen.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: const Color(0xFF888888),
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
                              color:
                                  activeTab.value == i
                                      ? primary
                                      : Colors.transparent,
                              width: 2,
                            ),
                            top: BorderSide(
                              color: Colors.black.withValues(alpha: 0.12),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                activeTab.value == i
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                            color:
                                activeTab.value == i
                                    ? primary
                                    : const Color(0xFF555555),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _TabBody(
                tab: tabs[activeTab.value],
                translation: translation,
                watchOut: watchOut,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.tab,
    required this.translation,
    required this.watchOut,
  });

  final String tab;
  final QuestionTranslation translation;
  final ({String title, String reason})? watchOut;

  @override
  Widget build(BuildContext context) {
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (watchOut != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch out - ${watchOut!.title}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: Color(0xFF854F0B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      watchOut!.reason,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.55,
                        color: Color(0xFF633806),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < translation.eliminationLogic.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        translation.eliminationLogic[i],
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.55,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (translation.upscTrapExplanation ?? '').trim(),
              style: const TextStyle(
                fontSize: 12,
                height: 1.65,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (translation.conceptsUsed.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in translation.conceptsUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F5),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.22),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
    }
  }
}

class _StatementRow extends StatelessWidget {
  const _StatementRow({required this.index, required this.item});
  final int index;
  final StatementAnalysisVm item;

  @override
  Widget build(BuildContext context) {
    final pillBg =
        item.isCorrect ? const Color(0xFFC0DD97) : const Color(0xFFF7C1C1);
    final pillText =
        item.isCorrect ? const Color(0xFF173404) : const Color(0xFF501313);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.12),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.statement,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: Color(0xFF1A1A1A),
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
            child: Text(
              item.reason,
              style: const TextStyle(
                fontSize: 12,
                height: 1.55,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
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
