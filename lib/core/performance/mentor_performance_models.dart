// ignore_for_file: public_member_api_docs

/// Readiness band shown on the performance home hero.
enum ReadinessBand { critical, needsWork, improving, strong, examReady }

class ReadinessSnapshot {
  const ReadinessSnapshot({
    required this.score,
    required this.band,
    this.scoreChangeReasons = const [],
  });

  final int score;
  final ReadinessBand band;
  final List<String> scoreChangeReasons;
}

class QuickSnapshot {
  const QuickSnapshot({
    required this.overallAccuracyPercent,
    required this.dangerousMistakesCount,
    required this.smartGuessAccuracyPercent,
    required this.smartGuessAttempted,
    required this.revisionPendingCount,
    this.strongestSubject,
    this.weakestSubject,
  });

  final double overallAccuracyPercent;
  final int dangerousMistakesCount;
  final double smartGuessAccuracyPercent;
  final int smartGuessAttempted;
  final int revisionPendingCount;
  final String? strongestSubject;
  final String? weakestSubject;
}

class RevisionTopicRow {
  const RevisionTopicRow({required this.topic, required this.subject});

  final String topic;
  final String subject;
}

class SubjectMentorCard {
  const SubjectMentorCard({
    required this.subject,
    required this.statusLine,
    required this.healthScore,
    required this.oneLineInsight,
  });

  final String subject;
  final String statusLine;
  final int healthScore;
  final String oneLineInsight;
}

class OverallPerformanceView {
  const OverallPerformanceView({
    required this.readiness,
    required this.quick,
    this.focusThisWeek,
    required this.subjectCards,
    required this.focusRevisionTopics,
  });

  final ReadinessSnapshot readiness;
  final QuickSnapshot quick;
  final String? focusThisWeek;
  final List<SubjectMentorCard> subjectCards;
  final List<RevisionTopicRow> focusRevisionTopics;
}

class WeeklyMentorReport {
  const WeeklyMentorReport({
    this.readinessDelta,
    this.improvedSubjects = const [],
    this.slippingSubjects = const [],
    this.biggestRiskLine = '',
  });

  final int? readinessDelta;
  final List<String> improvedSubjects;
  final List<String> slippingSubjects;
  final String biggestRiskLine;
}

class SubjectMentorAnalysis {
  const SubjectMentorAnalysis();
}

class TrendPoint {
  const TrendPoint(this.value);
  final double value;
}

class TopicZones {
  const TopicZones({
    required this.sureWrong,
    required this.educatedWrong,
    required this.sureCorrect,
    required this.educatedCorrect,
    required this.pureGuessCorrect,
    required this.pureGuessWrong,
  });

  final int sureWrong;
  final int educatedWrong;
  final int sureCorrect;
  final int educatedCorrect;
  final int pureGuessCorrect;
  final int pureGuessWrong;
}

class TopicMentorAnalysis {
  const TopicMentorAnalysis({
    required this.statusHeadline,
    required this.riskReasonLines,
    required this.whyCopy,
    required this.zones,
    required this.recommendedAction,
    required this.correctWrongTrend14d,
  });

  final String statusHeadline;
  final List<String> riskReasonLines;
  final String whyCopy;
  final TopicZones zones;
  final String recommendedAction;
  final List<TrendPoint> correctWrongTrend14d;
}
