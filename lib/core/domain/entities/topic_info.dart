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
    this.dangerSureWrongLast30 = 0,
    this.dangerEducatedGuessWrongLast30 = 0,
  });

  final String topic;
  final String subject;
  final String displayName;
  final int questionCount;
  final int attemptCount;
  final double? accuracyPercent;
  final AccuracyDisplayTier accuracyTier;

  /// Wrong attempts with Sure confidence in the last 30 days (same window as subject Danger Zone).
  final int dangerSureWrongLast30;
  /// Wrong attempts with Educated-guess confidence in the last 30 days.
  final int dangerEducatedGuessWrongLast30;
}
