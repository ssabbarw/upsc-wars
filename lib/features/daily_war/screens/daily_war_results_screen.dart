import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../daily_war_constants.dart';
import '../data/daily_war_cloud_service.dart';
import '../data/daily_war_firestore_paths.dart';
import '../domain/daily_war_models.dart';
import '../providers/daily_war_providers.dart';

/// After the local test session completes, sync score to Cloud Functions and
/// show AIR (live) or practice score (unranked).
class DailyWarResultsScreen extends HookConsumerWidget {
  const DailyWarResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final syncState = useState<_SyncState>(_SyncState.loading);
    final score = useState<double?>(null);
    final submission = useState<DailyWarSubmission?>(null);
    final nextTopics = useState<List<DailyWarTopicRef>>(const []);
    final error = useState<String?>(null);

    useEffect(() {
      var cancelled = false;
      unawaited(() async {
        try {
          final load = await ref.read(loadSessionUseCaseProvider.future);
          final session = await load.execute(sessionId);
          final dateId = (session.topic ?? '').trim();
          if (dateId.isEmpty) {
            throw StateError('Missing War date on session');
          }
          final mode = DailyWarConstants.isUnrankedFeatureKey(
                session.analyticsFeatureKey,
              )
              ? 'unranked'
              : 'live';

          final answers = <String, String>{};
          for (final q in session.questions) {
            final sel = q.selectedOption?.trim();
            if (sel != null && sel.isNotEmpty) {
              answers[q.uuid] = sel.toLowerCase();
            }
          }

          final limit = session.timeLimitSecs ?? 0;
          final remaining = session.savedExamRemainingSecs ?? 0;
          final elapsedMs =
              ((limit - remaining).clamp(0, limit > 0 ? limit : 0) * 1000);

          final displayName =
              FirebaseAuth.instance.currentUser?.displayName?.trim();

          const cloud = DailyWarCloudService();
          final result = await cloud.submit(
            dateId: dateId,
            answers: answers,
            elapsedMs: elapsedMs,
            mode: mode,
            displayName: displayName,
          );
          if (cancelled) return;
          if (!result.ok) {
            error.value = result.errorMessage ?? 'Submit failed';
            syncState.value = _SyncState.error;
            return;
          }
          score.value = result.score;

          final warDoc = await ref.read(dailyWarDocByIdProvider(dateId).future);
          nextTopics.value = warDoc?.nextTopics ?? const [];

          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            for (var i = 0; i < 15; i++) {
              if (cancelled) return;
              final snap =
                  await DailyWarFirestorePaths.submissionDoc(dateId, uid).get();
              if (snap.exists && snap.data() != null) {
                final sub = DailyWarSubmission.fromMap(uid, snap.data()!);
                submission.value = sub;
                if (mode == 'unranked' || sub.hasOfficialRank) break;
              }
              await Future<void>.delayed(const Duration(seconds: 2));
            }
          }

          syncState.value = _SyncState.ready;
        } on Object catch (e) {
          if (cancelled) return;
          error.value = e.toString();
          syncState.value = _SyncState.error;
        }
      }());
      return () => cancelled = true;
    }, [sessionId]);

    return Scaffold(
      appBar: AppBar(
        title: Text('War results', style: AppTextStyles.h3()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: switch (syncState.value) {
          _SyncState.loading => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text('Calculating your All-India Rank…'),
              ],
            ),
          ),
          _SyncState.error => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                error.value ?? 'Something went wrong',
                style: AppTextStyles.bodyMd().copyWith(color: AppColors.wrong),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Home'),
              ),
            ],
          ),
          _SyncState.ready => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (submission.value?.hasOfficialRank == true) ...[
                Text(
                  'AIR ${submission.value!.air}',
                  style: AppTextStyles.h1().copyWith(color: scheme.onSurface),
                ),
                Text(
                  'Percentile ${submission.value!.percentile?.toStringAsFixed(1) ?? '—'}',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                Text(
                  'Score',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  score.value?.toStringAsFixed(2) ?? '—',
                  style: AppTextStyles.h1(),
                ),
                if (submission.value?.mode == 'unranked' ||
                    submission.value == null)
                  Text(
                    'Unranked · not an official AIR yet',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (nextTopics.value.isNotEmpty) ...[
                Text('Tomorrow\'s War', style: AppTextStyles.label()),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  nextTopics.value.map((t) => t.topic).join(' + '),
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Done'),
              ),
              TextButton(
                onPressed: () => context.push(dailyWarHistoryRoute()),
                child: const Text('War History'),
              ),
            ],
          ),
        },
      ),
    );
  }
}

enum _SyncState { loading, ready, error }
