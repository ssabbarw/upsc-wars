import 'package:upsc_wars/core/database/user_db.dart';

class SessionBundleModel {
  const SessionBundleModel({
    required this.session,
    required this.sessionQuestions,
    required this.questionRows,
    required this.translations,
  });

  final Session session;
  final List<SessionQuestion> sessionQuestions;
  final List<Question> questionRows;
  final Map<String, QuestionTranslation> translations;
}
