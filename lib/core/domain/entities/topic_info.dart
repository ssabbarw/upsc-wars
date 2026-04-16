import 'accuracy_display_tier.dart';

class TopicInfo {
  const TopicInfo({
    required this.topic,
    required this.subject,
    required this.displayName,
    required this.questionCount,
    required this.attemptCount,
    required this.accuracyPercent,
    required this.accuracyTier,
  });

  final String topic;
  final String subject;
  final String displayName;
  final int questionCount;
  final int attemptCount;
  final double? accuracyPercent;
  final AccuracyDisplayTier accuracyTier;
}
