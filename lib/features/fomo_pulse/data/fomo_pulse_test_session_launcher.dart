import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/question_bank_upsert.dart';
import '../../../core/database/user_db.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../test_engine/domain/usecases/create_session_use_case.dart';
import '../domain/fomo_pulse_models.dart';

const fomoPulseLearningAnalyticsKey = 'fomo_pulse_learning';

class FomoPulseTestSessionLauncher {
  FomoPulseTestSessionLauncher({
    required this.userDb,
    required this.createSession,
    required this.prefs,
  }) : _upsert = QuestionBankUpsert(userDb);

  final UserDatabase userDb;
  final CreateSessionUseCase createSession;
  final PrefsService prefs;
  final QuestionBankUpsert _upsert;

  Future<String> createLearningSession(FomoPulse pulse) async {
    final q = pulse.question;
    final displayEn = _displayText(
      q.displayText,
      q.optionA,
      q.optionB,
      q.optionC,
      q.optionD,
    );
    final displayHi = _displayText(
      q.displayTextHi,
      q.optionAHi,
      q.optionBHi,
      q.optionCHi,
      q.optionDHi,
    );

    final map = <String, dynamic>{
      'uuid': pulse.pulseId,
      'meta': {
        'gs_subject': q.gsSubject.trim().isEmpty
            ? 'Current Affairs'
            : q.gsSubject,
        'topic': q.topic.trim().isEmpty ? 'FOMO Pulse' : q.topic,
        'sub_topic': 'FOMO Pulse',
      },
      'shared': {
        'question_type': 'direct',
        'correct_option': q.correctOption.toLowerCase(),
      },
      'en': {
        'display_text': displayEn,
        'final_explanation': q.finalExplanation,
        'strong_distractor': '',
        'elimination_logic': const <String>[],
        'upsc_trap_explanation': '',
      },
    };
    if (displayHi.trim().isNotEmpty || q.finalExplanationHi.trim().isNotEmpty) {
      map['hi'] = {
        'display_text': displayHi.trim().isEmpty ? displayEn : displayHi,
        'final_explanation': q.finalExplanationHi.trim().isEmpty
            ? q.finalExplanation
            : q.finalExplanationHi,
        'strong_distractor': '',
        'elimination_logic': const <String>[],
        'upsc_trap_explanation': '',
      };
    }

    await _upsert.applyCorrections([map]);

    return createSession.execute(
      SessionConfig(
        subject: q.gsSubject.trim().isEmpty ? 'Current Affairs' : q.gsSubject,
        topic: q.topic.trim().isEmpty ? 'FOMO Pulse' : q.topic,
        subTopic: 'FOMO Pulse',
        mode: 'learning',
        questionCount: 1,
        isTimed: false,
        language: normalizeAppLanguage(prefs.language),
        specificQuestionUuids: [pulse.pulseId],
        analyticsFeatureKey: fomoPulseLearningAnalyticsKey,
      ),
    );
  }

  static String _displayText(
    String stem,
    String a,
    String b,
    String c,
    String d,
  ) {
    final s = stem.trim();
    final aa = a.trim();
    final bb = b.trim();
    final cc = c.trim();
    final dd = d.trim();
    return [
      if (s.isNotEmpty) s,
      if (aa.isNotEmpty) '(a) $aa',
      if (bb.isNotEmpty) '(b) $bb',
      if (cc.isNotEmpty) '(c) $cc',
      if (dd.isNotEmpty) '(d) $dd',
    ].join('\n');
  }
}

final fomoPulseTestSessionLauncherProvider =
    FutureProvider<FomoPulseTestSessionLauncher>((ref) async {
      final userDb = ref.watch(userDatabaseProvider);
      final createSession = await ref.watch(
        createSessionUseCaseProvider.future,
      );
      final prefs = await ref.watch(prefsServiceProvider.future);
      return FomoPulseTestSessionLauncher(
        userDb: userDb,
        createSession: createSession,
        prefs: prefs,
      );
    });
