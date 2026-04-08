import 'package:sqflite/sqflite.dart';

/// Read-only access to the bundled question SQLite file (copied to documents on first launch).
class QuestionDb {
  QuestionDb(this._path);

  final String _path;
  Database? _db;

  Future<Database> get database async {
    _db ??= await openDatabase(_path, readOnly: true);
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Distinct subject slugs, sorted alphabetically.
  Future<List<String>> getDistinctSubjectSlugs() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT subject_slug FROM questions ORDER BY subject_slug ASC',
    );
    return rows.map((r) => r['subject_slug']! as String).toList();
  }

  /// Distinct topic slugs for a subject, sorted alphabetically.
  Future<List<String>> getDistinctTopicSlugs(String subjectSlug) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT topic_slug FROM questions WHERE subject_slug = ? '
      'ORDER BY topic_slug ASC',
      [subjectSlug],
    );
    return rows.map((r) => r['topic_slug']! as String).toList();
  }

  Future<int> getQuestionCountForSubject(String subjectSlug) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM questions WHERE subject_slug = ?',
      [subjectSlug],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Distinct topic count for a subject.
  Future<int> getDistinctTopicCountForSubject(String subjectSlug) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT topic_slug) AS c FROM questions WHERE subject_slug = ?',
      [subjectSlug],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Per-topic question counts for a subject.
  Future<Map<String, int>> getQuestionCountsByTopicForSubject(
    String subjectSlug,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT topic_slug, COUNT(*) AS c FROM questions WHERE subject_slug = ? '
      'GROUP BY topic_slug',
      [subjectSlug],
    );
    return {
      for (final r in rows)
        r['topic_slug']! as String: Sqflite.firstIntValue([r]) ?? 0,
    };
  }

  /// Maps each uuid to subject and topic slugs (batched).
  Future<Map<String, QuestionSubjectTopic>> getSubjectTopicForUuids(
    List<String> uuids,
  ) async {
    if (uuids.isEmpty) return {};
    final db = await database;
    final out = <String, QuestionSubjectTopic>{};
    for (final chunk in _chunkList(uuids, 800)) {
      final ph = List.filled(chunk.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT uuid, subject_slug, topic_slug FROM questions WHERE uuid IN ($ph)',
        chunk,
      );
      for (final r in rows) {
        out[r['uuid']! as String] = QuestionSubjectTopic(
          subjectSlug: r['subject_slug']! as String,
          topicSlug: r['topic_slug']! as String,
        );
      }
    }
    return out;
  }

  Future<int> getQuestionCountForTopic(
    String subjectSlug,
    String topicSlug,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM questions WHERE subject_slug = ? AND topic_slug = ?',
      [subjectSlug, topicSlug],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<int> getQuestionCountForSubTopic(
    String subjectSlug,
    String topicSlug,
    String subTopicSlug,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM questions WHERE subject_slug = ? '
      'AND topic_slug = ? AND sub_topic_slug = ?',
      [subjectSlug, topicSlug, subTopicSlug],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Unseen first (not in [attemptedQuestionUuids]), then random seen to fill [n].
  Future<List<QuestionRow>> getNUnseenQuestionsForSubject(
    String subjectSlug,
    int n,
    Set<String> attemptedQuestionUuids,
  ) async {
    if (n <= 0) return [];
    final unseen = await _randomUuidsForSubject(
      subjectSlug,
      limit: n,
      attempted: attemptedQuestionUuids,
      preferUnseen: true,
    );
    if (unseen.length >= n) {
      return getQuestionsByUuids(unseen.take(n).toList());
    }
    final need = n - unseen.length;
    final seen = await _randomUuidsForSubject(
      subjectSlug,
      limit: need,
      attempted: attemptedQuestionUuids,
      preferUnseen: false,
    );
    return getQuestionsByUuids([...unseen, ...seen]);
  }

  /// Unseen first for a topic, then seen.
  Future<List<QuestionRow>> getNUnseenQuestionsForTopic(
    String subjectSlug,
    String topicSlug,
    int n,
    Set<String> attemptedQuestionUuids,
  ) async {
    if (n <= 0) return [];
    final unseen = await _randomUuidsForTopic(
      subjectSlug,
      topicSlug,
      limit: n,
      attempted: attemptedQuestionUuids,
      preferUnseen: true,
    );
    if (unseen.length >= n) {
      return getQuestionsByUuids(unseen.take(n).toList());
    }
    final need = n - unseen.length;
    final seen = await _randomUuidsForTopic(
      subjectSlug,
      topicSlug,
      limit: need,
      attempted: attemptedQuestionUuids,
      preferUnseen: false,
    );
    return getQuestionsByUuids([...unseen, ...seen]);
  }

  Future<List<QuestionRow>> getQuestionsByUuids(List<String> uuids) async {
    if (uuids.isEmpty) return [];
    final db = await database;
    final byUuid = <String, QuestionRow>{};
    for (final chunk in _chunkList(uuids, 800)) {
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT uuid, subject_slug, topic_slug, sub_topic_slug, correct_option, '
        'question_type, trap_type, has_table FROM questions WHERE uuid IN ($placeholders)',
        chunk,
      );
      for (final r in rows) {
        final row = QuestionRow.fromMap(r);
        byUuid[row.uuid] = row;
      }
    }
    return uuids.map((u) => byUuid[u]).whereType<QuestionRow>().toList();
  }

  Future<QuestionTranslationRow?> getQuestionTranslation(
    String uuid,
    String language,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT question_uuid, language, display_text, concept_anchor, final_explanation, '
      'upsc_trap_explanation, strong_distractor, elimination_logic, statement_analysis, '
      'concepts_used, header_text, footer_text, columns AS table_columns, rows AS table_rows '
      'FROM question_translations WHERE question_uuid = ? AND language = ?',
      [uuid, language],
    );
    if (rows.isEmpty) return null;
    return QuestionTranslationRow.fromMap(rows.first);
  }

  /// Topic slug → display name for [subjectSlug] and [language].
  Future<Map<String, String>> getTopicDisplayNamesForSubject(
    String subjectSlug,
    String language,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT topic_slug, display_name FROM topic_translations '
      'WHERE subject_slug = ? AND language = ? ORDER BY topic_slug ASC',
      [subjectSlug, language],
    );
    return {
      for (final r in rows)
        r['topic_slug']! as String: r['display_name']! as String,
    };
  }

  /// Per-topic accuracy using [attempts] (from user/session data).
  Future<Map<String, TopicAccuracy>> getAccuracyPerTopicForSubject(
    String subjectSlug,
    List<QuestionAttemptAccuracy> attempts,
  ) async {
    if (attempts.isEmpty) return {};
    final db = await database;
    final uuidToCorrect = {
      for (final a in attempts) a.questionUuid: a.isCorrect,
    };
    final uuids = uuidToCorrect.keys.toList();
    final uuidToTopic = <String, String>{};
    for (final chunk in _chunkList(uuids, 800)) {
      final ph = List.filled(chunk.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT uuid, topic_slug FROM questions WHERE subject_slug = ? AND uuid IN ($ph)',
        [subjectSlug, ...chunk],
      );
      for (final r in rows) {
        uuidToTopic[r['uuid']! as String] = r['topic_slug']! as String;
      }
    }
    final topicStats = <String, _TopicAgg>{};
    for (final entry in uuidToTopic.entries) {
      final correct = uuidToCorrect[entry.key];
      if (correct == null) continue;
      final agg = topicStats.putIfAbsent(entry.value, _TopicAgg.new);
      agg.attempted += 1;
      if (correct) agg.correct += 1;
    }
    return topicStats.map(
      (topic, agg) => MapEntry(
        topic,
        TopicAccuracy(
          topicSlug: topic,
          attempted: agg.attempted,
          correct: agg.correct,
          accuracy: agg.attempted == 0 ? 0 : (agg.correct / agg.attempted) * 100,
        ),
      ),
    );
  }

  Future<List<String>> _randomUuidsForSubject(
    String subjectSlug, {
    required int limit,
    required Set<String> attempted,
    required bool preferUnseen,
  }) async {
    final db = await database;
    final cond = StringBuffer('subject_slug = ?');
    final args = <Object?>[subjectSlug];
    if (preferUnseen) {
      final extra = _notInSqlAndArgs('uuid', attempted);
      if (extra != null) {
        cond.write(' AND ${extra.$1}');
        args.addAll(extra.$2);
      }
    } else {
      final inside = _inSqlAndArgs('uuid', attempted);
      if (inside == null) return [];
      cond.write(' AND ${inside.$1}');
      args.addAll(inside.$2);
    }
    final rows = await db.rawQuery(
      'SELECT uuid FROM questions WHERE $cond ORDER BY RANDOM() LIMIT ?',
      [...args, limit],
    );
    return rows.map((r) => r['uuid']! as String).toList();
  }

  Future<List<String>> _randomUuidsForTopic(
    String subjectSlug,
    String topicSlug, {
    required int limit,
    required Set<String> attempted,
    required bool preferUnseen,
  }) async {
    final db = await database;
    final cond = StringBuffer('subject_slug = ? AND topic_slug = ?');
    final args = <Object?>[subjectSlug, topicSlug];
    if (preferUnseen) {
      final extra = _notInSqlAndArgs('uuid', attempted);
      if (extra != null) {
        cond.write(' AND ${extra.$1}');
        args.addAll(extra.$2);
      }
    } else {
      final inside = _inSqlAndArgs('uuid', attempted);
      if (inside == null) return [];
      cond.write(' AND ${inside.$1}');
      args.addAll(inside.$2);
    }
    final rows = await db.rawQuery(
      'SELECT uuid FROM questions WHERE $cond ORDER BY RANDOM() LIMIT ?',
      [...args, limit],
    );
    return rows.map((r) => r['uuid']! as String).toList();
  }

  static (String, List<Object?>)? _notInSqlAndArgs(String column, Set<String> values) {
    if (values.isEmpty) return null;
    final chunks = _chunkList(values.toList(), 800);
    final parts = <String>[];
    final args = <Object?>[];
    for (final c in chunks) {
      parts.add(
        '$column NOT IN (${List.filled(c.length, '?').join(',')})',
      );
      args.addAll(c);
    }
    return (parts.join(' AND '), args);
  }

  static (String, List<Object?>)? _inSqlAndArgs(String column, Set<String> values) {
    if (values.isEmpty) return null;
    final chunks = _chunkList(values.toList(), 800);
    final parts = <String>[];
    final args = <Object?>[];
    for (final c in chunks) {
      parts.add('$column IN (${List.filled(c.length, '?').join(',')})');
      args.addAll(c);
    }
    if (parts.length == 1) return (parts.single, args);
    return ('(${parts.join(' OR ')})', args);
  }

  static List<List<T>> _chunkList<T>(List<T> list, int size) {
    final out = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = i + size > list.length ? list.length : i + size;
      out.add(list.sublist(i, end));
    }
    return out;
  }
}

class _TopicAgg {
  int attempted = 0;
  int correct = 0;
}

class QuestionSubjectTopic {
  const QuestionSubjectTopic({
    required this.subjectSlug,
    required this.topicSlug,
  });

  final String subjectSlug;
  final String topicSlug;
}

class QuestionRow {
  const QuestionRow({
    required this.uuid,
    required this.subjectSlug,
    required this.topicSlug,
    required this.subTopicSlug,
    required this.correctOption,
    this.questionType,
    this.trapType,
    required this.hasTable,
  });

  factory QuestionRow.fromMap(Map<String, Object?> map) {
    return QuestionRow(
      uuid: map['uuid']! as String,
      subjectSlug: map['subject_slug']! as String,
      topicSlug: map['topic_slug']! as String,
      subTopicSlug: map['sub_topic_slug']! as String,
      correctOption: map['correct_option']! as String,
      questionType: map['question_type'] as String?,
      trapType: map['trap_type'] as String?,
      hasTable: (map['has_table'] as int? ?? 0) != 0,
    );
  }

  final String uuid;
  final String subjectSlug;
  final String topicSlug;
  final String subTopicSlug;
  final String correctOption;
  final String? questionType;
  final String? trapType;
  final bool hasTable;
}

class QuestionTranslationRow {
  const QuestionTranslationRow({
    required this.questionUuid,
    required this.language,
    required this.displayText,
    this.conceptAnchor,
    this.finalExplanation,
    this.upscTrapExplanation,
    this.strongDistractor,
    this.eliminationLogic,
    this.statementAnalysis,
    this.conceptsUsed,
    this.headerText,
    this.footerText,
    this.columns,
    this.rows,
  });

  factory QuestionTranslationRow.fromMap(Map<String, Object?> map) {
    return QuestionTranslationRow(
      questionUuid: map['question_uuid']! as String,
      language: map['language']! as String,
      displayText: map['display_text']! as String,
      conceptAnchor: map['concept_anchor'] as String?,
      finalExplanation: map['final_explanation'] as String?,
      upscTrapExplanation: map['upsc_trap_explanation'] as String?,
      strongDistractor: map['strong_distractor'] as String?,
      eliminationLogic: map['elimination_logic'] as String?,
      statementAnalysis: map['statement_analysis'] as String?,
      conceptsUsed: map['concepts_used'] as String?,
      headerText: map['header_text'] as String?,
      footerText: map['footer_text'] as String?,
      columns: map['table_columns'] as String?,
      rows: map['table_rows'] as String?,
    );
  }

  final String questionUuid;
  final String language;
  final String displayText;
  final String? conceptAnchor;
  final String? finalExplanation;
  final String? upscTrapExplanation;
  final String? strongDistractor;
  final String? eliminationLogic;
  final String? statementAnalysis;
  final String? conceptsUsed;
  final String? headerText;
  final String? footerText;
  final String? columns;
  final String? rows;
}

class QuestionAttemptAccuracy {
  const QuestionAttemptAccuracy({
    required this.questionUuid,
    required this.isCorrect,
  });

  final String questionUuid;
  final bool isCorrect;
}

class TopicAccuracy {
  const TopicAccuracy({
    required this.topicSlug,
    required this.attempted,
    required this.correct,
    required this.accuracy,
  });

  final String topicSlug;
  final int attempted;
  final int correct;
  final double accuracy;
}
