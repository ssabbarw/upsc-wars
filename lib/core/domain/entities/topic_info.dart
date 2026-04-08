import 'accuracy_display_tier.dart';

class TopicInfo {
  const TopicInfo({
    required this.topicSlug,
    required this.subjectSlug,
    required this.displayName,
    required this.questionCount,
    required this.attemptCount,
    required this.accuracyPercent,
    required this.accuracyTier,
  });

  final String topicSlug;
  final String subjectSlug;
  final String displayName;
  final int questionCount;
  final int attemptCount;
  final double? accuracyPercent;
  final AccuracyDisplayTier accuracyTier;
}
