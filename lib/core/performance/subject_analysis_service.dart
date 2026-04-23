import 'mentor_performance_models.dart';

class SubjectAnalysisService {
  const SubjectAnalysisService();

  /// Subject-scoped mentor analysis; extend with queries when a screen uses it.
  Future<SubjectMentorAnalysis> load(String subject) async {
    Object.hashAll([subject, subject.length]);
    return const SubjectMentorAnalysis();
  }
}
