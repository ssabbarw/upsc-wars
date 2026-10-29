import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/user_db.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/insight_improve.dart';
import '../domain/subject_trap_stat.dart';
import 'practice_catalog_provider.dart';

class InsightImproveDelta {
  const InsightImproveDelta({
    required this.label,
    required this.beforeCorrect,
    required this.beforeWrong,
    required this.afterCorrect,
    required this.afterWrong,
  });

  final String label;
  final int beforeCorrect;
  final int beforeWrong;
  final int afterCorrect;
  final int afterWrong;

  int get beforeTotal => beforeCorrect + beforeWrong;
  int get afterTotal => afterCorrect + afterWrong;

  int? get beforePercent =>
      beforeTotal == 0 ? null : ((100 * beforeCorrect) / beforeTotal).round();

  int get afterPercent =>
      afterTotal == 0 ? 0 : ((100 * afterCorrect) / afterTotal).round();

  bool get isFirst => beforeTotal == 0;

  bool get improved =>
      !isFirst && beforePercent != null && afterPercent > beforePercent!;

  bool get declined =>
      !isFirst && beforePercent != null && afterPercent < beforePercent!;
}

final insightImproveDeltaProvider = FutureProvider.autoDispose
    .family<InsightImproveDelta?, String>((ref, sessionId) async {
      final result = await ref.watch(sessionResultProvider(sessionId).future);
      if (!isInsightImproveFeature(result.analyticsFeatureKey)) return null;

      final catalog = await ref.watch(practiceCatalogProvider.future);
      final db = ref.watch(userDatabaseProvider);
      return loadInsightImproveDelta(
        db,
        sessionId: sessionId,
        subject: result.subject,
        topic: result.topic,
        isTrap: result.analyticsFeatureKey == kPracticeTrapImproveKey,
        seasonStart: catalog.season.start,
        topicDisplayNames: catalog.topicDisplayNames,
      );
    });

Future<InsightImproveDelta?> loadInsightImproveDelta(
  UserDatabase db, {
  required String sessionId,
  required String subject,
  required String? topic,
  required bool isTrap,
  required DateTime seasonStart,
  required Map<String, String> topicDisplayNames,
}) async {
  final season = Variable.withInt(seasonStart.millisecondsSinceEpoch ~/ 1000);
  final groupCol = isTrap ? 'q.trap_type' : 'q.topic';
  final rows = await db
      .customSelect(
        '''
        SELECT
          a.session_id AS sid,
          $groupCol AS gkey,
          COALESCE(SUM(CASE WHEN a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS c,
          COALESCE(SUM(CASE WHEN a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS w
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        INNER JOIN sessions s ON s.id = a.session_id
        WHERE q.subject = ?
          AND s.status = 'completed'
          AND s.completed_at >= ?
          AND a.status IN ('correct', 'wrong')
          ${isTrap ? '' : 'AND q.topic = ?'}
        GROUP BY a.session_id, $groupCol
        ''',
        variables: [
          Variable.withString(subject),
          season,
          if (!isTrap) Variable.withString(topic ?? ''),
        ],
        readsFrom: {db.sessionQuestions, db.questions, db.sessions},
      )
      .get();

  String? trapKey;
  if (isTrap) {
    for (final row in rows) {
      if (row.read<String>('sid') != sessionId) continue;
      final type = row.read<String?>('gkey') ?? '';
      if (normalizeTrapType(type).isEmpty) continue;
      trapKey = normalizeTrapType(type);
      break;
    }
    if (trapKey == null) return null;
  }

  var beforeC = 0;
  var beforeW = 0;
  var afterC = 0;
  var afterW = 0;
  for (final row in rows) {
    if (trapKey != null &&
        normalizeTrapType(row.read<String?>('gkey') ?? '') != trapKey) {
      continue;
    }
    final c = row.read<int>('c');
    final w = row.read<int>('w');
    afterC += c;
    afterW += w;
    if (row.read<String>('sid') != sessionId) {
      beforeC += c;
      beforeW += w;
    }
  }

  if (afterC + afterW == 0) return null;

  final topicKey = (topic ?? '').trim();
  final label = isTrap
      ? titleCaseTrapSlug(trapKey!)
      : (topicDisplayNames[topicKey] ??
            (topicKey.isEmpty ? subject : topicKey));

  return InsightImproveDelta(
    label: label,
    beforeCorrect: beforeC,
    beforeWrong: beforeW,
    afterCorrect: afterC,
    afterWrong: afterW,
  );
}
