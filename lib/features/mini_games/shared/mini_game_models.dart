// Content models for all five mini-games. Field names match the JSON schemas.
// Optional `*_hi` fields enable Hindi; English is always required.

/// Difficulty tiers shared by all mini-game content.
enum MiniGameDifficulty {
  easy,
  medium,
  hard;

  static MiniGameDifficulty parse(String? raw) => switch (raw) {
    'easy' => MiniGameDifficulty.easy,
    'hard' => MiniGameDifficulty.hard,
    _ => MiniGameDifficulty.medium,
  };
}

String _miniGameText(String en, String? hi, String lang) {
  if (lang == 'hi' && hi != null && hi.trim().isNotEmpty) return hi;
  return en;
}

List<String> _miniGameList(List<String> en, List<String>? hi, String lang) {
  if (lang == 'hi' && hi != null && hi.length == en.length) return hi;
  return en;
}

String normalizeMiniGameLang(String? raw) => raw == 'hi' ? 'hi' : 'en';

class TimelineItem {
  const TimelineItem({
    required this.label,
    this.labelHi,
    required this.yearDisplay,
    required this.sortKey,
  });

  final String label;
  final String? labelHi;
  final String yearDisplay;
  final int sortKey;

  String labelForLang(String lang) => _miniGameText(label, labelHi, lang);

  factory TimelineItem.fromJson(Map<String, dynamic> json) => TimelineItem(
    label: json['label'] as String,
    labelHi: json['label_hi'] as String?,
    yearDisplay: json['year_display'] as String,
    sortKey: json['sort_key'] as int,
  );
}

class TimelineSorterSet {
  const TimelineSorterSet({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.theme,
    this.themeHi,
    required this.items,
    required this.explanation,
    this.explanationHi,
  });

  final String id;
  final String subject;
  final MiniGameDifficulty difficulty;
  final String theme;
  final String? themeHi;
  final List<TimelineItem> items;
  final String explanation;
  final String? explanationHi;

  String themeForLang(String lang) => _miniGameText(theme, themeHi, lang);

  String explanationForLang(String lang) =>
      _miniGameText(explanation, explanationHi, lang);

  factory TimelineSorterSet.fromJson(Map<String, dynamic> json) =>
      TimelineSorterSet(
        id: json['id'] as String,
        subject: json['subject'] as String,
        difficulty: MiniGameDifficulty.parse(json['difficulty'] as String?),
        theme: json['theme'] as String,
        themeHi: json['theme_hi'] as String?,
        items: (json['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TimelineItem.fromJson)
            .toList(growable: false),
        explanation: json['explanation'] as String,
        explanationHi: json['explanation_hi'] as String?,
      );
}

class OddOneOutItem {
  const OddOneOutItem({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.items,
    this.itemsHi,
    required this.oddIndex,
    required this.explanation,
    this.explanationHi,
  });

  final String id;
  final String subject;
  final MiniGameDifficulty difficulty;
  final List<String> items;
  final List<String>? itemsHi;
  final int oddIndex;
  final String explanation;
  final String? explanationHi;

  List<String> itemsForLang(String lang) => _miniGameList(items, itemsHi, lang);

  String explanationForLang(String lang) =>
      _miniGameText(explanation, explanationHi, lang);

  factory OddOneOutItem.fromJson(Map<String, dynamic> json) => OddOneOutItem(
    id: json['id'] as String,
    subject: json['subject'] as String,
    difficulty: MiniGameDifficulty.parse(json['difficulty'] as String?),
    items: (json['items'] as List<dynamic>).cast<String>(),
    itemsHi: (json['items_hi'] as List<dynamic>?)?.cast<String>(),
    oddIndex: json['odd_index'] as int,
    explanation: json['explanation'] as String,
    explanationHi: json['explanation_hi'] as String?,
  );
}

class FactOrBluffItem {
  const FactOrBluffItem({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.statement,
    this.statementHi,
    required this.isFact,
    required this.explanation,
    this.explanationHi,
  });

  final String id;
  final String subject;
  final MiniGameDifficulty difficulty;
  final String statement;
  final String? statementHi;
  final bool isFact;
  final String explanation;
  final String? explanationHi;

  String statementForLang(String lang) =>
      _miniGameText(statement, statementHi, lang);

  String explanationForLang(String lang) =>
      _miniGameText(explanation, explanationHi, lang);

  factory FactOrBluffItem.fromJson(Map<String, dynamic> json) =>
      FactOrBluffItem(
        id: json['id'] as String,
        subject: json['subject'] as String,
        difficulty: MiniGameDifficulty.parse(json['difficulty'] as String?),
        statement: json['statement'] as String,
        statementHi: json['statement_hi'] as String?,
        isFact: json['is_fact'] as bool,
        explanation: json['explanation'] as String,
        explanationHi: json['explanation_hi'] as String?,
      );
}

class ConnectTheDotsItem {
  const ConnectTheDotsItem({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.dots,
    this.dotsHi,
    required this.options,
    this.optionsHi,
    required this.answerIndex,
    required this.explanation,
    this.explanationHi,
  });

  final String id;
  final String subject;
  final MiniGameDifficulty difficulty;
  final List<String> dots;
  final List<String>? dotsHi;
  final List<String> options;
  final List<String>? optionsHi;
  final int answerIndex;
  final String explanation;
  final String? explanationHi;

  List<String> dotsForLang(String lang) => _miniGameList(dots, dotsHi, lang);

  List<String> optionsForLang(String lang) =>
      _miniGameList(options, optionsHi, lang);

  String explanationForLang(String lang) =>
      _miniGameText(explanation, explanationHi, lang);

  factory ConnectTheDotsItem.fromJson(Map<String, dynamic> json) =>
      ConnectTheDotsItem(
        id: json['id'] as String,
        subject: json['subject'] as String,
        difficulty: MiniGameDifficulty.parse(json['difficulty'] as String?),
        dots: (json['dots'] as List<dynamic>).cast<String>(),
        dotsHi: (json['dots_hi'] as List<dynamic>?)?.cast<String>(),
        options: (json['options'] as List<dynamic>).cast<String>(),
        optionsHi: (json['options_hi'] as List<dynamic>?)?.cast<String>(),
        answerIndex: json['answer_index'] as int,
        explanation: json['explanation'] as String,
        explanationHi: json['explanation_hi'] as String?,
      );
}

class DuelQuestion {
  const DuelQuestion({
    required this.id,
    required this.subject,
    required this.difficulty,
    required this.question,
    this.questionHi,
    required this.options,
    this.optionsHi,
    required this.answerIndex,
  });

  final String id;
  final String subject;
  final MiniGameDifficulty difficulty;
  final String question;
  final String? questionHi;
  final List<String> options;
  final List<String>? optionsHi;
  final int answerIndex;

  String questionForLang(String lang) =>
      _miniGameText(question, questionHi, lang);

  List<String> optionsForLang(String lang) =>
      _miniGameList(options, optionsHi, lang);

  factory DuelQuestion.fromJson(Map<String, dynamic> json) => DuelQuestion(
    id: json['id'] as String,
    subject: json['subject'] as String,
    difficulty: MiniGameDifficulty.parse(json['difficulty'] as String?),
    question: json['question'] as String,
    questionHi: json['question_hi'] as String?,
    options: (json['options'] as List<dynamic>).cast<String>(),
    optionsHi: (json['options_hi'] as List<dynamic>?)?.cast<String>(),
    answerIndex: json['answer_index'] as int,
  );
}

/// Content filter chosen before launching a game. Empty strings = no filter.
/// Both fields are comma-separated lists (subject slugs / difficulty names).
typedef MiniGameFilter = ({String subjects, String difficulties});

const MiniGameFilter emptyMiniGameFilter = (subjects: '', difficulties: '');

Set<String> _csvToSet(String csv) =>
    csv.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();

/// Draws a session from [pool]: filter by [filter] (subjects and/or
/// difficulties; empty = all), shuffle, take [count], then order by rising
/// difficulty (easy → medium → hard). Falls back to progressively wider
/// pools if a filter combination matches nothing.
List<T> drawMiniGameSession<T>({
  required List<T> pool,
  required MiniGameFilter filter,
  required int count,
  required String Function(T) subjectOf,
  required MiniGameDifficulty Function(T) difficultyOf,
}) {
  final subjects = _csvToSet(filter.subjects);
  final difficulties = _csvToSet(filter.difficulties);

  final bySubject = subjects.isEmpty
      ? List<T>.from(pool)
      : pool.where((e) => subjects.contains(subjectOf(e))).toList();
  final subjectPool = bySubject.isEmpty ? List<T>.from(pool) : bySubject;

  final byDifficulty = difficulties.isEmpty
      ? subjectPool
      : subjectPool
            .where((e) => difficulties.contains(difficultyOf(e).name))
            .toList();
  final source = byDifficulty.isEmpty ? subjectPool : byDifficulty;

  source.shuffle();
  final drawn = source.take(count).toList();
  drawn.sort((a, b) => difficultyOf(a).index.compareTo(difficultyOf(b).index));
  return drawn;
}
