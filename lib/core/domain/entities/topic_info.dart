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
    this.dangerSureWrong = 0,
    this.dangerEducatedGuessWrong = 0,
  });

  final String topic;
  final String subject;
  final String displayName;
  final int questionCount;
  final int attemptCount;
  final double? accuracyPercent;
  final AccuracyDisplayTier accuracyTier;

  /// Wrong attempts with Sure confidence (lifetime; same definition as subject Danger Zone).
  final int dangerSureWrong;

  /// Wrong attempts with Educated-guess confidence (lifetime).
  final int dangerEducatedGuessWrong;

  TopicInfo copyWith({String? displayName}) {
    return TopicInfo(
      topic: topic,
      subject: subject,
      displayName: displayName ?? this.displayName,
      questionCount: questionCount,
      attemptCount: attemptCount,
      accuracyPercent: accuracyPercent,
      accuracyTier: accuracyTier,
      dangerSureWrong: dangerSureWrong,
      dangerEducatedGuessWrong: dangerEducatedGuessWrong,
    );
  }
}
