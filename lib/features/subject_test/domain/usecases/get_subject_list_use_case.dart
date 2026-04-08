import 'package:upsc_wars/core/constants/subject_constants.dart';
import 'package:upsc_wars/core/domain/accuracy_rules.dart';
import 'package:upsc_wars/core/domain/entities/subject_info.dart';
import 'package:upsc_wars/core/domain/repositories/test_catalog_repository.dart';

class GetSubjectListUseCase {
  GetSubjectListUseCase(this._repository);

  final TestCatalogRepository _repository;

  Future<List<SubjectInfo>> execute(String language) async {
    final metrics = await _repository.fetchSubjectMetrics(language);
    final bySlug = {for (final m in metrics) m.subjectSlug: m};
    return [
      for (final def in SubjectConstants.ordered)
        _mapSubject(def, bySlug[def.slug]),
    ];
  }

  SubjectInfo _mapSubject(SubjectDefinition def, SubjectMetrics? m) {
    final metrics = m ??
        SubjectMetrics(
          subjectSlug: def.slug,
          questionCount: 0,
          topicCount: 0,
          scoredAttemptCount: 0,
          scoredCorrectCount: 0,
        );
    final attempts = metrics.scoredAttemptCount;
    final acc = AccuracyRules.accuracyPercentOrNull(
      attemptCount: attempts,
      correctCount: metrics.scoredCorrectCount,
    );
    final tier = AccuracyRules.tierFor(
      attemptCount: attempts,
      accuracyPercent: acc,
    );
    return SubjectInfo(
      subjectSlug: def.slug,
      displayName: def.displayName,
      questionCount: metrics.questionCount,
      topicCount: metrics.topicCount,
      attemptCount: attempts,
      accuracyPercent: acc,
      accuracyTier: tier,
    );
  }
}
