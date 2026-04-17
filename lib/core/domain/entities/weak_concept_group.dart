class WeakSubTopicGroup {
  const WeakSubTopicGroup({
    required this.subject,
    required this.subTopic,
    required this.failureCount,
    required this.questionUuids,
  });

  final String subject;
  final String subTopic;
  final int failureCount;
  final List<String> questionUuids;
}
