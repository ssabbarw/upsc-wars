import 'dart:math' as math;

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import 'session_insight_case.dart';

/// Marks lost per topic from sure/educated wrong answers in a session.
class TopicMarksLost {
  const TopicMarksLost({
    required this.topic,
    required this.marksLost,
    required this.wrongCount,
  });

  final String topic;
  final double marksLost;
  final int wrongCount;
}

/// Computes per-topic marks lost (Sure + Educated wrong × 0.66).
List<TopicMarksLost> computeTopicMarksLost(List<TestQuestion> questions) {
  final map = <String, ({int wrong, double marks})>{};
  for (final q in questions) {
    if (q.status != 'wrong') continue;
    if (!AnswerConfidence.isDangerouslyConfident(q.confidence)) continue;
    final prev = map[q.topic] ?? (wrong: 0, marks: 0.0);
    map[q.topic] = (
      wrong: prev.wrong + 1,
      marks: prev.marks + kPrelimsWrongMarkPenalty,
    );
  }
  return map.entries
      .map(
        (e) => TopicMarksLost(
          topic: e.key,
          marksLost: e.value.marks,
          wrongCount: e.value.wrong,
        ),
      )
      .toList()
    ..sort((a, b) => b.marksLost.compareTo(a.marksLost));
}

/// Top risk topic by marks lost in this session.
({String topic, double marksLost, int pctOfLoss})? topRiskTopicByMarksLost(
  List<TopicMarksLost> rows,
) {
  if (rows.isEmpty) return null;
  final total = rows.fold<double>(0, (s, r) => s + r.marksLost);
  if (total <= 0) return null;
  final top = rows.first;
  final pct = (100 * top.marksLost / total).round().clamp(0, 100);
  return (topic: top.topic, marksLost: top.marksLost, pctOfLoss: pct);
}

/// Top N topics for collapsed UI (by marks lost, then attempted).
List<TopicMarksLost> topTopicsForDisplay(
  List<TopicMarksLost> marksRows,
  List<({String topic, int correct, int attempted})> accuracyRows, {
  int limit = 3,
}) {
  if (marksRows.isNotEmpty) {
    return marksRows.take(limit).toList();
  }
  return accuracyRows
      .take(limit)
      .map(
        (r) => TopicMarksLost(
          topic: r.topic,
          marksLost: 0,
          wrongCount: r.attempted - r.correct,
        ),
      )
      .toList();
}

/// Topics with at least one attempt, highest accuracy first.
List<({String topic, int correct, int attempted})> topicsSortedByAccuracyDesc(
  List<({String topic, int correct, int attempted})> rows,
) {
  final filtered = rows.where((r) => r.attempted > 0).toList()
    ..sort((a, b) {
      final accA = a.correct / a.attempted;
      final accB = b.correct / b.attempted;
      final cmp = accB.compareTo(accA);
      if (cmp != 0) return cmp;
      return b.attempted.compareTo(a.attempted);
    });
  return filtered;
}

/// Topics with at least one attempt, lowest accuracy first.
List<({String topic, int correct, int attempted})> topicsSortedByWorstAccuracy(
  List<({String topic, int correct, int attempted})> rows,
) {
  final filtered = rows.where((r) => r.attempted > 0).toList()
    ..sort((a, b) {
      final accA = a.correct / a.attempted;
      final accB = b.correct / b.attempted;
      final cmp = accA.compareTo(accB);
      if (cmp != 0) return cmp;
      return b.attempted.compareTo(a.attempted);
    });
  return filtered;
}

double topicRowAccuracyPercent(
  ({String topic, int correct, int attempted}) row,
) {
  if (row.attempted <= 0) return 0;
  return (100 * row.correct / row.attempted).clamp(0.0, 100.0);
}

double topicAccuracyPercent(
  List<({String topic, int correct, int attempted})> rows,
  String topic,
) {
  for (final r in rows) {
    if (r.topic == topic && r.attempted > 0) {
      return (100 * r.correct / r.attempted).clamp(0.0, 100.0);
    }
  }
  return 0;
}

({String topic, int correct, int attempted})? pickWeakestTopicForCoach(
  List<({String topic, int correct, int attempted})> rows,
) {
  if (rows.isEmpty) return null;
  ({String topic, int correct, int attempted})? worst;
  for (final r in rows) {
    if (r.attempted < 1) continue;
    final acc = r.correct / r.attempted;
    if (worst == null || acc < worst.correct / worst.attempted) {
      worst = r;
    }
  }
  return worst;
}

int displayQuestionCount(int n) => math.max(0, n);
