/// One topic to highlight before mocks (confident wrongs, lifetime).
class ReviseBeforeMockRow {
  const ReviseBeforeMockRow({
    required this.topicKey,
    required this.displayName,
    required this.sureWrong,
    required this.educatedGuessWrong,
  });

  final String topicKey;
  final String displayName;
  final int sureWrong;
  final int educatedGuessWrong;

  int get totalWrong => sureWrong + educatedGuessWrong;
}

/// Topic where confident answers land right more often than the user's global baseline.
class SafeAreaRow {
  const SafeAreaRow({
    required this.topicKey,
    required this.displayName,
    required this.confidentTotal,
    required this.confidentCorrect,
    required this.ratePercent,
    required this.globalRatePercent,
  });

  final String topicKey;
  final String displayName;
  final int confidentTotal;
  final int confidentCorrect;
  /// 0–100, one decimal where useful
  final double ratePercent;
  final double globalRatePercent;
}

/// Data for the two "mock prep" insight cards on the subject screen.
class SubjectMockPrepInsights {
  const SubjectMockPrepInsights({
    required this.reviseTopics,
    required this.safeTopics,
    required this.globalConfidentRatePercent,
    required this.globalConfidentMistakeRatePercent,
  });

  final List<ReviseBeforeMockRow> reviseTopics;
  final List<SafeAreaRow> safeTopics;
  /// Share of (very_sure + somewhat_sure) scored attempts that are **correct**, all subjects. Null if none.
  final double? globalConfidentRatePercent;
  /// Share of those same attempts that are **wrong**, all subjects. Null if none.
  final double? globalConfidentMistakeRatePercent;

  bool get hasReviseData => reviseTopics.isNotEmpty;
  bool get hasSafeData => safeTopics.isNotEmpty;
}
