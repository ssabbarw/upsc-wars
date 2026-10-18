import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/database/question_bank_upsert.dart';
import '../../../core/database/user_db.dart';
import 'daily_ca_firestore.dart';

class DailyCaDayDocument {
  const DailyCaDayDocument({
    required this.date,
    required this.firestorePath,
    required this.questionCount,
    required this.questions,
  });

  final String date;
  final String firestorePath;
  final int questionCount;
  final List<Map<String, dynamic>> questions;
}

class DailyCaRepository {
  DailyCaRepository({required UserDatabase db})
    : _db = db,
      _upsert = QuestionBankUpsert(db);

  static const _logName = 'DailyCaRepository';

  final UserDatabase _db;
  final QuestionBankUpsert _upsert;

  void _log(String message, {StackTrace? stackTrace}) {
    developer.log(message, name: _logName, stackTrace: stackTrace);
  }

  /// True when a live `daily_mcqs` snapshot has at least one question map.
  static bool snapshotHasQuestions(Map<String, dynamic>? data) {
    if (data == null) return false;
    return _coerceQuestionMaps(data['questions']).isNotEmpty;
  }

  /// Firestore may store `questions` as a List or a Map with numeric keys.
  static List<Map<String, dynamic>> _coerceQuestionMaps(Object? raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) {
      final entries = raw.entries.toList()
        ..sort((a, b) {
          final ai = int.tryParse(a.key.toString());
          final bi = int.tryParse(b.key.toString());
          if (ai != null && bi != null) return ai.compareTo(bi);
          return a.key.toString().compareTo(b.key.toString());
        });
      return entries
          .where((e) => e.value is Map)
          .map((e) => Map<String, dynamic>.from(e.value as Map))
          .toList();
    }
    return const [];
  }

  static bool _isPermissionDenied(FirebaseException e) {
    if (e.code.toLowerCase() == 'permission-denied') return true;
    final message = e.message ?? '';
    return message.contains('PERMISSION_DENIED') ||
        message.contains('Missing or insufficient permissions');
  }

  /// Loads one day's MCQs from Firestore at `daily_mcqs/{year}/{month}/{day}`.
  Future<DailyCaDayDocument?> fetchDay(String isoDate) async {
    final path = DailyCaFirestore.pathForDate(isoDate);
    _log('Fetching $path for $isoDate');
    try {
      final snap = await DailyCaFirestore.dayDoc(isoDate).get();
      if (!snap.exists) {
        _log('No document at $path');
        return null;
      }
      final data = snap.data();
      if (data == null) {
        _log('Document at $path exists but data is null');
        return null;
      }

      final rawQuestions = data['questions'];
      final questionMaps = _coerceQuestionMaps(rawQuestions);
      if (questionMaps.isEmpty) {
        _log(
          'Document at $path has no questions '
          '(type=${rawQuestions.runtimeType})',
        );
        return null;
      }

      final questions = questionMaps.map(_normalizeQuestionMap).toList();

      if (questions.isEmpty) {
        _log('Document at $path: questions array had no valid maps');
        return null;
      }

      final meta = data['metadata'];
      final countFromMeta = meta is Map ? meta['question_count'] : null;
      final count = countFromMeta is int ? countFromMeta : questions.length;

      _log('Loaded $count question(s) from $path');
      return DailyCaDayDocument(
        date: isoDate,
        firestorePath: path,
        questionCount: count,
        questions: questions,
      );
    } on FirebaseException catch (e, st) {
      _log(
        'Firestore error at $path: code=${e.code} message=${e.message}',
        stackTrace: st,
      );
      if (_isPermissionDenied(e)) {
        throw DailyCaPermissionDeniedException(isoDate, firestorePath: path);
      }
      rethrow;
    }
  }

  /// Reads Firestore (`daily_mcqs/year/month/day`), upserts locally, returns UUIDs.
  Future<List<String>> ensureCachedForDate(String isoDate) async {
    final path = DailyCaFirestore.pathForDate(isoDate);
    try {
      final doc = await fetchDay(isoDate);
      if (doc != null) {
        _log('Upserting ${doc.questions.length} question(s) for $isoDate');
        final uuids = await _upsert.upsertCurrentAffairsDocument(
          sourceDate: isoDate,
          questionMaps: doc.questions,
        );
        _log('Cached ${uuids.length} UUID(s) for $isoDate');
        return uuids;
      }

      final local = await _db.questionsDao.getCurrentAffairsByDate(isoDate);
      if (local.isNotEmpty) {
        _log(
          'Firestore miss at $path; using ${local.length} local question(s)',
        );
        return local.map((q) => q.uuid).toList();
      }

      _log('No Firestore doc and no local cache for $isoDate ($path)');
      throw DailyCaNotAvailableException(isoDate, firestorePath: path);
    } catch (e, st) {
      if (e is DailyCaNotAvailableException ||
          e is DailyCaPermissionDeniedException) {
        rethrow;
      }
      _log(
        'Failed to load/cache daily CA for $isoDate ($path): $e',
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Canonical `{ uuid, meta, shared, en, hi }` or legacy `{ shared, en, hi }`.
  static Map<String, dynamic> _normalizeQuestionMap(Map<String, dynamic> q) {
    if (q.containsKey('meta') && q['meta'] is Map) {
      return q;
    }

    final shared = q['shared'] is Map
        ? Map<String, dynamic>.from(q['shared'] as Map)
        : <String, dynamic>{};

    return {
      if (q['uuid'] != null) 'uuid': q['uuid'],
      'meta': {
        'gs_subject': shared['subject'] ?? shared['gs_subject'] ?? '',
        'topic': shared['topic'] ?? '',
        'sub_topic':
            shared['subtopic'] ?? shared['sub_topic'] ?? 'Current Affairs',
        'pool_order': shared['pool_order'],
      },
      'shared': {
        'question_type': shared['question_type'],
        'trap_type': shared['trap_type'],
        'concept_anchor': shared['concept_anchor'],
        'has_table': shared['has_table'] ?? false,
        'correct_option': shared['correct_option'],
      },
      'en': q['en'] is Map
          ? Map<String, dynamic>.from(q['en'] as Map)
          : <String, dynamic>{},
      'hi': q['hi'] is Map
          ? Map<String, dynamic>.from(q['hi'] as Map)
          : <String, dynamic>{},
    };
  }
}

class DailyCaNotAvailableException implements Exception {
  DailyCaNotAvailableException(this.date, {this.firestorePath});

  final String date;
  final String? firestorePath;

  @override
  String toString() {
    final path = firestorePath;
    if (path != null) {
      return 'Daily CA not available for $date (Firestore: $path)';
    }
    return 'Daily CA not available for $date';
  }
}

class DailyCaPermissionDeniedException implements Exception {
  DailyCaPermissionDeniedException(this.date, {this.firestorePath});

  final String date;
  final String? firestorePath;

  @override
  String toString() =>
      'Firestore permission denied for daily_mcqs ($date). '
      'Deploy firestore.rules: firebase deploy --only firestore:rules';
}
