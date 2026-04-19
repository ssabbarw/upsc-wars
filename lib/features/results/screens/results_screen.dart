import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/errors/app_errors.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../battle/widgets/battle_live_scoreboard.dart';
import '../widgets/session_summary_minimal.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionResultProvider(sessionId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e is SessionNotFoundException
                        ? 'Session not found'
                        : 'Could not load results',
                    style: AppTextStyles.body(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (e is! SessionNotFoundException)
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(sessionResultProvider(sessionId)),
                      child: Text('Retry', style: AppTextStyles.label()),
                    ),
                  if (e is SessionNotFoundException) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => context.go('/'),
                      child: Text('Home', style: AppTextStyles.label()),
                    ),
                  ],
                ],
              ),
            ),
          ),
          data: (r) {
            final displaySubject =
                SubjectConstants.bySlug(r.subject)?.displayName ?? r.subject;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                        ),
                        onPressed: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session summary',
                              style: AppTextStyles.h2().copyWith(
                                color: scheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              displaySubject,
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        children: [
                          if (r.dangerZoneWrongCount > 0) ...[
                            _DangerZoneCompactCard(
                              sessionId: sessionId,
                              resultLabel:
                                  'Confidently wrong on ${r.dangerZoneWrongCount} '
                                  'question${r.dangerZoneWrongCount == 1 ? '' : 's'}',
                              scheme: scheme,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (r.analyticsFeatureKey == 'mcq_battle') ...[
                            BattleLiveScoreboard(sessionId: sessionId),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          SessionSummaryMinimalContent(
                            sessionId: sessionId,
                            result: r,
                            displaySubjectName: displaySubject,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DangerZoneCompactCard extends StatelessWidget {
  const _DangerZoneCompactCard({
    required this.sessionId,
    required this.resultLabel,
    required this.scheme,
  });

  final String sessionId;
  final String resultLabel;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/danger-zone/$sessionId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.error, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  resultLabel,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onErrorContainer),
            ],
          ),
        ),
      ),
    );
  }
}
