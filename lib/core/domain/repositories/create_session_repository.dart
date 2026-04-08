import '../entities/session_config.dart';

abstract class CreateSessionRepository {
  Future<String> createSession(SessionConfig config);
}
