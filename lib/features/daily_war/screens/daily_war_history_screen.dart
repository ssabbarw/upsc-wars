import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/daily_war_firestore_paths.dart';
import '../domain/daily_war_models.dart';
import '../providers/daily_war_providers.dart';

/// Shared archive of past Wars with personal attempt state.
class DailyWarHistoryScreen extends HookConsumerWidget {
  const DailyWarHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tab = useState(0); // 0 all, 1 attempted, 2 missed
    final async = ref.watch(dailyWarHistoryListProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final subs = useState<Map<String, DailyWarSubmission>>({});

    useEffect(() {
      var cancelled = false;
      async.whenData((wars) async {
        if (uid == null || uid.isEmpty) return;
        final map = <String, DailyWarSubmission>{};
        for (final w in wars.take(40)) {
          final snap =
              await DailyWarFirestorePaths.submissionDoc(w.dateId, uid).get();
          if (cancelled) return;
          if (snap.exists && snap.data() != null) {
            map[w.dateId] = DailyWarSubmission.fromMap(uid, snap.data()!);
          }
        }
        if (!cancelled) subs.value = map;
      });
      return () => cancelled = true;
    }, [async, uid]);

    return Scaffold(
      appBar: AppBar(
        title: Text('War History', style: AppTextStyles.h3()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('All')),
                ButtonSegment(value: 1, label: Text('Attempted')),
                ButtonSegment(value: 2, label: Text('Missed')),
              ],
              selected: {tab.value},
              onSelectionChanged: (s) => tab.value = s.first,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (wars) {
                final filtered = wars.where((w) {
                  final sub = subs.value[w.dateId];
                  switch (tab.value) {
                    case 1:
                      return sub != null;
                    case 2:
                      return sub == null;
                    default:
                      return true;
                  }
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      tab.value == 1
                          ? 'No Wars attempted yet'
                          : tab.value == 2
                              ? 'You\'re caught up'
                              : 'No Wars yet',
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final w = filtered[i];
                    final sub = subs.value[w.dateId];
                    final subjects = w.topics
                        .map(
                          (t) =>
                              SubjectConstants.bySlug(t.subjectSlug)
                                  ?.displayName ??
                              t.subjectSlug,
                        )
                        .toSet()
                        .join(' + ');
                    final topics = w.topics.map((t) => t.topic).join(' + ');
                    String meta;
                    if (sub?.hasOfficialRank == true) {
                      meta = 'AIR ${sub!.air} · ${sub.score}';
                    } else if (sub?.mode == 'unranked') {
                      meta = 'Practiced · ${sub!.score}';
                    } else if (sub != null) {
                      meta = 'Submitted · waiting for rank';
                    } else {
                      meta = 'Missed';
                    }

                    return Material(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: ListTile(
                        title: Text(
                          '${w.isGrand ? 'Grand War' : 'Daily War'} · ${w.dateId}',
                          style: AppTextStyles.label(),
                        ),
                        subtitle: Text(
                          '$subjects\n$topics\n$meta',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
