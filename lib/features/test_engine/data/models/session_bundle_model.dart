import 'package:upsc_wars/core/database/question_db.dart';
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
  final List<QuestionRow> questionRows;
  final Map<String, QuestionTranslationRow> translations;
}
