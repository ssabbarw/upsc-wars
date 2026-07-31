import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/daily_war_firestore_paths.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';

/// Shared archive of past Wars with personal attempt state.
class DailyWarHistoryScreen extends HookConsumerWidget {
  const DailyWarHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'War History',
          style: DwText.dm(
            size: 18,
            weight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                for (final entry in const [
                  (0, 'All'),
                  (1, 'Attempted'),
                  (2, 'Missed'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _TabChip(
                        label: entry.$2,
                        selected: tab.value == entry.$1,
                        onTap: () => tab.value = entry.$1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                      style: DwText.dm(
                        size: 14,
                        color: DwColors.muted,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final w = filtered[i];
                    final sub = subs.value[w.dateId];
                    final subjects = DailyWarCopy.subjectsLine(w.topics);
                    final topics = DailyWarCopy.topicsLine(w.topics);
                    String meta;
                    Color metaColor = DwColors.muted;
                    if (sub?.hasOfficialRank == true) {
                      meta = 'AIR ${sub!.air} · ${sub.score}';
                      metaColor = DwColors.crimson;
                    } else if (sub?.mode == 'unranked') {
                      meta = 'Practiced · ${sub!.score}';
                    } else if (sub != null) {
                      meta = 'Submitted · waiting for rank';
                    } else {
                      meta = 'Missed';
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DwColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DwColors.borderOnDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                w.isGrand ? 'GRAND WAR' : 'DAILY WAR',
                                style: DwText.eyebrow(),
                              ),
                              const Spacer(),
                              Text(
                                w.dateId,
                                style: DwText.stamp(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subjects,
                            style: DwText.dm(
                              size: 12,
                              weight: FontWeight.w600,
                              color: DwColors.crimsonBright,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topics,
                            style: DwText.dm(
                              size: 15,
                              weight: FontWeight.w700,
                              color: DwColors.onDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meta,
                            style: DwText.dm(
                              size: 12,
                              weight: FontWeight.w600,
                              color: metaColor,
                            ),
                          ),
                        ],
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

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? DwColors.crimson : DwColors.cream,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? DwColors.crimson : const Color(0x1F000000),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: DwText.dm(
                size: 12,
                weight: FontWeight.w700,
                color: selected ? DwColors.onDark : DwColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
