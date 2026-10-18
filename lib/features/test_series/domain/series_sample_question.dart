import '../../../core/parsers/question_display_text_parser.dart';
import '../../history/widgets/explanation_card.dart';

/// One language's worth of a sample question.
class SampleQuestionContent {
  const SampleQuestionContent({
    required this.stem,
    required this.options,
    required this.translation,
  });

  final String stem;

  /// Keys `a`..`d`.
  final Map<String, String> options;
  final QuestionTranslation translation;

  bool get hasStatements => translation.statementAnalysis.isNotEmpty;
}

/// The question shown behind "See an example" on the test series intro.
///
/// Normally yesterday's current-affairs question with the richest explanation;
/// [fallback] (a GS question) when that is not available.
class SeriesSampleQuestion {
  const SeriesSampleQuestion({
    required this.en,
    required this.correctOption,
    required this.subjectLabel,
    required this.isCurrentAffairs,
    this.hi,
  });

  final SampleQuestionContent en;
  final SampleQuestionContent? hi;

  /// `a`..`d`.
  final String correctOption;
  final String subjectLabel;
  final bool isCurrentAffairs;

  SampleQuestionContent contentFor({required bool hindi}) =>
      hindi && hi != null ? hi! : en;

  /// A question needs at least this many explanation layers (statements,
  /// elimination, strong distractor, trap, value addition) to be a good demo.
  static const _minRichness = 3;

  /// Picks the best-explained renderable question from a Daily CA day.
  /// Returns null when none is rich enough, so the caller can fall back.
  static SeriesSampleQuestion? pickFromDailyCa(
    List<Map<String, dynamic>> questionMaps,
  ) {
    SeriesSampleQuestion? best;
    var bestScore = 0;
    for (final q in questionMaps) {
      final shared = q['shared'];
      if (shared is Map && shared['has_table'] == true) continue;
      final correct = (shared is Map ? shared['correct_option'] : null)
          .toString()
          .trim()
          .toLowerCase();
      if (!const {'a', 'b', 'c', 'd'}.contains(correct)) continue;

      final meta = q['meta'] is Map
          ? Map<String, dynamic>.from(q['meta'] as Map)
          : const <String, dynamic>{};
      final concepts = _stringList(meta['concepts_used']).isNotEmpty
          ? _stringList(meta['concepts_used'])
          : _stringList(meta['ca_tags']);

      final en = _content(q['en'], concepts);
      if (en == null) continue;
      final score = _richness(q['en'] as Map);
      if (score < _minRichness || score <= bestScore) continue;

      bestScore = score;
      final gs = (meta['gs_subject'] ?? meta['subject'] ?? '')
          .toString()
          .trim();
      best = SeriesSampleQuestion(
        en: en,
        hi: _content(q['hi'], concepts),
        correctOption: correct,
        subjectLabel: gs.isEmpty ? 'Current Affairs' : gs,
        isCurrentAffairs: true,
      );
    }
    return best;
  }

  static int _richness(Map en) {
    var score = 0;
    final sa = en['statement_analysis'];
    if (sa is List && sa.isNotEmpty) score++;
    if (_stringList(en['elimination_logic']).isNotEmpty) score++;
    if (_text(en['strong_distractor']).isNotEmpty) score++;
    if (_text(en['upsc_trap_explanation']).isNotEmpty) score++;
    if (_text(en['final_explanation']).contains('Value Addition:')) score++;
    return score;
  }

  static SampleQuestionContent? _content(Object? raw, List<String> concepts) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final parsed = QuestionDisplayTextParser.parse(_text(m['display_text']));
    final options = {
      'a': parsed.optionA,
      'b': parsed.optionB,
      'c': parsed.optionC,
      'd': parsed.optionD,
    };
    if (options.values.any((o) => o.isEmpty)) return null;

    final statements = <StatementAnalysisVm>[];
    final sa = m['statement_analysis'];
    if (sa is List) {
      for (final item in sa) {
        if (item is! Map) continue;
        final verdict =
            item['is_correct'] ?? item['correct'] ?? item['verdict'];
        final v = verdict.toString().trim().toLowerCase();
        statements.add(
          StatementAnalysisVm(
            statement: (item['statement'] ?? item['label'] ?? '').toString(),
            isCorrect: verdict == true || v == 'true' || v == 'correct',
            reason: (item['reason'] ?? '').toString(),
          ),
        );
      }
    }

    return SampleQuestionContent(
      // "1. With reference to…" -> "With reference to…"
      stem: parsed.stem.replaceFirst(RegExp(r'^\s*(Q\.?\s*)?\d+[.)]\s*'), ''),
      options: options,
      translation: QuestionTranslation(
        finalExplanation: _text(m['final_explanation']),
        statementAnalysis: statements,
        eliminationLogic: _stringList(m['elimination_logic']),
        strongDistractor: _text(m['strong_distractor']),
        upscTrapExplanation: _text(m['upsc_trap_explanation']),
        conceptsUsed: concepts,
      ),
    );
  }

  static String _text(Object? v) => v == null ? '' : v.toString().trim();

  static List<String> _stringList(Object? v) => v is List
      ? [
          for (final e in v)
            if (e.toString().trim().isNotEmpty) e.toString().trim(),
        ]
      : const [];

  /// A real Modern History question, used whenever no current-affairs
  /// question is available (facts: Regulating Act 1773, Charter Act 1833).
  static const fallback = SeriesSampleQuestion(
    correctOption: 'b',
    subjectLabel: 'Modern History',
    isCurrentAffairs: false,
    en: SampleQuestionContent(
      stem: 'Who was the first Governor-General of India?',
      options: {
        'a': 'Warren Hastings',
        'b': 'Lord William Bentinck',
        'c': 'Lord Mountbatten',
        'd': 'Lord Canning',
      },
      translation: QuestionTranslation(
        finalExplanation:
            'Warren Hastings feels right because he was the first '
            'Governor-General, and he was. But of Bengal, not India. The '
            'Charter Act of 1833 reorganised British territories and created '
            'the post of Governor-General of India for the first time. '
            'Bentinck was appointed to that new, broader post.\n\n'
            'Most aspirants have memorised "Hastings = first Governor-General" '
            'without attaching the word "Bengal" to it. UPSC counts on '
            'exactly that.\n\n'
            'Value Addition: Hastings: first GG of Bengal (Regulating Act, '
            '1773); Bentinck: first GG of India (Charter Act, 1833); '
            'Mountbatten: first GG of independent India (1947); Canning: '
            'first Viceroy (1858).',
        statementAnalysis: [
          StatementAnalysisVm(
            statement: '(a) Warren Hastings',
            isCorrect: false,
            reason:
                'First Governor-General of Bengal (Regulating Act, 1773), '
                'not of India.',
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
            reason:
                'First Viceroy of India (1858), a different title after 1857.',
          ),
        ],
        eliminationLogic: [
          'Eliminate (a): Hastings held the Bengal post, not the all-India '
              'one created in 1833.',
          'Eliminate (c): Mountbatten is post-independence, a century later.',
          'Eliminate (d): Canning was the first Viceroy, a different title '
              'created after 1857.',
          'Retain (b): Bentinck is the only option tied to the Charter Act '
              'of 1833 and the all-India post.',
        ],
        strongDistractor:
            'Warren Hastings — Feels right because he was the first GG, but '
            'of Bengal, not India.',
        upscTrapExplanation:
            'Entity-Swap trap: every option is the "first" of something real. '
            'UPSC changed one word, Governor-General of Bengal vs of India, '
            'and that one word decides everything.',
        conceptsUsed: [
          'Entity-Swap',
          'Charter Act 1833',
          'Regulating Act 1773',
          'Governor-General vs Viceroy',
        ],
      ),
    ),
  );
}
