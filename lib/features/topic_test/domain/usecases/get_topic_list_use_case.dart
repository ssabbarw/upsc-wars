import 'package:upsc_wars/core/domain/accuracy_rules.dart';
import 'package:upsc_wars/core/domain/entities/topic_info.dart';
import 'package:upsc_wars/core/domain/repositories/test_catalog_repository.dart';

class GetTopicListUseCase {
  GetTopicListUseCase(this._repository);

  final TestCatalogRepository _repository;

  Future<List<TopicInfo>> execute(String subject, String language) async {
    final metrics = await _repository.fetchTopicMetrics(subject, language);
    final out = <TopicInfo>[];
    for (final m in metrics) {
      final acc = AccuracyRules.accuracyPercentOrNull(
        attemptCount: m.scoredAttemptCount,
        correctCount: m.scoredCorrectCount,
      );
      out.add(
        TopicInfo(
          topic: m.topic,
          subject: m.subject,
          displayName: m.displayName,
          questionCount: m.questionCount,
          attemptCount: m.scoredAttemptCount,
          accuracyPercent: acc,
          accuracyTier: AccuracyRules.tierFor(
            attemptCount: m.scoredAttemptCount,
            accuracyPercent: acc,
          ),
        ),
      );
    }
    return out;
  }
}
