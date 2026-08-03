import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import '../data/onboarding_mcq_data.dart';
import '../widgets/onboarding_promise_page.dart';
import '../widgets/onboarding_mcq_page.dart';
import '../widgets/onboarding_scale.dart';
import '../widgets/onboarding_thesis_page.dart';
import '../widgets/onboarding_trap_page.dart';

/// Horizontal pager step id for [OnboardingStepDurationEvent].
String _onboardingStepIdForIndex(int i) {
  return switch (i) {
    0 => 'thesis',
    1 => 'trap',
    2 => 'mcq',
    3 => 'promise',
    _ => 'unknown',
  };
}

/// First-run onboarding: thesis → trap → markable MCQ → animated promise.
class OnboardingFlowScreen extends HookConsumerWidget {
  const OnboardingFlowScreen({super.key});

  static const int _pageCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final page = useState(0);
    final pageEnteredAt = useRef(DateTime.now());
    final onboardingFlowStartedAt = useRef(DateTime.now());
    final onboardingFlowCompleted = useRef(false);
    final highestPageIndex = useRef(0);
    final lastPageIndex = useRef(0);

    final mcqSelected = useState<int?>(null);
    final mcqConfidence = useState<OnboardingMcqConfidence?>(null);
    final mcqOutcome = useState<OnboardingMcqOutcome?>(null);
    final mcqOutcomeResolved = useRef(false);

    final bottom = MediaQuery.paddingOf(context).bottom;
    final hPad = onb(context, 20);
    final showSkip = page.value < _pageCount - 1;

    OnboardingMcqOutcome resolveOutcome() {
      final selected = mcqSelected.value;
      if (selected == null) return OnboardingMcqOutcome.skipped;
      final option = kOnboardingMcq.options[selected];
      return option.isCorrect
          ? OnboardingMcqOutcome.correct
          : OnboardingMcqOutcome.wrong;
    }

    void showMcqOutcome() {
      if (mcqOutcome.value != null) return;
      // Answered without picking a confidence level reads as a guess.
      if (mcqSelected.value != null && mcqConfidence.value == null) {
        mcqConfidence.value = OnboardingMcqConfidence.guessing;
      }
      mcqOutcome.value = resolveOutcome();
      final confidenceSuffix = mcqConfidence.value == null
          ? ''
          : '_${mcqConfidence.value!.name}';
      ScreenFlow.logAction(
        ref,
        screenName: ScreenFlow.onboarding,
        actionId: 'mcq_outcome_${mcqOutcome.value!.name}$confidenceSuffix',
      );
    }

    Future<void> completeFlow({required String actionId}) async {
      ScreenFlow.logAction(
        ref,
        screenName: ScreenFlow.onboarding,
        actionId: actionId,
      );
      await _complete(
        ref,
        context,
        markFlowCompleted: () {
          onboardingFlowCompleted.value = true;
        },
        lastStepIndex: page.value,
        lastStepStartedAt: pageEnteredAt.value,
        onboardingFlowStartedAt: onboardingFlowStartedAt.value,
      );
    }

    void goToPage(int i) {
      pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    useEffect(() {
      unawaited(Analytics.track(ref, const OnboardingFlowOpenedEvent()));
      return null;
    }, const []);

    useEffect(() {
      return () {
        if (onboardingFlowCompleted.value) return;
        final ms = DateTime.now()
            .difference(onboardingFlowStartedAt.value)
            .inMilliseconds;
        if (ms < 0) return;
        unawaited(
          Analytics.track(
            ref,
            OnboardingExitedIncompleteEvent(
              highestStep: _onboardingStepIdForIndex(highestPageIndex.value),
              lastStep: _onboardingStepIdForIndex(lastPageIndex.value),
              elapsedMs: ms,
              reachedLastStep: highestPageIndex.value == _pageCount - 1,
            ),
          ),
        );
      };
    }, const []);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: RgColors.pageBg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              onb(context, 10),
              hPad,
              bottom + onb(context, 10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopChrome(
                  index: page.value,
                  count: _pageCount,
                  showSkip: showSkip,
                  onSkip: () {
                    unawaited(completeFlow(actionId: 'onboarding_skipped'));
                  },
                ),
                SizedBox(height: onb(context, 14)),
                Expanded(
                  child: PageView(
                    controller: pageController,
                    // Forward = buttons only; swipe only goes back.
                    physics: const _OnboardingBackOnlyPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    onPageChanged: (i) {
                      final from = page.value;

                      // Safety: never land on promise until Got it (buttons).
                      if (i == 3 && !mcqOutcomeResolved.value) {
                        showMcqOutcome();
                        pageController.jumpToPage(2);
                        page.value = 2;
                        return;
                      }

                      final ms = DateTime.now()
                          .difference(pageEnteredAt.value)
                          .inMilliseconds;
                      if (ms >= 0) {
                        unawaited(
                          Analytics.track(
                            ref,
                            OnboardingStepDurationEvent(
                              step: _onboardingStepIdForIndex(from),
                              durationMs: ms,
                            ),
                          ),
                        );
                      }
                      pageEnteredAt.value = DateTime.now();
                      page.value = i;
                      lastPageIndex.value = i;
                      if (i > highestPageIndex.value) {
                        highestPageIndex.value = i;
                      }
                    },
                    children: [
                      OnboardingThesisPage(
                        onContinue: () {
                          ScreenFlow.logAction(
                            ref,
                            screenName: ScreenFlow.onboarding,
                            actionId: 'thesis_continued',
                          );
                          goToPage(1);
                        },
                      ),
                      OnboardingTrapPage(
                        onContinue: () {
                          ScreenFlow.logAction(
                            ref,
                            screenName: ScreenFlow.onboarding,
                            actionId: 'trap_continued',
                          );
                          goToPage(2);
                        },
                      ),
                      OnboardingMcqPage(
                        selectedIndex: mcqSelected.value,
                        confidence: mcqConfidence.value,
                        outcome: mcqOutcome.value,
                        onSelect: (i) => mcqSelected.value = i,
                        onConfidenceSelect: (c) => mcqConfidence.value = c,
                        onContinue: showMcqOutcome,
                        onGotIt: () {
                          mcqOutcomeResolved.value = true;
                          ScreenFlow.logAction(
                            ref,
                            screenName: ScreenFlow.onboarding,
                            actionId: 'mcq_got_it',
                          );
                          goToPage(3);
                        },
                      ),
                      OnboardingPromisePage(
                        isActive: page.value == 3,
                        onGetStarted: () {
                          unawaited(
                            completeFlow(actionId: 'promise_get_started'),
                          );
                        },
                        onSkip: () {
                          unawaited(
                            completeFlow(actionId: 'promise_skipped'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _complete(
  WidgetRef ref,
  BuildContext context, {
  required void Function() markFlowCompleted,
  required int lastStepIndex,
  required DateTime lastStepStartedAt,
  required DateTime onboardingFlowStartedAt,
}) async {
  markFlowCompleted();
  final ms = DateTime.now().difference(lastStepStartedAt).inMilliseconds;
  if (ms >= 0) {
    unawaited(
      Analytics.track(
        ref,
        OnboardingStepDurationEvent(
          step: _onboardingStepIdForIndex(lastStepIndex),
          durationMs: ms,
        ),
      ),
    );
  }
  final totalMs =
      DateTime.now().difference(onboardingFlowStartedAt).inMilliseconds;
  if (totalMs >= 0) {
    unawaited(
      Analytics.track(
        ref,
        OnboardingFlowCompletedEvent(totalDurationMs: totalMs),
      ),
    );
  }
  unawaited(
    logActivationMilestoneOnce(
      ref,
      ActivationMilestones.onboardingFlowCompleted,
    ),
  );
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.patternInterruptOnboardingSeen = true;
  prefs.getStartedSheetPendingAfterOnboarding = true;
  ref.invalidate(prefsServiceProvider);
  if (context.mounted) context.go('/');
}

class _TopChrome extends StatelessWidget {
  const _TopChrome({
    required this.index,
    required this.count,
    required this.showSkip,
    required this.onSkip,
  });

  final int index;
  final int count;
  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(count, (i) {
              final on = i == index;
              final passed = i < index;
              return Padding(
                padding: EdgeInsets.only(right: onb(context, 5)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: onb(context, 6),
                  width: on
                      ? onb(context, 18)
                      : passed
                      ? onb(context, 10)
                      : onb(context, 6),
                  decoration: BoxDecoration(
                    color: on
                        ? RgColors.ink
                        : passed
                        ? RgColors.ink.withValues(alpha: 0.35)
                        : RgColors.border,
                    borderRadius: BorderRadius.circular(onb(context, 4)),
                  ),
                ),
              );
            }),
          ),
        ),
        if (showSkip)
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: RgColors.muted,
              padding: EdgeInsets.symmetric(horizontal: onb(context, 8)),
              minimumSize: Size(onb(context, 44), onb(context, 32)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'SKIP',
              style: RgText.mono(
                size: onb(context, 10),
                letterSpacingEm: 0.05,
                color: RgColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Allows swipe/drag only toward previous pages. Forward advances via buttons.
class _OnboardingBackOnlyPhysics extends PageScrollPhysics {
  const _OnboardingBackOnlyPhysics({super.parent});

  @override
  _OnboardingBackOnlyPhysics applyTo(ScrollPhysics? ancestor) {
    return _OnboardingBackOnlyPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // LTR PageView: positive offset moves toward the next page.
    if (offset > 0) return 0;
    return offset;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Kill flings that would advance to the next page.
    final v = velocity > 0 ? 0.0 : velocity;
    return super.createBallisticSimulation(position, v);
  }
}
