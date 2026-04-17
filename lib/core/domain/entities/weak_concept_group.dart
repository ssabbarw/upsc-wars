class WeakSubTopicGroup {
  const WeakSubTopicGroup({
    required this.subTopic,
    required this.failureCount,
    required this.questionUuids,
  });

  final String subTopic;
  final int failureCount;
  final List<String> questionUuids;
}
