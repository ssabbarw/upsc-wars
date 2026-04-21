import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'open_challenge_exam_context.dart';

/// In-memory bridge between session creation and [ResultsScreen].
final openChallengeExamRegistryProvider =
    Provider<OpenChallengeExamRegistry>((ref) {
  return OpenChallengeExamRegistry();
});

final class OpenChallengeExamRegistry {
  final _bySessionId = <String, OpenChallengeExamContext>{};

  void register(OpenChallengeExamContext ctx) {
    _bySessionId[ctx.sessionId] = ctx;
  }

  OpenChallengeExamContext? peek(String sessionId) => _bySessionId[sessionId];

  OpenChallengeExamContext? take(String sessionId) =>
      _bySessionId.remove(sessionId);
}
