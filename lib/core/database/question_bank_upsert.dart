import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../constants/question_source_constants.dart';
import 'user_db.dart';

const _uuid = Uuid();

/// Stable UUID for a daily CA question (matches Python pipeline).
String currentAffairsQuestionUuid({
  required String sourceDate,
  required int poolOrder,
}) {
  return _uuid.v5(
    Namespace.url.value,
    'upsc-wars|ca|$sourceDate|$poolOrder',
  );
}

/// Upserts canonical Firestore question maps into the local question bank.
///
/// Expected shape per item:
/// `{ uuid, meta, shared, en, hi }`
class QuestionBankUpsert {
  QuestionBankUpsert(this._db);

  final UserDatabase _db;

  /// Applies remote correction maps (canonical `{ uuid, meta, shared, en, hi }`).
  Future<void> applyCorrections(Iterable<Map<String, dynamic>> maps) async {
    final list = maps.toList();
    if (list.isEmpty) return;
    await _db.transaction(() async {
      for (final map in list) {
        final uuid = _str(map['uuid']);
        if (uuid.isEmpty) continue;
        final existing = await _db.questionsDao.getByUuid(uuid);
        await _upsertOne(
          map,
          uuid: uuid,
          sourceDate: existing?.sourceDate ?? '',
          poolOrder: existing?.paperOrder ?? 1,
          preserveSourceFrom: existing,
        );
      }
    });
  }

  /// Upserts all questions from a daily CA Firestore document.
  ///
  /// Returns ordered UUIDs (by [meta.pool_order] / list index).
  Future<List<String>> upsertCurrentAffairsDocument({
    required String sourceDate,
    required List<Map<String, dynamic>> questionMaps,
  }) async {
    final uuids = <String>[];
    await _db.transaction(() async {
      for (var i = 0; i < questionMaps.length; i++) {
        final map = questionMaps[i];
        final poolOrder = _readPoolOrder(map, i + 1);
        final uuid = _readUuid(map, sourceDate: sourceDate, poolOrder: poolOrder);
        uuids.add(uuid);
        await _upsertOne(map, uuid: uuid, sourceDate: sourceDate, poolOrder: poolOrder);
      }
    });
    return uuids;
  }

  Future<void> _upsertOne(
    Map<String, dynamic> map, {
    required String uuid,
    required String sourceDate,
    required int poolOrder,
    Question? preserveSourceFrom,
  }) async {
    final meta = _asMap(map['meta']);
    final shared = _asMap(map['shared']);
    final en = _asMap(map['en']);
    final hi = _asMap(map['hi']);

    final gsSubject = QuestionSourceConstants.normalizeGsSubject(
      _str(meta['gs_subject'] ?? meta['subject']),
    );
    final topic = _str(meta['topic']).isEmpty ? gsSubject : _str(meta['topic']);
    final subTopic = _str(meta['sub_topic'] ?? meta['subtopic']).isEmpty
        ? (preserveSourceFrom?.subTopic ?? 'Current Affairs')
        : _str(meta['sub_topic'] ?? meta['subtopic']);
    final conceptsUsed = meta['concepts_used'];
    final conceptsJson = jsonEncode(
      conceptsUsed is List ? conceptsUsed : const <dynamic>[],
    );

    final qType = QuestionSourceConstants.normalizeQuestionType(
      _str(shared['question_type']),
    );
    final correctOption = _str(shared['correct_option']).toLowerCase();
    final conceptAnchor = _str(shared['concept_anchor']);
    final hasTable = shared['has_table'] == true;
    final preserved = preserveSourceFrom;
    final subjectLabel = preserved != null && preserved.subject.isNotEmpty
        ? preserved.subject
        : gsSubject;
    final sourceKind = preserved?.sourceKind ??
        QuestionSourceConstants.kindCurrentAffairs;
    final sourceYear = preserved?.sourceYear;
    final resolvedSourceDate = preserved?.sourceDate ?? sourceDate;
    final resolvedPaperOrder = preserved?.paperOrder ?? poolOrder;
    final negativeFraming = preserved?.negativeFraming ?? false;

    await _db.into(_db.questions).insertOnConflictUpdate(
      QuestionsCompanion.insert(
        uuid: uuid,
        subject: subjectLabel,
        topic: topic,
        subTopic: subTopic,
        questionType: qType,
        trapType: Value(_nullableStr(shared['trap_type'])),
        correctOption: correctOption.isEmpty ? 'a' : correctOption,
        conceptAnchor: conceptAnchor.isEmpty ? subTopic : conceptAnchor,
        conceptsUsed: conceptsJson,
        enDisplayText: Value(_nullableStr(en['display_text'])),
        hiDisplayText: Value(_nullableStr(hi['display_text'])),
        hasTable: Value(preserved?.hasTable ?? hasTable),
        negativeFraming: Value(negativeFraming),
        paperOrder: Value(resolvedPaperOrder),
        gsSubject: Value(gsSubject.isEmpty ? subjectLabel : gsSubject),
        sourceKind: Value(sourceKind),
        sourceYear: sourceYear == null
            ? const Value.absent()
            : Value(sourceYear),
        sourceDate: resolvedSourceDate.isEmpty
            ? const Value.absent()
            : Value(resolvedSourceDate),
      ),
    );

    for (final lang in ['en', 'hi']) {
      final payload = lang == 'en' ? en : hi;
      if (payload.isEmpty) continue;
      await _upsertExplanation(uuid: uuid, language: lang, payload: payload);
    }

    if (hasTable) {
      await _upsertTable(uuid: uuid, en: en, hi: hi);
    }
  }

  Future<void> _upsertExplanation({
    required String uuid,
    required String language,
    required Map<String, dynamic> payload,
  }) async {
    final stmtAnalysis = payload['statement_analysis'];
    final strongDistractor = _str(payload['strong_distractor']);
    final eliminationLogic = jsonEncode(
      payload['elimination_logic'] is List
          ? payload['elimination_logic']
          : const <dynamic>[],
    );
    final upscTrapExplanation = _str(payload['upsc_trap_explanation']);
    final finalExplanation = _str(payload['final_explanation']);
    final statementAnalysis = stmtAnalysis == null
        ? null
        : jsonEncode(stmtAnalysis is List ? stmtAnalysis : const []);

    final existing = await _db.questionTranslationsDao.getByQuestionAndLanguage(
      uuid,
      language,
    );
    final insertCompanion = QuestionTranslationsCompanion.insert(
      questionUuid: uuid,
      language: language,
      strongDistractor: strongDistractor,
      eliminationLogic: eliminationLogic,
      upscTrapExplanation: upscTrapExplanation,
      finalExplanation: finalExplanation,
      statementAnalysis: Value(statementAnalysis),
    );

    if (existing == null) {
      await _db.into(_db.questionTranslations).insert(insertCompanion);
      return;
    }

    await (_db.update(_db.questionTranslations)
          ..where(
            (t) => t.questionUuid.equals(uuid) & t.language.equals(language),
          ))
        .write(
      QuestionTranslationsCompanion(
        strongDistractor: Value(strongDistractor),
        eliminationLogic: Value(eliminationLogic),
        upscTrapExplanation: Value(upscTrapExplanation),
        finalExplanation: Value(finalExplanation),
        statementAnalysis: Value(statementAnalysis),
      ),
    );
  }

  Future<void> _upsertTable({
    required String uuid,
    required Map<String, dynamic> en,
    required Map<String, dynamic> hi,
  }) async {
    final enTable = _asMap(en['table_data']);
    final hiTable = _asMap(hi['table_data']);
    if (enTable.isEmpty && hiTable.isEmpty) return;

    final existing = await _db.questionTablesDao.getByQuestionUuid(uuid);
    final companion = QuestionTablesCompanion.insert(
      questionUuid: uuid,
      enHeaderText: Value(_nullableStr(enTable['header_text'])),
      enFooterText: Value(_nullableStr(enTable['footer_text'])),
      enColumns: jsonEncode(
        enTable['columns'] is List ? enTable['columns'] : const [],
      ),
      enRows: jsonEncode(
        enTable['rows'] is List ? enTable['rows'] : const [],
      ),
      hiHeaderText: Value(_nullableStr(hiTable['header_text'])),
      hiFooterText: Value(_nullableStr(hiTable['footer_text'])),
      hiColumns: jsonEncode(
        hiTable['columns'] is List ? hiTable['columns'] : const [],
      ),
      hiRows: jsonEncode(
        hiTable['rows'] is List ? hiTable['rows'] : const [],
      ),
    );

    if (existing == null) {
      await _db.into(_db.questionTables).insert(companion);
    } else {
      await (_db.update(_db.questionTables)
            ..where((t) => t.questionUuid.equals(uuid)))
          .write(
        QuestionTablesCompanion(
          enHeaderText: companion.enHeaderText,
          enFooterText: companion.enFooterText,
          enColumns: Value(companion.enColumns.value),
          enRows: Value(companion.enRows.value),
          hiHeaderText: companion.hiHeaderText,
          hiFooterText: companion.hiFooterText,
          hiColumns: Value(companion.hiColumns.value),
          hiRows: Value(companion.hiRows.value),
        ),
      );
    }
  }

  int _readPoolOrder(Map<String, dynamic> map, int fallback) {
    final meta = _asMap(map['meta']);
    final raw = meta['pool_order'] ?? map['pool_order'];
    if (raw is int && raw > 0) return raw;
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return fallback;
  }

  String _readUuid(
    Map<String, dynamic> map, {
    required String sourceDate,
    required int poolOrder,
  }) {
    final fromMap = _str(map['uuid']);
    if (fromMap.isNotEmpty) return fromMap;
    return currentAffairsQuestionUuid(
      sourceDate: sourceDate,
      poolOrder: poolOrder,
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  String _str(Object? value) => value?.toString().trim() ?? '';

  String? _nullableStr(Object? value) {
    final s = _str(value);
    return s.isEmpty ? null : s;
  }
}
