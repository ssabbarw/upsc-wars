import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';

/// Shared archive of past Wars with personal attempt state.
///
/// Backed by [dailyWarHistoryBundleProvider] which serves ranked wars from
/// local cache and only hits Firestore for a short recent window.
class DailyWarHistoryScreen extends ConsumerWidget {
  const DailyWarHistoryScreen({super.key, this.embedded = false});

  /// When true, omit [Scaffold] / [AppBar] (used inside Progress hub).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyWarHistoryBundleProvider);
    final scheme = Theme.of(context).colorScheme;

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(dailyWarBadgesRoute()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Your Earned badges',
                style: DwText.dm(
                  size: 12,
                  weight: FontWeight.w700,
                  color: DwColors.teal,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (bundle) {
                final wars = bundle.wars;
                final subs = bundle.submissions;

                if (wars.isEmpty) {
                  return Center(
                    child: Text(
                      'No Wars yet',
                      style: DwText.dm(
                        size: 14,
                        color: DwColors.muted,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: wars.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final w = wars[i];
                    final sub = subs[w.dateId];
                    final subjects = DailyWarCopy.subjectsLine(w.topics);
                    final topics = DailyWarCopy.topicsLine(w.topics);
                    final status = _WarStatus.fromSubmission(sub);

                    final isGrand = w.isGrand;
                    final kindColor =
                        isGrand ? DwColors.gold : DwColors.crimsonBright;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(
                          dailyWarHistoryDetailRoute(w.dateId),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: DwColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: status.borderColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kindColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: kindColor.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      isGrand ? 'GRAND WAR' : 'DAILY WAR',
                                      style: DwText.dm(
                                        size: 10,
                                        weight: FontWeight.w800,
                                        color: kindColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusBadge(status: status),
                                  const Spacer(),
                                  Text(
                                    DailyWarCopy.formatWarDate(w.dateId),
                                    style: DwText.dm(
                                      size: 12,
                                      weight: FontWeight.w600,
                                      color: DwColors.onDarkMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (subjects.isNotEmpty) ...[
                                Text(
                                  subjects,
                                  style: DwText.dm(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: DwColors.crimsonBright,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                topics,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DwText.dm(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: DwColors.onDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (status.detail != null)
                                    Expanded(
                                      child: Text(
                                        status.detail!,
                                        style: DwText.dm(
                                          size: 12,
                                          weight: FontWeight.w600,
                                          color: status.color,
                                        ),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  Text(
                                    'Open',
                                    style: DwText.dm(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: DwColors.onDarkMuted,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: DwColors.onDarkDim,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'War History',
          style: DwText.dm(
            size: 18,
            weight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: body,
    );
  }
}

class _WarStatus {
  const _WarStatus({
    required this.label,
    required this.color,
    this.detail,
  });

  final String label;
  final Color color;
  final String? detail;

  Color get borderColor => color.withValues(alpha: 0.35);

  static _WarStatus fromSubmission(DailyWarSubmission? sub) {
    if (sub == null) {
      return const _WarStatus(
        label: 'Missed',
        color: DwColors.onDarkMuted,
      );
    }
    if (sub.hasOfficialRank) {
      return _WarStatus(
        label: 'Attempted',
        color: DwColors.teal,
        detail: 'AIR ${sub.air} · ${sub.score}',
      );
    }
    if (sub.mode == 'unranked') {
      return _WarStatus(
        label: 'Practiced',
        color: const Color(0xFFAEB8FF),
        detail: '${sub.score}',
      );
    }
    return const _WarStatus(
      label: 'Submitted',
      color: DwColors.gold,
      detail: 'Waiting for rank',
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _WarStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: DwText.dm(
          size: 10,
          weight: FontWeight.w800,
          color: status.color,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

