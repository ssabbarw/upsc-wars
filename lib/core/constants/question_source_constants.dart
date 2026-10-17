/// Question pool classification and session tagging for PYQ / daily CA.
abstract final class QuestionSourceConstants {
  QuestionSourceConstants._();

  static const String kindStatic = 'static';
  static const String kindPyq = 'pyq';
  static const String kindCurrentAffairs = 'current_affairs';

  /// Session [Sessions.subject] for the daily current-affairs feature.
  static const String dailyCaSessionSubject = 'daily_ca';

  /// Session [Sessions.subject] for paid Test Series attempts.
  static const String testSeriesSessionSubject = 'test_series';

  /// Session [Sessions.topic] for subject-wise current-affairs drills.
  static const String subjectCaSessionTopic = 'current_affairs';

  /// Session [Sessions.topic] for subject-wise PYQ drills.
  static const String subjectPyqSessionTopic = 'pyq';

  static const String analyticsDailyCurrentAffairs = 'daily_current_affairs';
  static const String analyticsDailyCurrentAffairsRevise =
      'daily_current_affairs_revise';
  static const String analyticsSubjectCurrentAffairs = 'subject_current_affairs';
  static const String analyticsSubjectPyq = 'subject_pyq';

  /// Scored Test Series attempt (also stored with series_id / series_test_id).
  static const String analyticsTestSeries = 'test_series';

  /// Unscored practice re-attempt of a Test Series test.
  static const String analyticsTestSeriesPractice = 'test_series_practice';

  /// Maps pipeline / PYQ labels to app GS subject slugs.
  static const Map<String, String> gsSubjectSlugMap = {
    'Ancient History': 'Ancient History',
    'Medieval History': 'Medieval History',
    'Modern History': 'Modern History',
    'Indian Polity & Governance': 'Polity',
    'Indian Polity': 'Polity',
    'Polity': 'Polity',
    'Indian Economy': 'Economy',
    'Economy': 'Economy',
    'Environment & Ecology': 'Environment',
    'Environment': 'Environment',
    'Science & Technology': 'Science & Technology',
    'Geography': 'Geography',
    'International Relations': 'International Relations',
    'Art & Culture': 'Art and Culture',
    'Art and Culture': 'Art and Culture',
    'Social Issues': 'Social Issues',
    'Internal Security': 'Internal Security',
    'Current affairs': 'Current affairs',
    'Current Affairs': 'Current affairs',
  };

  static String normalizeGsSubject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'General Studies';
    return gsSubjectSlugMap[trimmed] ?? trimmed;
  }

  /// Normalizes LLM / Firestore question types to SQLite values.
  static String normalizeQuestionType(String? raw) {
    final t = (raw ?? '').trim();
    if (t == 'multi-statement') return 'multi-statement-correct';
    if (t == 'statement-based') return 'multi-statement-correct';
    return t.isEmpty ? 'direct' : t;
  }
}
