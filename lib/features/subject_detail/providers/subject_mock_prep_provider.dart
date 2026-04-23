import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../data/subject_topic_danger.dart';
import '../domain/subject_mock_prep_insights.dart';

const _minTopicConfidentForSafe = 3;
const _maxList = 5;

/// Mock-oriented topic lists: where confident wrongs cluster (lifetime), and where confident play is above your global rate.
final subjectMockPrepInsightsProvider =
    FutureProvider.autoDispose.family<SubjectMockPrepInsights, String>(
  (ref, subject) async {
    final db = ref.watch(userDatabaseProvider);
    final catalog = await ref.watch(topicTestTopicsProvider(subject).future);
    final byKey = {for (final t in catalog) t.topic: t.displayName};

    final dangerByTopic = await fetchSubjectTopicDanger(db, subject);

    final revise = dangerByTopic.entries
        .where((e) => e.value.sure + e.value.guess > 0)
        .map(
          (e) => ReviseBeforeMockRow(
            topicKey: e.key,
            displayName: byKey[e.key] ?? e.key,
            sureWrong: e.value.sure,
            educatedGuessWrong: e.value.guess,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalWrong.compareTo(a.totalWrong));

    final globalRow = await db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS cc,
            COALESCE(COUNT(*), 0) AS tot
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE a.attempted_at IS NOT NULL
            AND a.status IN ('correct', 'wrong')
            AND a.confidence IN ('very_sure', 'somewhat_sure')
          ''',
          readsFrom: {db.sessionQuestions, db.questions},
        )
        .getSingle();
    final globalCorrect = globalRow.read<int>('cc');
    final globalTotal = globalRow.read<int>('tot');
    final double? globalRate = globalTotal > 0
        ? (100.0 * globalCorrect / globalTotal)
        : null;

    if (globalRate == null || globalTotal == 0) {
      return SubjectMockPrepInsights(
        reviseTopics: revise.take(_maxList).toList(),
        safeTopics: const [],
        globalConfidentRatePercent: null,
        globalConfidentMistakeRatePercent: null,
        reviseTopicTotalCount: revise.length,
        safeTopicTotalCount: 0,
      );
    }
    final globalMistakeRate = 100.0 * (globalTotal - globalCorrect) / globalTotal;

    final topicRows = await db
        .customSelect(
          '''
          SELECT
            q.topic AS topic,
            COALESCE(SUM(CASE WHEN a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS cc,
            COALESCE(COUNT(*), 0) AS tot
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND a.attempted_at IS NOT NULL
            AND a.status IN ('correct', 'wrong')
            AND a.confidence IN ('very_sure', 'somewhat_sure')
          GROUP BY q.topic
          ''',
          variables: [Variable.withString(subject)],
          readsFrom: {db.sessionQuestions, db.questions},
        )
        .get();

    final topicAllTime = <String, ({int tot, int cc})>{};
    for (final r in topicRows) {
      final topicKey = r.read<String>('topic');
      final cc = r.read<int>('cc');
      final tot = r.read<int>('tot');
      topicAllTime[topicKey] = (tot: tot, cc: cc);
    }

    final safeCandidates = <SafeAreaRow>[];
    for (final r in topicRows) {
      final topicKey = r.read<String>('topic');
      final cc = r.read<int>('cc');
      final tot = r.read<int>('tot');
      if (tot < _minTopicConfidentForSafe) continue;
      if (cc * globalTotal <= globalCorrect * tot) continue;
      final rate = 100.0 * cc / tot;
      safeCandidates.add(
        SafeAreaRow(
          topicKey: topicKey,
          displayName: byKey[topicKey] ?? topicKey,
          confidentTotal: tot,
          confidentCorrect: cc,
          ratePercent: rate,
          globalRatePercent: globalRate,
        ),
      );
    }
    safeCandidates.sort((a, b) {
      final cmp = b.ratePercent.compareTo(a.ratePercent);
      if (cmp != 0) return cmp;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    // If a topic is both a strong "revise" (lifetime confident wrongs) and "safe"
    // (above global), keep it in one list: compare all-time confident
    // wrongs vs confident corrects (very_sure + somewhat_sure, scored only).
    final reviseKeySet = {for (final r in revise) r.topicKey};
    final safeKeySet = {for (final s in safeCandidates) s.topicKey};
    for (final topicKey in reviseKeySet.intersection(safeKeySet)) {
      final stat = topicAllTime[topicKey];
      if (stat == null) {
        // Topic has confident wrongs; keep it on revise, drop from safe.
        for (var i = safeCandidates.length - 1; i >= 0; i--) {
          if (safeCandidates[i].topicKey == topicKey) {
            safeCandidates.removeAt(i);
            break;
          }
        }
        continue;
      }
      final w = stat.tot - stat.cc; // confident wrongs (all-time)
      final c = stat.cc; // confident corrects
      // Ties: keep on Revise (caution in mocks).
      if (w >= c) {
        for (var i = safeCandidates.length - 1; i >= 0; i--) {
          if (safeCandidates[i].topicKey == topicKey) {
            safeCandidates.removeAt(i);
            break;
          }
        }
      } else {
        for (var i = revise.length - 1; i >= 0; i--) {
          if (revise[i].topicKey == topicKey) {
            revise.removeAt(i);
            break;
          }
        }
      }
    }

    // Re-sort after removals (order may be unchanged)
    revise.sort((a, b) => b.totalWrong.compareTo(a.totalWrong));
    safeCandidates.sort((a, b) {
      final cmp = b.ratePercent.compareTo(a.ratePercent);
      if (cmp != 0) return cmp;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    final reviseTop = revise.take(_maxList).toList();
    final safeTop = safeCandidates.take(_maxList).toList();

    return SubjectMockPrepInsights(
      reviseTopics: reviseTop,
      safeTopics: safeTop,
      globalConfidentRatePercent: globalRate,
      globalConfidentMistakeRatePercent: globalMistakeRate,
      reviseTopicTotalCount: revise.length,
      safeTopicTotalCount: safeCandidates.length,
    );
  },
);
