import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/debug/upsc_wars_trace.dart';
import '../../../core/responsive/app_breakpoints.dart';
import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/analytics/session_analytics_derive.dart';
import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/domain/errors/app_errors.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/pyq_badge.dart';
import '../../../shared/widgets/question_table_view.dart';
import '../../../shared/theme/dark_mode_toggle.dart';
import '../../../shared/widgets/debug_correct_answer_banner.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../../../shared/widgets/en_hi_language_toggle.dart';
import '../../question_editor/widgets/question_editor_access.dart';
import '../../../shared/widgets/selectable_copy_search_text.dart';
import '../../../shared/widgets/top_snack_bar.dart';
import '../../community/widgets/share_qotd_sheet.dart';
import '../../history/widgets/explanation_card.dart';
import '../../home/domain/create_get_started_session_use_case.dart';
import '../../home/providers/home_activation_journey_provider.dart';
import '../../push_spot_test/push_spot_test_constants.dart';
import '../providers/test_session_provider.dart';
import '../providers/test_session_state.dart';
import '../widgets/demo_language_coach_overlay.dart';
import '../widgets/exam_option_confidence_strip.dart';
import '../widgets/test_engine_question_shimmer.dart';
import '../../../l10n/l10n.dart';

Future<void> _showDemoConfidenceIntroThenPrompt(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  final session = ref
      .read(testSessionProvider(sessionId))
      .asData
      ?.value
      .session;
  final isDemo =
      session?.analyticsFeatureKey ==
      CreateGetStartedSessionUseCase.analyticsKey;
  if (isDemo) {
    final prefs = await ref.read(prefsServiceProvider.future);
    if (!prefs.demoConfidenceIntroSeen) {
      if (!context.mounted) return;
      await _showDemoConfidenceIntroSheet(context);
      prefs.demoConfidenceIntroSeen = true;
    }
  }
  if (!context.mounted) return;
  await _showConfidenceBottomSheet(context, ref, sessionId);
}

Future<void> _showDemoExplanationCoachSheet(
  BuildContext context, {
  required bool isCorrect,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DismissOnScrimTap(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isCorrect
                        ? context.l10n.demoFeedbackCorrectTitle
                        : context.l10n.demoFeedbackWrongTitle,
                    style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isCorrect
                        ? context.l10n.testHintCorrect
                        : context.l10n.testHintWrong,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.l10n.testShowExplanation),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _scrollToExplanation(GlobalKey key) {
  final target = key.currentContext;
  if (target == null) return;
  Scrollable.ensureVisible(
    target,
    alignment: 0.04,
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );
}

Future<void> _showDemoConfidenceIntroSheet(BuildContext context) async {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.testConfidenceIntroTitle,
                style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text: context.l10n.testConfidenceWhy,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    TextSpan(text: context.l10n.testConfidenceWhyBody),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.commonGotIt),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showConfidenceBottomSheet(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.testHowSure,
                style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.testHowSureBody,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref
                      .read(testSessionProvider(sessionId).notifier)
                      .submitConfidenceForPending(AnswerConfidence.verySure);
                },
                child: Text(
                  AnswerConfidence.examShortLabel(AnswerConfidence.verySure),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref
                      .read(testSessionProvider(sessionId).notifier)
                      .submitConfidenceForPending(
                        AnswerConfidence.somewhatSure,
                      );
                },
                child: Text(
                  AnswerConfidence.examShortLabel(
                    AnswerConfidence.somewhatSure,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref
                      .read(testSessionProvider(sessionId).notifier)
                      .submitConfidenceForPending(AnswerConfidence.guessing);
                },
                child: Text(
                  AnswerConfidence.examShortLabel(AnswerConfidence.guessing),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  final stillOpen =
      ref
          .read(testSessionProvider(sessionId))
          .asData
          ?.value
          .confidencePromptVisible ??
      false;
  if (stillOpen && context.mounted) {
    ref.read(testSessionProvider(sessionId).notifier).cancelConfidencePrompt();
  }
}

class TestEngineScreen extends HookConsumerWidget {
  const TestEngineScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(testSessionProvider(sessionId).notifier);
    final sessionMeta = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final s = a.asData?.value.session;
        if (s == null) return null;
        return (s.mode, s.analyticsFeatureKey);
      }),
    );
    final mode = sessionMeta?.$1;
    final isDemo =
        sessionMeta?.$2 == CreateGetStartedSessionUseCase.analyticsKey;

    void leaveToHome({required String actionId, required String actionKind}) {
      ScreenFlow.logAction(
        ref,
        screenName: ScreenFlow.testSession,
        actionId: actionId,
        actionKind: actionKind,
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isDemo) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                context.l10n.testLeaveDemoTitle,
                style: AppTextStyles.h3(),
              ),
              content: Text(
                context.l10n.testLeaveDemoBody,
                style: AppTextStyles.bodyMd(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.l10n.commonCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.l10n.testLeave),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            ref.invalidate(homeActivationJourneyProvider);
            leaveToHome(
              actionId: 'demo_leave_after_dialog',
              actionKind: 'back',
            );
          }
          return;
        }
        final isDiscard = mode == 'exam';
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              isDiscard
                  ? context.l10n.testGoBackTitle
                  : context.l10n.testLeaveTestTitle,
              style: AppTextStyles.h3(),
            ),
            content: Text(
              isDiscard
                  ? context.l10n.testGoBackBody
                  : context.l10n.testLeaveTestBody,
              style: AppTextStyles.bodyMd(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  isDiscard ? context.l10n.testGoBack : context.l10n.testLeave,
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          if (isDiscard) {
            await notifier.discardSession();
          } else if (mode != 'learning') {
            await notifier.markAbandoned();
          }
          if (context.mounted) {
            leaveToHome(actionId: 'leave_after_dialog', actionKind: 'back');
          }
        }
      },
      child: Scaffold(
        body: SafeArea(child: _TestEngineAsyncBody(sessionId: sessionId)),
      ),
    );
  }
}

class _TestEngineAsyncBody extends HookConsumerWidget {
  const _TestEngineAsyncBody({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      testSessionProvider(sessionId).select((a) => a.isLoading),
    );
    final err = ref.watch(
      testSessionProvider(sessionId).select((a) => a.hasError ? a.error : null),
    );
    final notifier = ref.read(testSessionProvider(sessionId).notifier);

    if (loading) {
      return const TestEngineQuestionShimmer();
    }
    if (err != null) {
      final isNotFound = err is SessionNotFoundException;
      final isNoQuestions = err is SessionHasNoQuestionsException;
      final msg = isNotFound
          ? context.l10n.testSessionNotFound
          : isNoQuestions
          ? context.l10n.commonSomethingWrong
          : context.l10n.testSessionLoadFailed;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg, style: AppTextStyles.body()),
              const SizedBox(height: AppSpacing.lg),
              if (!isNotFound && !isNoQuestions)
                OutlinedButton(
                  onPressed: notifier.reload,
                  child: Text(
                    context.l10n.commonRetry,
                    style: AppTextStyles.label(),
                  ),
                ),
              if (isNotFound || isNoQuestions) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () {
                    ScreenFlow.logAction(
                      ref,
                      screenName: ScreenFlow.testSession,
                      actionId: 'error_go_home',
                      actionKind: 'back',
                    );
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  child: Text('Home', style: AppTextStyles.label()),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _TestEngineLoaded(sessionId: sessionId);
  }
}

class _TestEngineTimerTicker extends HookConsumerWidget {
  const _TestEngineTimerTicker({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        if (v?.session == null) return false;
        if (v!.preStartPaused) return false;
        if (v.explanationVisible && v.session!.mode == 'learning') {
          return false;
        }
        return true;
      }),
    );

    useEffect(() {
      if (!run) return null;
      Timer? timer;
      timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final notifier = ref.read(testSessionProvider(sessionId).notifier);
        notifier.tickSecond();
        final now = ref.read(testSessionProvider(sessionId)).asData?.value;
        final current = now?.session;
        if (now == null || current == null) return;

        if (current.mode == 'learning') {
          if (!now.explanationVisible && now.learningRemainingSecs == 0) {
            await notifier.onLearningTimedOut();
          }
        } else if (current.isTimed && current.timeLimitSecs != null) {
          final remain = current.timeLimitSecs! - now.totalElapsedSecs;
          if (remain <= 0 && !now.isSubmitting) {
            if (now.confidencePromptVisible) {
              notifier.cancelConfidencePrompt();
            }
            try {
              final submitted = await notifier.submit();
              if (context.mounted) {
                final featureKey = ref
                    .read(testSessionProvider(sessionId))
                    .asData
                    ?.value
                    .session
                    ?.analyticsFeatureKey;
                upscWarsTrace(
                  'TestEngine timer submit -> go '
                  '${sessionResultsRouteForKey(submitted, featureKey)}',
                );
                context.go(sessionResultsRouteForKey(submitted, featureKey));
              }
            } catch (e, st) {
              upscWarsTrace(
                'TestEngine timer submit FAILED sessionId=$sessionId',
                error: e,
                stackTrace: st,
              );
            }
          }
        }
      });
      return () => timer?.cancel();
    }, [run, sessionId]);

    return const SizedBox.shrink();
  }
}

class _TestEngineLoaded extends HookConsumerWidget {
  const _TestEngineLoaded({required this.sessionId});

  final String sessionId;

  static const String _kSingleQuestionTutorialKey =
      'share_single_question_tutorial';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(testSessionProvider(sessionId).notifier);
    final sessionForFx = ref.watch(
      testSessionProvider(sessionId).select((a) => a.asData?.value.session),
    );
    final prefs = ref.watch(prefsServiceProvider).asData?.value;
    final demoCoachesResetForVisit = useRef(false);
    final isDemoSession =
        sessionForFx?.analyticsFeatureKey ==
        CreateGetStartedSessionUseCase.analyticsKey;
    if (isDemoSession && prefs != null && !demoCoachesResetForVisit.value) {
      prefs.resetDemoCoachPrompts();
      demoCoachesResetForVisit.value = true;
    }
    final featureStartedSent = useRef(false);
    final languageToggleKey = useMemoized(GlobalKey.new);
    final languageCoachRequested = useRef(false);
    useEffect(() {
      if (languageCoachRequested.value) return null;
      if (!isDemoSession || prefs == null) return null;
      languageCoachRequested.value = true;
      var cancelled = false;
      OverlayEntry? entry;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (cancelled || !context.mounted) return;
        if (prefs.demoLanguageCoachSeen) return;
        prefs.demoLanguageCoachSeen = true;
        void dismiss() {
          final current = entry;
          if (current == null || !current.mounted) return;
          current.remove();
        }

        entry = OverlayEntry(
          builder: (ctx) => DemoLanguageCoachOverlay(
            toggleKey: languageToggleKey,
            onDismiss: dismiss,
          ),
        );
        Overlay.of(context).insert(entry!);
      });
      return () {
        cancelled = true;
        final current = entry;
        if (current != null && current.mounted) current.remove();
      };
    }, [isDemoSession, prefs != null]);
    useEffect(() {
      final s = sessionForFx;
      if (s == null || featureStartedSent.value) return null;
      featureStartedSent.value = true;
      final labels = deriveSessionAnalyticsLabels(
        analyticsFeatureKey: s.analyticsFeatureKey,
        subject: s.subject,
      );
      unawaited(
        Analytics.track(
          ref,
          FeatureStartedEvent(
            featureName: labels.featureName,
            subject: s.subject,
            topic: s.topic,
            difficulty: null,
            source: labels.source,
          ),
        ),
      );
      unawaited(
        Analytics.track(
          ref,
          McqTestSessionStartedEvent(
            subject: s.subject,
            topic: s.topic,
            analyticsFeatureKey: s.analyticsFeatureKey,
          ),
        ),
      );
      unawaited(
        logActivationMilestoneOnce(
          ref,
          ActivationMilestones.firstMcqTestEntered,
        ),
      );
      if (s.analyticsFeatureKey !=
          CreateGetStartedSessionUseCase.analyticsKey) {
        unawaited(maybeLogPostDemoExplore(ref, surface: 'mcq_test'));
      }
      if (s.subject == 'revision' || s.subject == 'revision_quick') {
        unawaited(
          Analytics.track(
            ref,
            RevisionStartedEvent(
              questionsCount: s.questionCount,
              subject: s.subject,
            ),
          ),
        );
        unawaited(
          logActivationMilestoneOnce(
            ref,
            ActivationMilestones.firstRevisionTest,
          ),
        );
      }
      return null;
    }, [sessionForFx]);

    ref.listen<AsyncValue<TestSessionState>>(testSessionProvider(sessionId), (
      prev,
      next,
    ) {
      final was = prev?.asData?.value.confidencePromptVisible ?? false;
      final now = next.asData?.value.confidencePromptVisible ?? false;
      if (!was && now) {
        unawaited(_showDemoConfidenceIntroThenPrompt(context, ref, sessionId));
      }
    });

    final sessionLanguage =
        ref.watch(
          testSessionProvider(
            sessionId,
          ).select((a) => a.asData?.value.session?.language),
        ) ??
        'en';
    final preferredLanguage = watchAppLanguage(ref, fallback: sessionLanguage);
    final uiLanguage = useState(preferredLanguage);
    final showBanner = ref.watch(
      testSessionProvider(
        sessionId,
      ).select((a) => a.asData?.value.showTimedExamResumeBanner ?? false),
    );

    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final hPadding = AppBreakpoints.fullScreenHPadding(
      MediaQuery.sizeOf(context).width,
    );

    final isSingleQuestionTutorial = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final s = a.asData?.value.session;
        if (s == null) return false;
        return s.mode == 'learning' &&
            s.questionCount == 1 &&
            (s.analyticsFeatureKey == _kSingleQuestionTutorialKey);
      }),
    );

    return Padding(
      padding: hPadding,
      child: Column(
        children: [
          _TestEngineTimerTicker(sessionId: sessionId),
          if (showBanner)
            Material(
              color: AppColors.transparent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                color: scheme.surfaceContainerLow,
                child: Text(
                  context.l10n.testTimerPausedNotice,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Material(
            color: scheme.surface,
            elevation: isDark ? 0 : 1,
            shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.5 : 0.12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopBar(
                  sessionId: sessionId,
                  uiLanguage: uiLanguage.value,
                  languageToggleKey: languageToggleKey,
                  onLanguageChanged: (value) {
                    uiLanguage.value = value;
                    unawaited(persistAppLanguage(ref, value));
                  },
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                if (!isSingleQuestionTutorial)
                  _ExamActionRow(
                    sessionId: sessionId,
                    onPalette: () =>
                        _showTestPaletteSheet(context, ref, sessionId),
                    onSubmit: () =>
                        _showTestPaletteSheet(context, ref, sessionId),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _QuestionArea(
              sessionId: sessionId,
              uiLanguage: uiLanguage.value,
              onSelectOption: notifier.selectOption,
            ),
          ),
          if (!isSingleQuestionTutorial)
            _BottomBar(
              sessionId: sessionId,
              onPrev: notifier.movePrev,
              onNext: notifier.moveNext,
              onBookmark: () async {
                final marked = await notifier.toggleBookmark();
                if (!context.mounted) return;
                showTopSnackBar(
                  context,
                  content: Text(
                    marked
                        ? context.l10n.testBookmarked
                        : context.l10n.testBookmarkRemoved,
                    style: AppTextStyles.bodyMd().copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

Future<void> _showTestPaletteSheet(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  final async = ref.read(testSessionProvider(sessionId));
  final state = async.asData?.value;
  final notifier = ref.read(testSessionProvider(sessionId).notifier);
  if (state == null || state.session == null) return;
  final session = state.session!;
  final isDark = context.isDarkMode;
  final scheme = Theme.of(context).colorScheme;
  final attempted = session.questions
      .where((q) => q.status != 'unattempted')
      .length;
  final flagged = session.questions.where((q) => q.flagged).length;
  final skipped = session.questions
      .where((q) => q.status == 'unattempted')
      .length;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      final screenH = MediaQuery.of(ctx).size.height;
      return DismissOnScrimTap(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenH * 0.9),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerHigh
                        : scheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gray900.withValues(
                          alpha: isDark ? 0.45 : 0.14,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Question Grid',
                          style: AppTextStyles.h3().copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.testGridHint,
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _LegendItem(
                            label: context.l10n.testGridCurrent,
                            bg: AppColors.primary,
                            fg: AppColors.onPrimary,
                          ),
                          _LegendItem(
                            label: context.l10n.testGridAttempted,
                            bg: isDark
                                ? AppColors.correctBgDark
                                : AppColors.correctBg,
                            fg: isDark
                                ? AppColors.correctTextDark
                                : AppColors.correctText,
                          ),
                          _LegendItem(
                            label: context.l10n.testGridFlagged,
                            bg: isDark
                                ? AppColors.warningBgDark
                                : AppColors.warningBg,
                            fg: isDark
                                ? AppColors.warningTextDark
                                : AppColors.warningText,
                          ),
                          _LegendItem(
                            label: context.l10n.testGridNotVisited,
                            bg: scheme.surfaceContainerLow,
                            fg: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Flexible(
                        fit: FlexFit.loose,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (var i = 0; i < session.questions.length; i++)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    notifier.jumpToIndex(i);
                                  },
                                  child: _PaletteCell(
                                    index: i,
                                    currentIndex: state.currentIndex,
                                    q: session.questions[i],
                                    isDark: isDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 0.6,
                          ),
                        ),
                        child: Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                              width: 0.6,
                            ),
                          ),
                          children: [
                            TableRow(
                              children: [
                                _CountCell(
                                  label: context.l10n.testGridAttempted,
                                  value: '$attempted',
                                ),
                                _CountCell(
                                  label: context.l10n.testGridSkipped,
                                  value: '$skipped',
                                ),
                                _CountCell(
                                  label: context.l10n.testGridFlagged,
                                  value: '$flagged',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(context.l10n.testGoBack),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  final id = await notifier.submit();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (!context.mounted) return;
                                  final featureKey = ref
                                      .read(testSessionProvider(sessionId))
                                      .asData
                                      ?.value
                                      .session
                                      ?.analyticsFeatureKey;
                                  upscWarsTrace(
                                    'TestEngine palette submit -> go '
                                    '${sessionResultsRouteForKey(id, featureKey)}',
                                  );
                                  context.go(
                                    sessionResultsRouteForKey(id, featureKey),
                                  );
                                } catch (e, st) {
                                  upscWarsTrace(
                                    'TestEngine palette submit FAILED',
                                    error: e,
                                    stackTrace: st,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? scheme.errorContainer
                                    : AppColors.wrong,
                                foregroundColor: isDark
                                    ? scheme.onErrorContainer
                                    : null,
                              ),
                              child: Text(
                                session.mode == 'exam'
                                    ? context.l10n.testSubmitTest
                                    : context.l10n.testSubmit,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _CountCell extends HookConsumerWidget {
  const _CountCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends HookConsumerWidget {
  const _LegendItem({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final swatch = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '•',
          style: AppTextStyles.caption().copyWith(color: fg, height: 1),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TopBar extends HookConsumerWidget {
  const _TopBar({
    required this.sessionId,
    required this.uiLanguage,
    required this.onLanguageChanged,
    required this.onBack,
    this.languageToggleKey,
  });

  final String sessionId;
  final String uiLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onBack;
  final GlobalKey? languageToggleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final snap = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        final i = v.currentIndex;
        if (i < 0 || i >= s.questions.length) return null;
        final q = s.questions[i];
        return (v.currentIndex, s.questions.length, q.flagged, q.uuid);
      }),
    );

    if (snap == null) return const SizedBox.shrink();

    final (currentIndex, qLen, flagged, questionUuid) = snap;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.commonBack,
            onPressed: onBack,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            context.l10n.testQuestionOfTotal(currentIndex + 1, qLen),
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
          const Spacer(),
          QuestionEditorIconButton(
            questionUuid: questionUuid,
            onReturned: () =>
                ref.read(testSessionProvider(sessionId).notifier).reload(),
          ),
          EnHiLanguageToggle(
            key: languageToggleKey,
            language: uiLanguage,
            onChanged: onLanguageChanged,
            minHeight: 28,
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: () =>
                ref.read(testSessionProvider(sessionId).notifier).toggleFlag(),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: flagged
                    ? (context.isDarkMode
                          ? AppColors.warningBgDark
                          : AppColors.warningBg)
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                flagged ? Icons.flag : Icons.outlined_flag,
                size: 18,
                color: flagged ? AppColors.warning : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _TopBarDarkModeToggle(),
        ],
      ),
    );
  }
}

class _TopBarDarkModeToggle extends HookConsumerWidget {
  const _TopBarDarkModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    return InkWell(
      onTap: () async {
        await setDarkModeEnabled(ref: ref, darkModeEnabled: !isDark);
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TopBarTimerLabel extends HookConsumerWidget {
  const _TopBarTimerLabel({required this.sessionId});

  final String sessionId;

  static String _mmss(int total) {
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final t = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        if (s.mode == 'exam') {
          if (s.isTimed && s.timeLimitSecs != null) {
            final remain = (s.timeLimitSecs! - v.totalElapsedSecs).clamp(
              0,
              1 << 30,
            );
            return ('et', remain, remain <= 300);
          }
          return ('eu', v.totalElapsedSecs, false);
        }
        if (v.learningRemainingSecs < 0) {
          return ('lr', 0, false);
        }
        return ('l', v.learningRemainingSecs, false);
      }),
    );

    if (t == null) return const SizedBox.shrink();

    String rightLabel;
    Color rightColor;

    switch (t.$1) {
      case 'et':
        rightLabel = _mmss(t.$2);
        rightColor = t.$3 == true ? AppColors.wrong : scheme.onSurface;
      case 'eu':
        rightLabel = _mmss(t.$2);
        rightColor = scheme.onSurface;
      case 'l':
        final left = t.$2;
        rightLabel = _mmss(left);
        if (left > 30) {
          rightColor = AppColors.correct;
        } else if (left >= 10) {
          rightColor = AppColors.warning;
        } else {
          rightColor = AppColors.wrong;
        }
      case 'lr':
        rightLabel = 'Review';
        rightColor = scheme.onSurfaceVariant;
      default:
        rightLabel = '00:00';
        rightColor = scheme.onSurface;
    }

    return Text(
      rightLabel,
      style: AppTextStyles.label().copyWith(color: rightColor),
    );
  }
}

class _QuestionArea extends HookConsumerWidget {
  const _QuestionArea({
    required this.sessionId,
    required this.uiLanguage,
    required this.onSelectOption,
  });

  final String sessionId;
  final String uiLanguage;
  final Future<void> Function(String option) onSelectOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final snap = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        final i = v.currentIndex;
        if (i < 0 || i >= s.questions.length) return null;
        final q = s.questions[i];
        return (
          s.mode,
          v.explanationVisible,
          v.learningVerdict,
          q,
          s.analyticsFeatureKey,
        );
      }),
    );

    if (snap == null) return const SizedBox.shrink();

    final (mode, explanationVisible, learningVerdict, question, featureKey) =
        snap;
    final isDemoDiagnostic =
        featureKey == CreateGetStartedSessionUseCase.analyticsKey;
    final expandDeepDive = isDemoDiagnostic;
    final explanationKey = useMemoized(GlobalKey.new);
    final explanationWasVisible = useRef<bool?>(null);
    useEffect(() {
      final was = explanationWasVisible.value;
      explanationWasVisible.value = explanationVisible;
      if (mode != 'learning' || !explanationVisible) return null;
      final isInitialObservation = was == null;
      final justRevealed = was == false;
      if (!isInitialObservation && !justRevealed) return null;
      var cancelled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(() async {
          final showCoach =
              justRevealed &&
              isDemoDiagnostic &&
              (learningVerdict == LearningVerdict.correct ||
                  learningVerdict == LearningVerdict.incorrect);
          if (showCoach) {
            final prefs = await ref.read(prefsServiceProvider.future);
            if (cancelled || !context.mounted) return;
            if (!prefs.demoExplanationCoachSeen) {
              await Future<void>.delayed(const Duration(milliseconds: 320));
              if (cancelled || !context.mounted) return;
              await _showDemoExplanationCoachSheet(
                context,
                isCorrect: learningVerdict == LearningVerdict.correct,
              );
              if (!cancelled) {
                prefs.demoExplanationCoachSeen = true;
              }
              if (cancelled || !context.mounted) return;
              _scrollToExplanation(explanationKey);
              return;
            }
          }
          await Future<void>.delayed(const Duration(milliseconds: 80));
          if (cancelled) return;
          _scrollToExplanation(explanationKey);
        }());
      });
      return () => cancelled = true;
    }, [explanationVisible, question.uuid]);
    final isHindi = uiLanguage == 'hi';
    final displayText = isHindi ? question.displayTextHi : question.displayText;
    final optionA = isHindi ? question.optionAHi : question.optionA;
    final optionB = isHindi ? question.optionBHi : question.optionB;
    final optionC = isHindi ? question.optionCHi : question.optionC;
    final optionD = isHindi ? question.optionDHi : question.optionD;
    final tableData = isHindi ? question.tableDataHi : question.tableData;
    final trimmedDisplayText = displayText.trim();

    Widget questionContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.isPyq) ...[
          PyqBadge(year: question.sourceYear),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (trimmedDisplayText.isNotEmpty && !question.hasTable)
          SelectableCopySearchText(
            trimmedDisplayText,
            style: context.readingFont(
              AppTextStyles.question().copyWith(color: scheme.onSurface),
            ),
          ),
        if (question.hasTable && tableData != null) ...[
          SizedBox(
            height: trimmedDisplayText.isNotEmpty
                ? AppSpacing.sm
                : AppSpacing.xs,
          ),
          QuestionTableView(table: tableData),
        ],
      ],
    );

    Widget optionsContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionRow(
          keyLabel: 'A',
          optionKey: 'a',
          optionText: optionA,
          visual: _optionVisual(mode, question, 'a', explanationVisible),
          mode: mode,
          explanationVisible: explanationVisible,
          sessionId: sessionId,
          question: question,
          onTap: (mode == 'learning' && explanationVisible)
              ? null
              : () => onSelectOption('a'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionRow(
          keyLabel: 'B',
          optionKey: 'b',
          optionText: optionB,
          visual: _optionVisual(mode, question, 'b', explanationVisible),
          mode: mode,
          explanationVisible: explanationVisible,
          sessionId: sessionId,
          question: question,
          onTap: (mode == 'learning' && explanationVisible)
              ? null
              : () => onSelectOption('b'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OptionRow(
          keyLabel: 'C',
          optionKey: 'c',
          optionText: optionC,
          visual: _optionVisual(mode, question, 'c', explanationVisible),
          mode: mode,
          explanationVisible: explanationVisible,
          sessionId: sessionId,
          question: question,
          onTap: (mode == 'learning' && explanationVisible)
              ? null
              : () => onSelectOption('c'),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Key last option + explanation together so auto-scroll keeps D and
        // the explanation start in view (instead of pinning only the body).
        KeyedSubtree(
          key: explanationKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OptionRow(
                keyLabel: 'D',
                optionKey: 'd',
                optionText: optionD,
                visual: _optionVisual(mode, question, 'd', explanationVisible),
                mode: mode,
                explanationVisible: explanationVisible,
                sessionId: sessionId,
                question: question,
                onTap: (mode == 'learning' && explanationVisible)
                    ? null
                    : () => onSelectOption('d'),
              ),
              if (!explanationVisible) ...[
                const SizedBox(height: AppSpacing.sm),
                DebugCorrectAnswerBanner(question: question),
              ],
              if (mode == 'learning') ...[
                const SizedBox(height: AppSpacing.lg),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: explanationVisible
                      ? _ExplanationCard(
                          question: question,
                          uiLanguage: uiLanguage,
                          verdict: learningVerdict,
                          expandDeepDive: expandDeepDive,
                          showPostQotd: !isDemoDiagnostic,
                          analyticsSource: isDemoDiagnostic
                              ? 'demo_test'
                              : 'in_test',
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= AppBreakpoints.largeTablet;
        if (isTwoColumn) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 55,
                child: SingleChildScrollView(
                  key: ValueKey('q-${question.uuid}'),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: questionContent,
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 0.5,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                flex: 45,
                child: SingleChildScrollView(
                  key: ValueKey('opt-${question.uuid}'),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: optionsContent,
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          key: ValueKey(question.uuid),
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              questionContent,
              const SizedBox(height: AppSpacing.lg),
              optionsContent,
            ],
          ),
        );
      },
    );
  }

  _OptionVisual _optionVisual(
    String mode,
    TestQuestion q,
    String key,
    bool revealed,
  ) {
    final selected = q.selectedOption == key;
    final isCorrect = q.correctOption.toLowerCase() == key;

    if (mode == 'learning' && revealed) {
      if (q.status == 'timed_out') {
        if (isCorrect) return _OptionVisual.correct;
        return _OptionVisual.unselected;
      }
      if (isCorrect) return _OptionVisual.correct;
      if (selected && !isCorrect) return _OptionVisual.wrong;
      return _OptionVisual.unselected;
    }

    if (selected) return _OptionVisual.selected;
    return _OptionVisual.unselected;
  }
}

enum _OptionVisual { unselected, selected, correct, wrong }

class _OptionRow extends HookConsumerWidget {
  const _OptionRow({
    required this.keyLabel,
    required this.optionKey,
    required this.optionText,
    required this.visual,
    required this.onTap,
    required this.mode,
    required this.explanationVisible,
    required this.sessionId,
    required this.question,
  });

  final String keyLabel;
  final String optionKey;
  final String optionText;
  final _OptionVisual visual;
  final VoidCallback? onTap;
  final String mode;
  final bool explanationVisible;
  final String sessionId;
  final TestQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final prefs = ref.watch(prefsServiceProvider).value;

    Color bg;
    Color border;
    Color text;
    Color badgeBg;
    Color badgeText;
    double borderWidth;

    switch (visual) {
      case _OptionVisual.unselected:
        bg = scheme.surface;
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        text = scheme.onSurface;
        badgeBg = scheme.surfaceContainerLow;
        badgeText = scheme.onSurfaceVariant;
        borderWidth = 0.5;
      case _OptionVisual.selected:
        bg = isDark ? AppColors.primaryDeep : AppColors.primaryLight;
        border = AppColors.primary;
        text = isDark ? AppColors.onPrimary : AppColors.primaryDeep;
        badgeBg = AppColors.primary;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case _OptionVisual.correct:
        bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
        border = AppColors.correct;
        text = isDark ? AppColors.correctTextDark : AppColors.correctText;
        badgeBg = AppColors.correct;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
      case _OptionVisual.wrong:
        bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
        border = AppColors.wrong;
        text = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
        badgeBg = AppColors.wrong;
        badgeText = AppColors.onPrimary;
        borderWidth = 2;
    }

    final scored = question.status == 'correct' || question.status == 'wrong';
    final selectedHere =
        question.selectedOption?.toLowerCase() == optionKey.toLowerCase();
    final showLearningConfidenceStrip =
        mode == 'learning' && explanationVisible && scored && selectedHere;
    final showExamConfidenceStrip = mode == 'exam' && scored && selectedHere;
    final showOptionConfidenceStrip =
        (prefs?.confidenceTrackingEnabled ?? false) &&
        (showExamConfidenceStrip || showLearningConfidenceStrip);
    final learningConfidenceInteractionLocked =
        mode == 'learning' && explanationVisible && question.confidence != null;

    final outerRadius = BorderRadius.circular(AppRadius.md);

    return ClipRRect(
      borderRadius: outerRadius,
      child: Material(
        color: AppColors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: outerRadius,
            border: Border.all(color: border, width: borderWidth),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onTap != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: showOptionConfidenceStrip
                        ? const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.md),
                          )
                        : BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  keyLabel,
                                  style: AppTextStyles.labelSm().copyWith(
                                    color: badgeText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: AppTextStyles.option().copyWith(
                                  color: text,
                                ),
                                children: doubleAsteriskBoldInlineSpans(
                                  optionText,
                                  AppTextStyles.option().copyWith(color: text),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              keyLabel,
                              style: AppTextStyles.labelSm().copyWith(
                                color: badgeText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SelectableCopySearchText(
                          optionText,
                          style: AppTextStyles.option().copyWith(color: text),
                        ),
                      ),
                    ],
                  ),
                ),
              if (showOptionConfidenceStrip) ...[
                Divider(
                  height: 1,
                  thickness: 1,
                  color: border.withValues(alpha: isDark ? 0.45 : 0.35),
                ),
                ExamOptionConfidenceStrip(
                  liveSessionId: sessionId,
                  question: question,
                  interactionLocked: learningConfidenceInteractionLocked,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends HookConsumerWidget {
  const _ExplanationCard({
    required this.question,
    required this.uiLanguage,
    required this.verdict,
    this.expandDeepDive = false,
    this.showPostQotd = true,
    this.analyticsSource,
  });

  final TestQuestion question;
  final String uiLanguage;
  final LearningVerdict? verdict;
  final bool expandDeepDive;
  final bool showPostQotd;
  final String? analyticsSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isHindi = uiLanguage == 'hi';
    final finalExplanation = isHindi
        ? question.finalExplanationHi
        : question.finalExplanation;
    final statementAnalysis = isHindi
        ? question.statementAnalysisHi
        : question.statementAnalysis;
    final eliminationLogic = isHindi
        ? question.eliminationLogicHi
        : question.eliminationLogic;
    final strongDistractor = isHindi
        ? question.strongDistractorHi
        : question.strongDistractor;
    final upscTrapExplanation = isHindi
        ? question.upscTrapExplanationHi
        : question.upscTrapExplanation;

    final cardRadius = BorderRadius.circular(AppRadius.lg);

    return ClipRRect(
      borderRadius: cardRadius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        key: ValueKey('${question.uuid}-${verdict?.name ?? 'none'}'),
        decoration: BoxDecoration(color: scheme.surfaceContainerLow),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExplanationCard(
              demoForceDeepDive: expandDeepDive ? true : null,
              analyticsSource: analyticsSource,
              translation: QuestionTranslation(
                finalExplanation: finalExplanation,
                statementAnalysis: statementAnalysis
                    .map(
                      (e) => StatementAnalysisVm(
                        statement: e.label,
                        isCorrect: e.isCorrect,
                        reason: e.reason,
                      ),
                    )
                    .toList(),
                eliminationLogic: eliminationLogic,
                strongDistractor: strongDistractor,
                upscTrapExplanation: upscTrapExplanation,
                conceptsUsed: question.conceptsUsed,
              ),
              showStatements: statementAnalysis.isNotEmpty,
            ),
            if (showPostQotd) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => showShareQotdSheet(
                  context: context,
                  ref: ref,
                  questionUuid: question.uuid,
                  correctOption: question.correctOption,
                ),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Post QOTD'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends HookConsumerWidget {
  const _BottomBar({
    required this.sessionId,
    required this.onPrev,
    required this.onNext,
    required this.onBookmark,
  });

  final String sessionId;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final Future<void> Function() onBookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(
      testSessionProvider(sessionId).select((a) {
        final v = a.asData?.value;
        final s = v?.session;
        if (v == null || s == null) return null;
        return (
          s.mode,
          v.currentIndex,
          s.questions.length,
          v.furthestAnsweredIndex,
          v.bookmarkedByUuid[s.questions[v.currentIndex].uuid] ?? false,
          s.questions[v.currentIndex].selectedOption != null ||
              s.questions[v.currentIndex].status == 'timed_out',
        );
      }),
    );

    if (snap == null) return const SizedBox.shrink();

    final (
      mode,
      currentIndex,
      qLen,
      furthestAnsweredIndex,
      currentBookmarked,
      currentQuestionAnswered,
    ) = snap;
    final last = currentIndex == qLen - 1;
    final canPrev = currentIndex > 0;
    final canAdvanceLearning =
        currentIndex < furthestAnsweredIndex || currentQuestionAnswered;
    final canNext = mode == 'exam' ? !last : (!last && canAdvanceLearning);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canPrev ? onPrev : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: Text(context.l10n.testPrev),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onBookmark,
            icon: Icon(
              currentBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canNext ? onNext : null,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: Text(context.l10n.testNext),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamActionRow extends HookConsumerWidget {
  const _ExamActionRow({
    required this.sessionId,
    required this.onPalette,
    required this.onSubmit,
  });

  final String sessionId;
  final Future<void> Function() onPalette;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final topic = ref.watch(
      testSessionProvider(
        sessionId,
      ).select((a) => a.asData?.value.session?.topic),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OutlinedButton(
                onPressed: onPalette,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: const Icon(Icons.grid_view_outlined, size: 18),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: onSubmit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: isDark ? scheme.error : AppColors.wrong,
                  side: BorderSide(
                    color: isDark ? scheme.error : AppColors.wrong,
                  ),
                ),
                child: Text(context.l10n.testSubmit),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (topic != null && topic.isNotEmpty)
                Expanded(
                  child: Text(
                    topic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: AppSpacing.sm),
              _TopBarTimerLabel(sessionId: sessionId),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaletteCell extends HookConsumerWidget {
  const _PaletteCell({
    required this.index,
    required this.currentIndex,
    required this.q,
    required this.isDark,
  });

  final int index;
  final int currentIndex;
  final TestQuestion q;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;

    if (index == currentIndex) {
      bg = AppColors.primary;
      fg = AppColors.onPrimary;
    } else if (q.flagged) {
      bg = isDark ? AppColors.warningBgDark : AppColors.warningBg;
      fg = isDark ? AppColors.warningTextDark : AppColors.warningText;
    } else if (q.status != 'unattempted') {
      bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
      fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
    } else {
      bg = scheme.surfaceContainerLow;
      fg = scheme.onSurfaceVariant;
    }

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '${index + 1}',
        style: AppTextStyles.labelSm().copyWith(color: fg),
      ),
    );
  }
}
