import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/debug/upsc_wars_trace.dart';
import '../../../core/presentation/session_subject_label.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/domain/errors/app_errors.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/deep_link/shared_session_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
import '../../home/providers/home_activation_provider.dart';
import '../widgets/session_summary_coach.dart';
import '../widgets/share_test_bottom_sheet.dart';

String _sessionResultPhase(AsyncValue<SessionResult>? v) {
  if (v == null) return '(none)';
  return v.when(
    data: (_) => 'data',
    loading: () => 'loading',
    error: (_, _) => 'error',
  );
}

bool _resultsNeedsScrollableExtras(SessionResult r) {
  if (r.analyticsFeatureKey == 'mcq_battle') return true;
  final key = r.analyticsFeatureKey ?? '';
  return key.startsWith('share_deep_link_');
}

bool _resultsUseFixedCanvas(SessionResult r) =>
    !_resultsNeedsScrollableExtras(r);

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
      if (next.hasValue && prev?.hasValue != true) {
        ref.invalidate(homeActivationProvider);
      }
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
    final hPad = AppBreakpoints.fullScreenHPadding(MediaQuery.sizeOf(context).width);

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
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xs + hPad.left,
                      AppSpacing.sm,
                      AppSpacing.lg + hPad.right,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                          ),
                          onPressed: () async {
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
                          tooltip: 'Share test',
                          style: IconButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                          ),
                          onPressed: () => unawaited(
                            showShareTestBottomSheet(
                              context: context,
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
                        final horizontalPad = EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        );
                        final contactUs = const Center(
                          child: ContactUsTextButton(),
                        );

                        if (_resultsUseFixedCanvas(r)) {
                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: w,
                              height: h,
                              child: Padding(
                                padding: horizontalPad,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, coachConstraints) {
                                          return SessionSummaryCoachContent(
                                            sessionId: sessionId,
                                            result: r,
                                            displaySubjectName: displaySubject,
                                            maxHeight: coachConstraints.maxHeight,
                                          );
                                        },
                                      ),
                                    ),
                                    contactUs,
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final coach = SessionSummaryCoachContent(
                          sessionId: sessionId,
                          result: r,
                          displaySubjectName: displaySubject,
                          maxHeight: h,
                        );

                        return Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: horizontalPad,
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
                                if ((r.analyticsFeatureKey ?? '')
                                    .startsWith('share_deep_link_')) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  _SharedLeaderboardSection(
                                    shareId: sessionId,
                                    scorePct: r.accuracy,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],
                                coach,
                                const SizedBox(height: AppSpacing.lg),
                                contactUs,
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

class _SharedLeaderboardSection extends ConsumerStatefulWidget {
  const _SharedLeaderboardSection({
    required this.shareId,
    required this.scorePct,
  });

  final String shareId;
  final double scorePct;

  @override
  ConsumerState<_SharedLeaderboardSection> createState() =>
      _SharedLeaderboardSectionState();
}

class _SharedLeaderboardSectionState
    extends ConsumerState<_SharedLeaderboardSection> {
  static const _namePrefKey = 'share_participant_name_v1';

  bool _posted = false;
  late Future<List<SharedLeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = SharedSessionFirestoreRepository().fetchTopLeaderboard(
      shareId: widget.shareId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_posted) return;
    _posted = true;
    unawaited(_maybePostAttempt());
  }

  Future<void> _maybePostAttempt() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    final postedKey = 'share_lb_posted_${widget.shareId}_v1';
    if (prefs.getBool(postedKey)) return;

    final user = FirebaseAuth.instance.currentUser;
    final rawName = (user?.displayName ?? user?.email) ?? prefs.getString(_namePrefKey) ?? '';
    final name = rawName.trim();
    if (name.isEmpty) return;

    try {
      await SharedSessionFirestoreRepository().appendLeaderboardAttempt(
        shareId: widget.shareId,
        name: name,
        score: widget.scorePct,
      );
      await prefs.setBool(postedKey, true);
      if (!mounted) return;
      setState(() {
        _future = SharedSessionFirestoreRepository().fetchTopLeaderboard(
          shareId: widget.shareId,
        );
      });
    } catch (_) {
      // Non-blocking; leaderboard posting is best-effort.
    }
  }

  String _currentName(AsyncValue<PrefsService> prefsAsync) {
    final user = FirebaseAuth.instance.currentUser;
    final fromAuth = (user?.displayName ?? user?.email)?.trim();
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;
    final prefs = prefsAsync.asData?.value;
    final raw = prefs?.getString(_namePrefKey)?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'You';
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(prefsServiceProvider);
    return FutureBuilder<List<SharedLeaderboardEntry>>(
      future: _future,
      builder: (context, snap) {
        final list = snap.data ?? const <SharedLeaderboardEntry>[];
        final top5 = list.length <= 5 ? list : list.sublist(0, 5);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final me = _currentName(prefsAsync);
        final meNorm = me.trim().toLowerCase();
        final inTop5 = top5.any((e) => e.name.trim().toLowerCase() == meNorm);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.correct,
                AppColors.correct.withValues(alpha: isDark ? 0.75 : 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: AppTextStyles.label().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Top 5 for this shared test',
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      'Your score: ${widget.scorePct.round()}%',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (snap.connectionState == ConnectionState.waiting && list.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                )
              else if (top5.isEmpty)
                Text(
                  "It's empty.",
                  style: AppTextStyles.bodySm().copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < top5.length; i++)
                      _LeaderRow(
                        rank: i + 1,
                        name: top5[i].name,
                        scorePct: top5[i].score,
                        highlight: top5[i].name.trim().toLowerCase() == meNorm,
                      ),
                    if (!inTop5) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$me (you)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm().copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${widget.scorePct.round()}%',
                            style: AppTextStyles.bodySm().copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Could not load leaderboard.',
                    style: AppTextStyles.caption().copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.scorePct,
    required this.highlight,
  });

  final int rank;
  final String name;
  final double scorePct;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final badgeBg = highlight
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.12);
    final border =
        highlight ? Colors.white.withValues(alpha: 0.95) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border, width: highlight ? 1.4 : 0.0),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#$rank',
                style: AppTextStyles.caption().copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm().copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${scorePct.round()}%',
              style: AppTextStyles.bodySm().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
