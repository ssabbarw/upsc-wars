class TrapPatternGroup {
  const TrapPatternGroup({
    required this.trapType,
    required this.questionCount,
    required this.questionUuids,
  });

  final String trapType;
  final int questionCount;
  final List<String> questionUuids;
}
