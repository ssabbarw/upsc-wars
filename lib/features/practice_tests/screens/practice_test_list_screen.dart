import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'practice_subject_screen.dart';
import 'practice_topic_screen.dart';

class PracticeTestListScreen extends ConsumerWidget {
  const PracticeTestListScreen({super.key, required this.subject, this.topic});

  final String subject;
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (topic == null) {
      return PracticeSubjectScreen(subject: subject);
    }
    return PracticeTopicScreen(subject: subject, topic: topic!);
  }
}
