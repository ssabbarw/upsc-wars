import '../entities/session_config.dart';

abstract class CreateSessionRepository {
  Future<String> createSession(SessionConfig config);

  /// Inserts a session with a fixed id and [SessionConfig.specificQuestionUuids]
  /// (joiner importing a host's battle). No-op if the session id already exists.
  Future<void> importSessionWithFixedId({
    required String sessionId,
    required SessionConfig config,
  });
}
