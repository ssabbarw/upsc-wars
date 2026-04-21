enum OpenChallengeExamKind { create, accept }

/// Registered before navigating to [TestEngineScreen], keyed by session id.
class OpenChallengeExamContext {
  const OpenChallengeExamContext({
    required this.kind,
    required this.sessionId,
    required this.subjectDisplay,
    required this.questionUuids,
    this.existingChallengeId,
  });

  final OpenChallengeExamKind kind;
  final String sessionId;
  final String subjectDisplay;
  final List<String> questionUuids;

  /// For [OpenChallengeExamKind.accept] — Firestore document id.
  final String? existingChallengeId;
}
