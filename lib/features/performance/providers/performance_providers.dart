import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/performance/mentor_performance_models.dart';
import '../../../core/performance/overall_performance_service.dart';
import '../../../core/performance/performance_queries.dart';
import '../../../core/performance/subject_analysis_service.dart';
import '../../../core/performance/topic_analysis_service.dart';
import '../../../core/performance/weekly_report_service.dart';
import '../../../core/providers/user_database_provider.dart';

/// Home tab: overall view + weekly mentor copy for "why score changed".
final performanceHomeBundleProvider =
    FutureProvider.autoDispose<PerformanceHomeBundle>((ref) async {
      final db = ref.watch(userDatabaseProvider);
      final view = await OverallPerformanceService(db).load();
      final week = await WeeklyReportService().build();
      final reasons = _mergeReadinessReasons(view.readiness, week);
      return PerformanceHomeBundle(
        view: _withReadinessReasons(view, reasons),
        week: week,
      );
    });

List<String> _mergeReadinessReasons(
  ReadinessSnapshot readiness,
  WeeklyMentorReport week,
) {
  final out = <String>[];
  final d = week.readinessDelta;
  if (d != null && d != 0) {
    out.add(
      d > 0
          ? '+$d vs last week on recent attempt quality.'
          : '$d vs last week — recent attempts dipped; see focus below.',
    );
  }
  if (week.improvedSubjects.isNotEmpty) {
    out.add('Improving: ${week.improvedSubjects.join(', ')}.');
  }
  if (week.slippingSubjects.isNotEmpty) {
    out.add('Slipping: ${week.slippingSubjects.join(', ')}.');
  }
  if (week.biggestRiskLine.isNotEmpty) {
    out.add(week.biggestRiskLine);
  }
  if (readiness.scoreChangeReasons.isNotEmpty) {
    out.addAll(readiness.scoreChangeReasons);
  }
  return out;
}

OverallPerformanceView _withReadinessReasons(
  OverallPerformanceView view,
  List<String> reasons,
) {
  return OverallPerformanceView(
    readiness: ReadinessSnapshot(
      score: view.readiness.score,
      band: view.readiness.band,
      scoreChangeReasons: reasons,
    ),
    quick: view.quick,
    focusThisWeek: view.focusThisWeek,
    subjectCards: view.subjectCards,
    focusRevisionTopics: view.focusRevisionTopics,
  );
}

class PerformanceHomeBundle {
  const PerformanceHomeBundle({required this.view, required this.week});

  final OverallPerformanceView view;
  final WeeklyMentorReport week;
}

final performanceSubjectAnalysisProvider = FutureProvider.autoDispose
    .family<SubjectMentorAnalysis, String>((ref, subject) async {
      return SubjectAnalysisService().load(subject);
    });

/// Use [performanceTopicKey] to build the family argument.
final performanceTopicMentorProvider = FutureProvider.autoDispose
    .family<TopicMentorAnalysis, String>((ref, topicKey) async {
      final decoded = decodePerformanceTopicKey(topicKey);
      final db = ref.watch(userDatabaseProvider);
      return TopicAnalysisService(db).load(decoded.subject, decoded.topic);
    });

/// Stable key for Riverpod (subject and topic may contain odd characters).
String performanceTopicKey(String subject, String topic) =>
    '${subject.length}\x1F$subject\x1F$topic';

({String subject, String topic}) decodePerformanceTopicKey(String key) {
  final first = key.indexOf('\x1F');
  if (first < 0) return (subject: '', topic: '');
  final len = int.tryParse(key.substring(0, first)) ?? 0;
  final rest = key.substring(first + 1);
  if (len <= 0 || len > rest.length) return (subject: '', topic: '');
  final subject = rest.substring(0, len);
  final topic = rest.length > len + 1 ? rest.substring(len + 1) : '';
  return (subject: subject, topic: topic);
}

final performanceSubjectTopicStatusesProvider = FutureProvider.autoDispose
    .family<List<({String topic, String status})>, String>((
      ref,
      subject,
    ) async {
      final db = ref.watch(userDatabaseProvider);
      final rollups = await topicRollupsForSubject(db, subject);
      final out = <({String topic, String status})>[];
      for (final r in rollups) {
        final acc = r.attempted == 0 ? 0.0 : r.correct / r.attempted;
        final sureN = r.sureCorrect + r.sureWrong;
        final sureWrongRate = sureN == 0 ? 0.0 : r.sureWrong / sureN;
        String status;
        if (sureWrongRate >= 0.35 && r.sureWrong >= 2) {
          status = 'High risk';
        } else if (acc < 0.5 && r.attempted >= 5) {
          status = 'Weak';
        } else if (acc >= 0.65 && r.sureWrong <= 1) {
          status = 'Strong';
        } else {
          status = 'Mixed';
        }
        out.add((topic: r.topic, status: status));
      }
      out.sort((a, b) => a.topic.compareTo(b.topic));
      return out;
    });
