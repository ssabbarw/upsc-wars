import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../data/memory_pair_sets_data.dart';
import '../data/memory_pair_stats_repository.dart';
import '../domain/memory_pair_models.dart';

final memoryPairStatsRepositoryProvider =
    FutureProvider<MemoryPairStatsRepository>((ref) async {
      final prefs = await ref.watch(prefsServiceProvider.future);
      return MemoryPairStatsRepository(prefs);
    });

final subjectUniqueQuestionsAttemptedProvider = FutureProvider.autoDispose
    .family<int, String>((ref, subjectSlug) async {
      final db = ref.watch(userDatabaseProvider);
      final row = await db
          .customSelect(
            '''
        SELECT COUNT(DISTINCT a.question_uuid) AS unique_count
        FROM attempts a
        INNER JOIN questions q ON q.uuid = a.question_uuid
        WHERE q.subject = ?
          AND a.attempted_at IS NOT NULL
          AND a.is_correct IS NOT NULL
        ''',
            variables: [Variable.withString(subjectSlug)],
            readsFrom: {db.sessionQuestions, db.questions},
          )
          .getSingle();
      return row.read<int>('unique_count');
    });

final memoryPairSetListProvider =
    FutureProvider.autoDispose<List<MemoryPairSetListItem>>((ref) async {
      final repo = await ref.watch(memoryPairStatsRepositoryProvider.future);
      final items = <MemoryPairSetListItem>[];

      for (final def in kMemoryPairSetCatalog) {
        final progress = await ref.watch(
          subjectUniqueQuestionsAttemptedProvider(def.unlockSubjectSlug).future,
        );
        final isUnlocked = progress >= def.unlockQuestionsRequired;
        final stats = await repo.getStats(def.id, def.difficulty);
        final bestSeconds = stats?.bestSeconds;
        final lastPlayedAt = stats?.lastPlayedAt;

        items.add(
          MemoryPairSetListItem(
            definition: def,
            isUnlocked: isUnlocked,
            unlockProgress: progress,
            unlockRequired: def.unlockQuestionsRequired,
            bestSeconds: bestSeconds,
            lastPlayedAt: lastPlayedAt,
          ),
        );
      }

      return items;
    });

final memoryPairSetStatsProvider = FutureProvider.autoDispose
    .family<MemoryPairSetStats?, (String, MemoryPairDifficulty)>((
      ref,
      key,
    ) async {
      final (setId, difficulty) = key;
      final repo = await ref.watch(memoryPairStatsRepositoryProvider.future);
      return repo.getStats(setId, difficulty);
    });
