import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/debug/upsc_wars_trace.dart';
import '../../../core/presentation/session_subject_label.dart';
import '../../../core/deep_link/share_session_opener.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/domain/errors/app_errors.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/contact_us_entry.dart';
import '../../battle/widgets/battle_live_scoreboard.dart';
import '../../community/open_challenge/open_challenge_analytics.dart';
import '../../community/open_challenge/open_challenge_exam_context.dart';
import '../../community/open_challenge/open_challenge_exam_registry.dart';
import '../../community/open_challenge/open_challenge_post_results_submit.dart';
import '../../community/widgets/open_challenge_post_from_results_card.dart';
import '../../community/widgets/open_challenge_results_actions.dart';
import '../../../core/services/deferred_push_permission_coordinator.dart';
import '../widgets/session_summary_coach.dart';

String _sessionResultPhase(AsyncValue<SessionResult>? v) {
  if (v == null) return '(none)';
  return v.when(
    data: (_) => 'data',
    loading: () => 'loading',
    error: (_, _) => 'error',
  );
}

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    upscWarsTrace('ResultsScreen.build sessionId=$sessionId');

    ref.listen(sessionResultProvider(sessionId), (prev, next) {
      upscWarsTrace(
        'ResultsScreen sessionResult $sessionId: '
        '${_sessionResultPhase(prev)} -> ${_sessionResultPhase(next)}',
      );
      if (next.hasError) {
        upscWarsTrace(
          'ResultsScreen sessionResult error sessionId=$sessionId',
          error: next.error,
          stackTrace: next.stackTrace,
        );
      }
    });

    final async = ref.watch(sessionResultProvider(sessionId));
    final scheme = Theme.of(context).colorScheme;

    // Submit uses go('/results/...'), so the root stack often cannot pop.
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ScreenFlow.logAction(
            ref,
            screenName: ScreenFlow.sessionResults,
            actionId: 'system_back_pop',
            actionKind: 'back',
          );
          return;
        }
        ScreenFlow.logAction(
          ref,
          screenName: ScreenFlow.sessionResults,
          actionId: 'back_to_home',
          actionKind: 'back',
        );
        unawaited(() async {
          await DeferredPushPermissionCoordinator.tryOfferFromResultsUserAction(
            context,
            ref,
          );
          if (context.mounted) context.go('/');
        }());
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: async.when(
            loading: () =>
                _ResultsLoadingWithTrace(sessionId: sessionId),
            error: (e, st) {
              upscWarsTrace(
                'ResultsScreen async.when error branch sessionId=$sessionId',
                error: e,
                stackTrace: st,
              );
              return Center(
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
              );
            },
            data: (r) {
              final ocCtx = ref
                  .read(openChallengeExamRegistryProvider)
                  .peek(sessionId);
              final isAcceptOpenChallenge =
                  r.analyticsFeatureKey == OpenChallengeAnalytics.accept &&
                  ocCtx?.kind == OpenChallengeExamKind.accept;

              if (isAcceptOpenChallenge) {
                return OpenChallengeAcceptResultsShell(
                  sessionId: sessionId,
                  result: r,
                );
              }

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
                          onPressed: () async {
                            await DeferredPushPermissionCoordinator
                                .tryOfferFromResultsUserAction(
                              context,
                              ref,
                            );
                            if (!context.mounted) return;
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                          ),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth <= 700
                            ? constraints.maxWidth
                            : 700.0;
                        final h = constraints.maxHeight;
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: w,
                            height: h,
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
                                OpenChallengeResultsActions(
                                  sessionId: sessionId,
                                  result: r,
                                ),
                                OpenChallengePostFromResultsCard(
                                  sessionId: sessionId,
                                  result: r,
                                ),
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
                        );
                      },
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

class _ResultsLoadingWithTrace extends StatefulWidget {
  const _ResultsLoadingWithTrace({required this.sessionId});

  final String sessionId;

  @override
  State<_ResultsLoadingWithTrace> createState() =>
      _ResultsLoadingWithTraceState();
}

class _ResultsLoadingWithTraceState extends State<_ResultsLoadingWithTrace> {
  @override
  void initState() {
    super.initState();
    upscWarsTrace(
      'ResultsScreen LOADING mounted sessionId=${widget.sessionId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
