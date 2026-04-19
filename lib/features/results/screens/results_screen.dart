import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/session_subject_label.dart';
import '../../../core/deep_link/share_session_opener.dart';
import '../../../core/domain/errors/app_errors.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../battle/widgets/battle_live_scoreboard.dart';
import '../widgets/session_summary_coach.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionResultProvider(sessionId));
    final scheme = Theme.of(context).colorScheme;

    // Submit uses go('/results/...'), so the root stack often cannot pop.
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.mounted) context.go('/');
      },
      child: Scaffold(
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
              final displaySubject = displayNameForSessionSubject(r.subject);

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
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/'),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        IconButton(
                          tooltip: 'Share questions',
                          style: IconButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                          ),
                          onPressed: () => unawaited(
                            shareSessionQuestionsLink(
                              ref: ref,
                              sessionId: sessionId,
                            ),
                          ),
                          icon: const Icon(Icons.ios_share_rounded),
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
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxl,
                          ),
                          children: [
                            if (r.analyticsFeatureKey == 'mcq_battle') ...[
                              BattleLiveScoreboard(sessionId: sessionId),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            SessionSummaryCoachContent(
                              sessionId: sessionId,
                              result: r,
                              displaySubjectName: displaySubject,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Center(child: ContactUsTextButton()),
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
      ),
    );
  }
}
