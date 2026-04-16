import 'accuracy_display_tier.dart';

class SubjectInfo {
  const SubjectInfo({
    required this.subject,
    required this.displayName,
    required this.questionCount,
    required this.topicCount,
    required this.attemptCount,
    required this.accuracyPercent,
    required this.accuracyTier,
  });

  final String subject;
  final String displayName;
  final int questionCount;
  final int topicCount;

  /// Scored attempts (correct + wrong rows) attributed to this subject.
  final int attemptCount;

  /// Null when [attemptCount] == 0.
  final double? accuracyPercent;

  final AccuracyDisplayTier accuracyTier;
}
