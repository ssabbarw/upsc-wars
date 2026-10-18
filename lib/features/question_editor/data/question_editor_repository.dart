import '../../../core/database/question_bank_upsert.dart';
import '../../../core/database/user_db.dart';
import '../../../core/services/question_corrections_sync_service.dart';
import '../../test_engine/domain/repositories/test_engine_repository.dart';
import '../domain/question_editor_draft.dart';
import 'question_correction_mapper.dart';
import 'question_correction_publish_service.dart';

class QuestionSearchHit {
  const QuestionSearchHit({
    required this.uuid,
    required this.preview,
    required this.subject,
  });

  final String uuid;
  final String preview;
  final String subject;
}

class QuestionTextSearchResult {
  const QuestionTextSearchResult({
    required this.first,
    required this.totalMatches,
  });

  final Question? first;
  final int totalMatches;
}

class QuestionEditorLoadBundle {
  const QuestionEditorLoadBundle({required this.row, required this.draft});

  final Question row;
  final QuestionEditorDraft draft;
}

class QuestionEditorRepository {
  QuestionEditorRepository({
    required UserDatabase db,
    required TestEngineRepository testEngine,
    QuestionCorrectionPublishService? publishService,
    QuestionCorrectionsSyncService? syncService,
  }) : _db = db,
       _testEngine = testEngine,
       _publish = publishService ?? QuestionCorrectionPublishService(),
       _upsert = QuestionBankUpsert(db),
       _syncService = syncService;

  final UserDatabase _db;
  final TestEngineRepository _testEngine;
  final QuestionCorrectionPublishService _publish;
  final QuestionBankUpsert _upsert;
  final QuestionCorrectionsSyncService? _syncService;

  Future<List<QuestionSearchHit>> searchByUuidPrefix(String prefix) async {
    final rows = await _db.questionsDao.searchUuidsByPrefix(prefix);
    return rows
        .map(
          (q) => QuestionSearchHit(
            uuid: q.uuid,
            preview: _previewText(q.enDisplayText),
            subject: q.subject,
          ),
        )
        .toList();
  }

  Future<QuestionTextSearchResult> searchByTextSnippet(String snippet) async {
    final first = await _db.questionsDao.findFirstByDisplayTextSnippet(snippet);
    final count = await _db.questionsDao.countByDisplayTextSnippet(snippet);
    return QuestionTextSearchResult(first: first, totalMatches: count);
  }

  Future<QuestionEditorLoadBundle?> loadByUuid(String uuid) async {
    final row = await _db.questionsDao.getByUuid(uuid.trim());
    if (row == null) return null;
    final question = await _testEngine.loadStandaloneQuestionByUuid(uuid);
    if (question == null) return null;
    return QuestionEditorLoadBundle(
      row: row,
      draft: QuestionEditorDraft.fromLoaded(row: row, question: question),
    );
  }

  Future<QuestionCorrectionPublishOutcome> publishCorrection(
    QuestionEditorDraft draft,
  ) async {
    final map = QuestionCorrectionMapper.draftToCorrectionMap(draft);
    final outcome = await _publish.publish(map);
    if (outcome.success) {
      await _upsert.applyCorrections([map]);
      final rev = outcome.revision;
      if (rev != null) {
        await _syncService?.markRevisionApplied(rev);
      }
    }
    return outcome;
  }

  String _previewText(String? text) {
    final t = (text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= 96) return t;
    return '${t.substring(0, 96)}…';
  }
}
