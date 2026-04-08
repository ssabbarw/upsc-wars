/// Thrown when a session id does not exist in the user database.
class SessionNotFoundException implements Exception {
  const SessionNotFoundException();
}

/// Thrown when a session has no loadable questions (data inconsistency).
class SessionHasNoQuestionsException implements Exception {
  const SessionHasNoQuestionsException();
}
