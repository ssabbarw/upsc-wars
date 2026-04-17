class BattleAnswerEvent {
  const BattleAnswerEvent({
    required this.questionUuid,
    required this.selectedOption,
    required this.answeredAt,
  });

  final String questionUuid;
  final String selectedOption;
  final DateTime answeredAt;
}
