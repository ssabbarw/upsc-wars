import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';

/// When to show the confidence sheet so we do not ask on every easy question forever.
abstract final class ConfidencePromptPolicy {
  static const int earlyLearnerMaxScoredAttempts = 125;

  static const _hardTypes = {
    'multi-statement-correct',
    'multi-statement-incorrect',
    'assertion-reason',
    'match-the-column',
    'two-statement-relationship',
    'quantitative-pairing',
  };

  static bool shouldPrompt({
    required PrefsService prefs,
    required TestQuestion question,
    required ActiveSession session,
    required int lifetimeScoredAttempts,
    required Set<String> weakTopicKeys,
  }) {
    if (!prefs.confidenceTrackingEnabled) return false;

    if (lifetimeScoredAttempts < earlyLearnerMaxScoredAttempts) return true;

    final subj = session.subject.toLowerCase();
    if (subj.contains('pyq')) return true;

    if (session.subject == 'revision' || session.subject == 'revision_quick') {
      return true;
    }

    final trapHeavy =
        (question.trapType != null && question.trapType!.trim().isNotEmpty) ||
        question.negativeFraming;
    if (trapHeavy) return true;

    final qt = question.questionType?.toLowerCase() ?? '';
    if (_hardTypes.contains(qt)) return true;

    final key = '${question.subject}||${question.topic}';
    if (weakTopicKeys.contains(key)) return true;

    return false;
  }
}
