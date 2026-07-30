// Content models for all five mini-games. Field names match the JSON schemas.

class TimelineItem {
  const TimelineItem({
    required this.label,
    required this.yearDisplay,
    required this.sortKey,
  });

  final String label;
  final String yearDisplay;
  final int sortKey;

  factory TimelineItem.fromJson(Map<String, dynamic> json) => TimelineItem(
        label: json['label'] as String,
        yearDisplay: json['year_display'] as String,
        sortKey: json['sort_key'] as int,
      );
}

class TimelineSorterSet {
  const TimelineSorterSet({
    required this.id,
    required this.subject,
    required this.theme,
    required this.items,
    required this.explanation,
  });

  final String id;
  final String subject;
  final String theme;
  final List<TimelineItem> items;
  final String explanation;

  factory TimelineSorterSet.fromJson(Map<String, dynamic> json) =>
      TimelineSorterSet(
        id: json['id'] as String,
        subject: json['subject'] as String,
        theme: json['theme'] as String,
        items: (json['items'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TimelineItem.fromJson)
            .toList(growable: false),
        explanation: json['explanation'] as String,
      );
}

class OddOneOutItem {
  const OddOneOutItem({
    required this.id,
    required this.subject,
    required this.items,
    required this.oddIndex,
    required this.explanation,
  });

  final String id;
  final String subject;
  final List<String> items;
  final int oddIndex;
  final String explanation;

  factory OddOneOutItem.fromJson(Map<String, dynamic> json) => OddOneOutItem(
        id: json['id'] as String,
        subject: json['subject'] as String,
        items: (json['items'] as List<dynamic>).cast<String>(),
        oddIndex: json['odd_index'] as int,
        explanation: json['explanation'] as String,
      );
}

class FactOrBluffItem {
  const FactOrBluffItem({
    required this.id,
    required this.subject,
    required this.statement,
    required this.isFact,
    required this.explanation,
  });

  final String id;
  final String subject;
  final String statement;
  final bool isFact;
  final String explanation;

  factory FactOrBluffItem.fromJson(Map<String, dynamic> json) =>
      FactOrBluffItem(
        id: json['id'] as String,
        subject: json['subject'] as String,
        statement: json['statement'] as String,
        isFact: json['is_fact'] as bool,
        explanation: json['explanation'] as String,
      );
}

class ConnectTheDotsItem {
  const ConnectTheDotsItem({
    required this.id,
    required this.subject,
    required this.dots,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String id;
  final String subject;
  final List<String> dots;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  factory ConnectTheDotsItem.fromJson(Map<String, dynamic> json) =>
      ConnectTheDotsItem(
        id: json['id'] as String,
        subject: json['subject'] as String,
        dots: (json['dots'] as List<dynamic>).cast<String>(),
        options: (json['options'] as List<dynamic>).cast<String>(),
        answerIndex: json['answer_index'] as int,
        explanation: json['explanation'] as String,
      );
}

class DuelQuestion {
  const DuelQuestion({
    required this.id,
    required this.subject,
    required this.question,
    required this.options,
    required this.answerIndex,
  });

  final String id;
  final String subject;
  final String question;
  final List<String> options;
  final int answerIndex;

  factory DuelQuestion.fromJson(Map<String, dynamic> json) => DuelQuestion(
        id: json['id'] as String,
        subject: json['subject'] as String,
        question: json['question'] as String,
        options: (json['options'] as List<dynamic>).cast<String>(),
        answerIndex: json['answer_index'] as int,
      );
}
