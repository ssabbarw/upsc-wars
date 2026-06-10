import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'domain/create_push_spot_test_session_use_case.dart';
import 'push_spot_test_launch_params.dart';

/// Creates a 1-question spot test and opens the test engine.
Future<void> launchPushSpotTest({
  required BuildContext context,
  required WidgetRef ref,
  String subject = '',
  String topic = '',
  String? subTopic,
  String? questionUuid,
}) async {
  final params = PushSpotTestLaunchParams(
    subject: subject,
    topic: topic,
    subTopic: subTopic,
    questionUuid: questionUuid,
  );
  final err = params.validationError;
  if (err != null) throw StateError(err);

  final uc = await ref.read(createPushSpotTestSessionUseCaseProvider.future);
  final sessionId = await uc.execute(
    subject: params.subject,
    topic: params.topic,
    subTopic: params.subTopic,
    questionUuid: params.trimmedQuestionUuid,
  );
  if (!context.mounted) return;
  context.push('/test/$sessionId');
}
