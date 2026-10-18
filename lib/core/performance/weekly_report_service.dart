import 'mentor_performance_models.dart';

class WeeklyReportService {
  WeeklyReportService();

  Future<WeeklyMentorReport> build() async {
    // Placeholder: delta / improved / slipping from week-over-week can be added later.
    return WeeklyMentorReport(
      readinessDelta: null,
      biggestRiskLine:
          'Keep logging attempts with confidence to sharpen trends.',
    );
  }
}
