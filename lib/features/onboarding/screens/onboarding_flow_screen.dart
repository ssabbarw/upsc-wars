import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../widgets/onboarding_fact_or_bluff_page.dart';
import '../widgets/onboarding_memory_pairs_page.dart';

/// Scale vs ~390dp shortest side (phone-first baseline); clamped for large/small devices.
double _onbScale(BuildContext context) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  return (shortest / 390).clamp(0.78, 1.22);
}

double _onb(BuildContext context, double designPx) =>
    designPx * _onbScale(context);

/// Horizontal pager step id for [OnboardingStepDurationEvent]. The demo step
/// id reflects which game Remote Config chose so funnels stay comparable.
String _onboardingStepIdForIndex(int i, String demoGame) {
  return switch (i) {
    0 => 'score_story',
    1 =>
      demoGame == onboardingGameFactOrBluff
          ? 'fact_or_bluff_demo'
          : 'memory_pairs_demo',
    2 => 'loop',
    _ => 'unknown',
  };
}

/// First-run onboarding: score story → memory-pairs demo → daily loop, then home.
class OnboardingFlowScreen extends HookConsumerWidget {
  const OnboardingFlowScreen({super.key});

  static const int _pageCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final page = useState(0);
    final pageEnteredAt = useRef(DateTime.now());
    final onboardingFlowStartedAt = useRef(DateTime.now());
    final onboardingFlowCompleted = useRef(false);
    final highestPageIndex = useRef(0);
    final lastPageIndex = useRef(0);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLast = page.value == _pageCount - 1;
    final onGameDemoPage = page.value == 1;
    final hPad = _onb(context, 20);
    final vPadSm = _onb(context, 8);

    // Which game the demo step shows (Remote Config A/B). Falls back to
    // memory pairs until RC resolves; frozen once the user reaches the demo
    // page so a late RC fetch cannot swap the game mid-play.
    final demoGameFrozen = useRef<String?>(null);
    final demoGame =
        demoGameFrozen.value ??
        ref.watch(onboardingGameRemoteProvider).asData?.value ??
        onboardingGameMemoryPairs;
    if (page.value >= 1) demoGameFrozen.value ??= demoGame;
    final demoGameRef = useRef(demoGame);
    demoGameRef.value = demoGame;

    void goToLoopPage() {
      pageController.animateToPage(
        _pageCount - 1,
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
              highestStep: _onboardingStepIdForIndex(
                highestPageIndex.value,
                demoGameRef.value,
              ),
              lastStep: _onboardingStepIdForIndex(
                lastPageIndex.value,
                demoGameRef.value,
              ),
              elapsedMs: ms,
              reachedLastStep: highestPageIndex.value == _pageCount - 1,
            ),
          ),
        );
      };
    }, const []);

    return PopScope(
      canPop: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        color: isLast ? AppColors.primaryDeep : AppColors.surfacePrimaryLight,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                if (h <= 0) {
                  return const SizedBox.shrink();
                }
                final topInset = h * 0.1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: topInset),
                    Expanded(
                      child: PageView(
                        controller: pageController,
                        physics: onGameDemoPage
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        onPageChanged: (i) {
                          final from = page.value;
                          final ms = DateTime.now()
                              .difference(pageEnteredAt.value)
                              .inMilliseconds;
                          if (ms >= 0) {
                            unawaited(
                              Analytics.track(
                                ref,
                                OnboardingStepDurationEvent(
                                  step: _onboardingStepIdForIndex(
                                    from,
                                    demoGameRef.value,
                                  ),
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
                          _ScoreStoryPage(
                            onFirstRevealCardSwipe: () {
                              unawaited(
                                Analytics.track(
                                  ref,
                                  const OnboardingRevealTrialSwipedEvent(),
                                ),
                              );
                            },
                          ),
                          if (demoGame == onboardingGameFactOrBluff)
                            OnboardingFactOrBluffPage(
                              onSkip: () {
                                ScreenFlow.logAction(
                                  ref,
                                  screenName: ScreenFlow.onboarding,
                                  actionId: 'fact_or_bluff_demo_skipped',
                                );
                                goToLoopPage();
                              },
                              onContinue: () {
                                ScreenFlow.logAction(
                                  ref,
                                  screenName: ScreenFlow.onboarding,
                                  actionId: 'fact_or_bluff_demo_completed',
                                );
                                goToLoopPage();
                              },
                            )
                          else
                            OnboardingMemoryPairsPage(
                              onSkip: () {
                                ScreenFlow.logAction(
                                  ref,
                                  screenName: ScreenFlow.onboarding,
                                  actionId: 'memory_pairs_demo_skipped',
                                );
                                goToLoopPage();
                              },
                              onContinue: () {
                                ScreenFlow.logAction(
                                  ref,
                                  screenName: ScreenFlow.onboarding,
                                  actionId: 'memory_pairs_demo_completed',
                                );
                                goToLoopPage();
                              },
                            ),
                          const _LoopPage(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        vPadSm,
                        hPad,
                        bottom + _onb(context, 4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DotRow(
                            index: page.value,
                            count: _pageCount,
                            dark: isLast,
                          ),
                          if (isLast) ...[
                            SizedBox(height: _onb(context, 10)),
                            FilledButton(
                              onPressed: () {
                                ScreenFlow.logAction(
                                  ref,
                                  screenName: ScreenFlow.onboarding,
                                  actionId: 'get_started',
                                );
                                unawaited(
                                  _complete(
                                    ref,
                                    context,
                                    markFlowCompleted: () {
                                      onboardingFlowCompleted.value = true;
                                    },
                                    demoGame: demoGameRef.value,
                                    lastStepIndex: page.value,
                                    lastStepStartedAt: pageEnteredAt.value,
                                    onboardingFlowStartedAt:
                                        onboardingFlowStartedAt.value,
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  vertical: _onb(context, 15),
                                ),
                                minimumSize: Size(
                                  double.infinity,
                                  _onb(context, 50),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Continue',
                                style: GoogleFonts.dmSans(
                                  fontSize: _onb(context, 16),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
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
  required String demoGame,
  required int lastStepIndex,
  required DateTime lastStepStartedAt,
  required DateTime onboardingFlowStartedAt,
}) async {
  markFlowCompleted();
  final ms = DateTime.now()
      .difference(lastStepStartedAt)
      .inMilliseconds;
  if (ms >= 0) {
    unawaited(
      Analytics.track(
        ref,
        OnboardingStepDurationEvent(
          step: _onboardingStepIdForIndex(lastStepIndex, demoGame),
          durationMs: ms,
        ),
      ),
    );
  }
  final totalMs = DateTime.now()
      .difference(onboardingFlowStartedAt)
      .inMilliseconds;
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

// ── Shared chrome ─────────────────────────────────────────────────────────

class _DotRow extends StatelessWidget {
  const _DotRow({required this.index, required this.count, required this.dark});

  final int index;
  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final dotH = _onb(context, 7);
    final dotOnW = _onb(context, 18);
    final dotOffW = _onb(context, 7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == index;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: _onb(context, 4)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: on ? dotOnW : dotOffW,
            height: dotH,
            decoration: BoxDecoration(
              color: on
                  ? AppColors.primary
                  : (dark
                        ? AppColors.onSurfaceDark.withValues(alpha: 0.25)
                        : AppColors.gray200),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }
}

TextStyle _eyebrow(BuildContext context, bool onDark) => GoogleFonts.dmSans(
  fontSize: _onb(context, 11),
  fontWeight: FontWeight.w700,
  letterSpacing: 1.6,
  color: onDark ? AppColors.correctTextDark : AppColors.primaryDark,
);

TextStyle _headline(BuildContext context, bool onDark) => GoogleFonts.dmSans(
  fontSize: _onb(context, 26),
  height: 1.15,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  color: onDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
);

TextStyle _body(BuildContext context, bool onDark) => GoogleFonts.dmSans(
  fontSize: _onb(context, 15),
  height: 1.5,
  fontWeight: FontWeight.w400,
  color: onDark
      ? AppColors.onSurfaceVariantDark
      : AppColors.onSurfaceVariantLight,
);

/// Scales [children] to the page viewport; no scroll. Avoid vertical
/// [Expanded] under this path (see [_hiddenSlide]).
Widget _onboardingFittedPage({
  required EdgeInsets padding,
  required List<Widget> children,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      var maxW = constraints.maxWidth;
      if (!maxW.isFinite || maxW <= 0) {
        maxW = MediaQuery.sizeOf(context).width;
      }
      return RepaintBoundary(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Split score card: drag the center arrow at most half the card width to reveal
/// the right “hidden risk” column (ends at 50 / 50).
class _DraggableSplitScoreCard extends StatefulWidget {
  const _DraggableSplitScoreCard({required this.splitDragLocksPage});

  /// When true, parent [PageView] uses [NeverScrollableScrollPhysics] so this
  /// handle’s horizontal drag is not stolen by the page scroller.
  final ValueNotifier<bool> splitDragLocksPage;

  @override
  State<_DraggableSplitScoreCard> createState() =>
      _DraggableSplitScoreCardState();
}

class _DraggableSplitScoreCardState extends State<_DraggableSplitScoreCard> {
  /// Left column width as a fraction of total width. In [0.5, 1.0]: 1 = right
  /// hidden; 0.5 = half left / half right.
  double _leftFraction = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final handleSize = _onb(context, 36);
        final cardH = _onb(context, 220);
        final leftFrac = _leftFraction.clamp(0.5, 1.0);
        final splitX = w * leftFrac;
        final rightW = math.max(0.0, w - splitX);
        final handleLeft = (splitX - handleSize / 2).clamp(0.0, w - handleSize);

        Widget leftColumn() {
          return ColoredBox(
            color: AppColors.surfacePrimaryDark,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _onb(context, 12),
                _onb(context, 10),
                _onb(context, 12),
                _onb(context, 10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR LATEST TEST',
                    style: GoogleFonts.dmSans(
                      fontSize: _onb(context, 9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.onSurfaceVariantDark,
                    ),
                  ),
                  SizedBox(height: _onb(context, 4)),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '82',
                          style: GoogleFonts.dmSans(
                            fontSize: _onb(context, 38),
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: AppColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: ' / 100',
                          style: GoogleFonts.dmSans(
                            fontSize: _onb(context, 14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariantDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _onb(context, 8)),
                  Row(
                    children: [
                      Text(
                        'Accuracy',
                        style: GoogleFonts.dmSans(
                          fontSize: _onb(context, 11),
                          color: AppColors.onSurfaceVariantDark,
                        ),
                      ),
                      SizedBox(width: _onb(context, 6)),
                      Text(
                        '82%',
                        style: GoogleFonts.dmSans(
                          fontSize: _onb(context, 13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.correctTextDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _onb(context, 6)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rank',
                        style: GoogleFonts.dmSans(
                          fontSize: _onb(context, 11),
                          color: AppColors.onSurfaceVariantDark,
                        ),
                      ),
                      SizedBox(width: _onb(context, 6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _onb(context, 7),
                          vertical: _onb(context, 3),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_onb(context, 6)),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Text(
                          'High',
                          style: GoogleFonts.dmSans(
                            fontSize: _onb(context, 10),
                            fontWeight: FontWeight.w700,
                            color: AppColors.correctTextDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _onb(context, 8)),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _onb(context, 10),
                        vertical: _onb(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(_onb(context, 8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Strong attempt',
                            style: GoogleFonts.dmSans(
                              fontSize: _onb(context, 11),
                              fontWeight: FontWeight.w700,
                              color: AppColors.correctTextDark,
                            ),
                          ),
                          SizedBox(width: _onb(context, 4)),
                          Icon(
                            Icons.check_rounded,
                            size: _onb(context, 14),
                            color: AppColors.correctTextDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Widget rightColumn() {
          return ColoredBox(
            color: AppColors.wrongBgDark,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _onb(context, 14),
                _onb(context, 10),
                _onb(context, 12),
                _onb(context, 10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: _onb(context, 16),
                        color: AppColors.wrongTextDark,
                      ),
                      SizedBox(width: _onb(context, 6)),
                      Expanded(
                        child: Text(
                          'HIDDEN RISK DETECTED',
                          style: GoogleFonts.dmSans(
                            fontSize: _onb(context, 9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.wrongTextDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _onb(context, 6)),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '8',
                          style: GoogleFonts.dmSans(
                            fontSize: _onb(context, 40),
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: AppColors.wrongTextDark,
                          ),
                        ),
                        TextSpan(
                          text: ' confident mistakes',
                          style: GoogleFonts.dmSans(
                            fontSize: _onb(context, 13),
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: AppColors.onSurfaceDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: _onb(context, 6)),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.onSurfaceDark.withValues(alpha: 0.2),
                  ),
                  SizedBox(height: _onb(context, 6)),
                  Text(
                    'Real exam cost',
                    style: GoogleFonts.dmSans(
                      fontSize: _onb(context, 11),
                      color: AppColors.onSurfaceVariantDark,
                    ),
                  ),
                  SizedBox(height: _onb(context, 2)),
                  Text(
                    '−5.28 marks',
                    style: GoogleFonts.dmSans(
                      fontSize: _onb(context, 22),
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: AppColors.wrongTextDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SizedBox(
            height: cardH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: splitX, child: leftColumn()),
                    SizedBox(
                      width: rightW,
                      child: rightW > 0.5
                          ? rightColumn()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                Positioned(
                  left: splitX - 0.5,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 1,
                      color: AppColors.onSurfaceDark.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Positioned(
                  left: handleLeft,
                  top: 0,
                  bottom: 0,
                  width: handleSize,
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) {
                        widget.splitDragLocksPage.value = true;
                      },
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _leftFraction += details.delta.dx / w;
                          _leftFraction = _leftFraction.clamp(0.5, 1.0);
                        });
                      },
                      onHorizontalDragEnd: (_) {
                        widget.splitDragLocksPage.value = false;
                      },
                      onHorizontalDragCancel: () {
                        widget.splitDragLocksPage.value = false;
                      },
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (_) {
                          widget.splitDragLocksPage.value = true;
                        },
                        onPointerUp: (_) {
                          widget.splitDragLocksPage.value = false;
                        },
                        onPointerCancel: (_) {
                          widget.splitDragLocksPage.value = false;
                        },
                        child: Material(
                          elevation: 3,
                          color: AppColors.surfacePrimaryLight,
                          shape: const CircleBorder(),
                          child: Padding(
                            padding: EdgeInsets.all(_onb(context, 7)),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: _onb(context, 20),
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// First step: split “latest test vs hidden risk” story (reference layout).
class _ScoreStoryPage extends StatefulWidget {
  const _ScoreStoryPage({this.onFirstRevealCardSwipe});

  final VoidCallback? onFirstRevealCardSwipe;

  @override
  State<_ScoreStoryPage> createState() => _ScoreStoryPageState();
}

class _ScoreStoryPageState extends State<_ScoreStoryPage> {
  late final PageController _revealScroll = PageController();

  @override
  void dispose() {
    _revealScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _onboardingFittedPage(
      padding: EdgeInsets.fromLTRB(
        _onb(context, 22),
        _onb(context, 8),
        _onb(context, 22),
        _onb(context, 4),
      ),
      children: [
        SizedBox(height: _onb(context, 6)),
        Text.rich(
          TextSpan(
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 24),
              height: 1.18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppColors.onSurfaceLight,
            ),
            children: [
              const TextSpan(text: 'You may be losing marks because of '),
              TextSpan(
                text: 'confident mistakes.',
                style: GoogleFonts.dmSans(
                  fontSize: _onb(context, 24),
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _onb(context, 10)),
        _RevealTrialCard(
          pageController: _revealScroll,
          onFirstVerticalReveal: widget.onFirstRevealCardSwipe,
        ),
        SizedBox(height: _onb(context, 10)),
        Text(
          'DISCOVER INSIGHTS LIKE',
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 11),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: _onb(context, 6)),
        _DiscoverChevronTile(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.summaryOrange,
          text:
              'Find topics and subjects where your \'confident\' or \'educated guess\' answers are usually wrong',
        ),
        SizedBox(height: _onb(context, 6)),
        _DiscoverChevronTile(
          icon: Icons.trending_down_rounded,
          iconColor: AppColors.wrong,
          text: 'Find topics where  your educated guesses are most accurate',
        ),
        SizedBox(height: _onb(context, 6)),
        _DiscoverChevronTile(
          icon: Icons.lightbulb_outline_rounded,
          iconColor: AppColors.primary,
          text: 'Trap types where you have most tendency of falling.',
        ),
      ],
    );
  }
}

/// Trial: vertical [PageView] (typical stats vs UPSC Wars); pager dots sit
/// on top of the slides (semi-transparent pill, trailing side).
class _RevealTrialCard extends StatefulWidget {
  const _RevealTrialCard({
    required this.pageController,
    this.onFirstVerticalReveal,
  });

  final PageController pageController;
  final VoidCallback? onFirstVerticalReveal;

  @override
  State<_RevealTrialCard> createState() => _RevealTrialCardState();
}

class _RevealTrialCardState extends State<_RevealTrialCard> {
  /// Card viewport height (matches design ~220 at baseline scale).
  double _cardHeight(BuildContext context) => _onb(context, 220);

  /// Scroll offset for peek: almost 50% of the next slide visible; kept a
  /// hair under half the viewport so [PageView] does not snap to page 1.
  double _peekScrollOffset(BuildContext context) =>
      _cardHeight(context) * 0.5 - 1;

  PageController get _pageController => widget.pageController;

  int _pageIndex = 0;
  bool _firedFirstRevealAnalytics = false;

  Future<void> _playSwipeUpHint() async {
    if (!mounted || _pageIndex != 0) return;
    for (var w = 0; w < 12 && mounted && !_pageController.hasClients; w++) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted || !_pageController.hasClients || _pageIndex != 0) return;
    final ph = _cardHeight(context);
    final target = _peekScrollOffset(context).clamp(0.0, ph * 0.499);
    for (var n = 0; n < 2; n++) {
      if (!mounted || _pageIndex != 0 || !_pageController.hasClients) return;
      try {
        await _pageController.animateTo(
          target,
          duration: const Duration(milliseconds: 720),
          curve: Curves.easeInOutCubic,
        );
      } catch (_) {
        return;
      }
      if (!mounted || _pageIndex != 0 || !_pageController.hasClients) return;
      try {
        await _pageController.animateTo(
          0,
          duration: const Duration(milliseconds: 680),
          curve: Curves.easeInOutCubic,
        );
      } catch (_) {
        return;
      }
      if (n == 0 && mounted && _pageIndex == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 850), () {
        if (mounted && _pageIndex == 0) unawaited(_playSwipeUpHint());
      });
    });
  }

  TextStyle _leakMeta(BuildContext context) {
    return GoogleFonts.dmSans(
      fontSize: _onb(context, 12),
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceDark.withValues(alpha: 0.88),
    );
  }

  Widget _surfaceSlide(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryDeep,
            Color.lerp(AppColors.primaryDeep, AppColors.primary, 0.22)!,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _onb(context, 3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 1,
            child: ColoredBox(
              color: AppColors.correctTextDark.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _onb(context, 16),
              _onb(context, 12),
              _onb(context, 14),
              _onb(context, 12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Typical test series stats:',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 13),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0.1,
                    color: AppColors.correctTextDark.withValues(alpha: 0.92),
                  ),
                ),
                SizedBox(height: _onb(context, 8)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '70',
                            style: GoogleFonts.dmSans(
                              fontSize: _onb(context, 36),
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -1,
                              color: AppColors.correctTextDark,
                            ),
                          ),
                          TextSpan(
                            text: ' / 100',
                            style: GoogleFonts.dmSans(
                              fontSize: _onb(context, 15),
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                              color: AppColors.onSurfaceDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: _onb(context, 40)),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.4),
                              AppColors.primary.withValues(alpha: 0.18),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(_onb(context, 9)),
                          border: Border.all(
                            color: AppColors.correctTextDark.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _onb(context, 10),
                            vertical: _onb(context, 7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: _onb(context, 15),
                                color: AppColors.correctTextDark,
                              ),
                              SizedBox(width: _onb(context, 5)),
                              Text(
                                'Strong attempt',
                                style: GoogleFonts.dmSans(
                                  fontSize: _onb(context, 11),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: AppColors.correctTextDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _onb(context, 8)),
                Text(
                  'Swipe up for how UPSC Wars reads the same attempt.',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 12),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceDark.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hiddenSlide(BuildContext context) {
    final leakMeta = _leakMeta(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.wrongBgDark,
            Color.lerp(AppColors.wrongBgDark, AppColors.gray900, 0.42)!,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _onb(context, 14),
          _onb(context, 10),
          _onb(context, 14),
          _onb(context, 10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UPSC Wars advantage:',
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 13),
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: 0.1,
                color: AppColors.wrongTextDark.withValues(alpha: 0.92),
              ),
            ),
            SizedBox(height: _onb(context, 8)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.gpp_bad_rounded,
                  size: _onb(context, 22),
                  color: AppColors.wrongTextDark,
                ),
                SizedBox(width: _onb(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '8 high-confidence misses',
                        style: GoogleFonts.dmSans(
                          fontSize: _onb(context, 15),
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppColors.wrongTextDark,
                        ),
                      ),
                      SizedBox(height: _onb(context, 4)),
                      Text(
                        'Answers you were sure about — wrong anyway.',
                        style: leakMeta,
                      ),
                      SizedBox(height: _onb(context, 2)),
                      Text(
                        '≈ −5.28 marks after negative marking',
                        style: GoogleFonts.dmSans(
                          fontSize: _onb(context, 11),
                          fontWeight: FontWeight.w700,
                          color: AppColors.wrongTextDark.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: _onb(context, 8)),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.onSurfaceDark.withValues(alpha: 0.14),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.psychology_alt_rounded,
                  size: _onb(context, 22),
                  color: AppColors.summaryOrange,
                ),
                SizedBox(width: _onb(context, 10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5 educated guesses — wrong',
                        style: GoogleFonts.dmSans(
                          fontSize: _onb(context, 15),
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: AppColors.summaryOrange,
                        ),
                      ),
                      SizedBox(height: _onb(context, 4)),
                      Text(
                        'Smart elimination still burns the same penalty.',
                        style: leakMeta,
                      ),
                      SizedBox(height: _onb(context, 2)),
                      Text(
                        'Same marking hit, different story',
                        style: GoogleFonts.dmSans(
                          fontSize: _onb(context, 11),
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariantDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Vertical pager dots drawn on top of the slides (not in a side gutter).
  Widget _overlayVerticalDots(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (i) {
        final active = i == _pageIndex;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: _onb(context, 4)),
          child: GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _onb(context, 6),
              height: active ? _onb(context, 20) : _onb(context, 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_onb(context, 3)),
                color: active
                    ? AppColors.surfacePrimaryLight.withValues(alpha: 0.95)
                    : AppColors.surfacePrimaryLight.withValues(alpha: 0.48),
                border: Border.all(
                  color: active
                      ? AppColors.surfacePrimaryLight.withValues(alpha: 0.75)
                      : AppColors.surfacePrimaryLight.withValues(alpha: 0.62),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageH = _cardHeight(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: pageH,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView(
                  scrollDirection: Axis.vertical,
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) {
                    if (i == 1 &&
                        _pageIndex == 0 &&
                        !_firedFirstRevealAnalytics) {
                      _firedFirstRevealAnalytics = true;
                      widget.onFirstVerticalReveal?.call();
                    }
                    setState(() => _pageIndex = i);
                  },
                  children: [_surfaceSlide(context), _hiddenSlide(context)],
                ),
                Positioned(
                  right: _onb(context, 10),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfacePrimaryLight.withValues(
                          alpha: 0.38,
                        ),
                        borderRadius: BorderRadius.circular(_onb(context, 12)),
                        border: Border.all(
                          color: AppColors.gray200.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gray900.withValues(alpha: 0.06),
                            blurRadius: _onb(context, 8),
                            offset: Offset(0, _onb(context, 1)),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _onb(context, 7),
                          vertical: _onb(context, 10),
                        ),
                        child: _overlayVerticalDots(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverChevronTile extends StatelessWidget {
  const _DiscoverChevronTile({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _onb(context, 12),
        vertical: _onb(context, 12),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: _onb(context, 22), color: iconColor),
          SizedBox(width: _onb(context, 10)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 14),
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceLight,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.gray400,
            size: _onb(context, 22),
          ),
        ],
      ),
    );
  }
}

// ── Page 2 ────────────────────────────────────────────────────────────────

class _LoopPage extends StatelessWidget {
  const _LoopPage();

  @override
  Widget build(BuildContext context) {
    return _onboardingFittedPage(
      padding: EdgeInsets.fromLTRB(
        _onb(context, 22),
        _onb(context, 4),
        _onb(context, 22),
        _onb(context, 0),
      ),
      children: [
        Text('DAILY COMPETITIVE LOOP', style: _eyebrow(context, true)),
        SizedBox(height: _onb(context, 6)),
        Text('Consistency clears prelims.', style: _headline(context, true)),
        SizedBox(height: _onb(context, 4)),
        Text(
          'Short, focused reps — history, progress, and community — so preparation feels structured, not random.',
          style: _body(context, true),
        ),
        SizedBox(height: _onb(context, 8)),
        _LoopMiniCard(
          color: AppColors.correctBgDark,
          border: AppColors.primary.withValues(alpha: 0.45),
          icon: Icons.topic_outlined,
          iconColor: AppColors.correctTextDark,
          title: 'Topic-wise mastery',
          subtitle: 'Drills tied to the syllabus, not loose MCQs.',
        ),
        SizedBox(height: _onb(context, 4)),
        _LoopMiniCard(
          color: AppColors.warningBgDark,
          border: AppColors.warning.withValues(alpha: 0.4),
          icon: Icons.history_rounded,
          iconColor: AppColors.warningTextDark,
          title: 'Session history',
          subtitle: 'See what you attempted and where it hurt.',
        ),
        SizedBox(height: _onb(context, 4)),
        _LoopMiniCard(
          color: AppColors.infoBgDark,
          border: AppColors.info.withValues(alpha: 0.45),
          icon: Icons.groups_outlined,
          iconColor: AppColors.infoTextDark,
          title: '1 on 1 MCQ battles & community',
          subtitle: 'Engage with other aspirants and feel the competition',
        ),
        SizedBox(height: _onb(context, 4)),
        _LoopMiniCard(
          color: AppColors.wrongBgDark.withValues(alpha: 0.65),
          border: AppColors.wrong.withValues(alpha: 0.35),
          icon: Icons.flag_outlined,
          iconColor: AppColors.wrongTextDark,
          title: 'Prelims countdown',
          subtitle: 'Daily loop tuned to the calendar, not vibes.',
        ),
        SizedBox(height: _onb(context, 6)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: AppColors.primary,
              size: _onb(context, 22),
            ),
            SizedBox(width: _onb(context, 8)),
            Expanded(
              child: Text(
                'Preparation should feel like progress, not randomness.',
                style: GoogleFonts.dmSans(
                  fontSize: _onb(context, 14),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoopMiniCard extends StatelessWidget {
  const _LoopMiniCard({
    required this.color,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_onb(context, 14)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: _onb(context, 40),
            height: _onb(context, 40),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimaryDark.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(_onb(context, 10)),
            ),
            child: Icon(icon, color: iconColor, size: _onb(context, 22)),
          ),
          SizedBox(width: _onb(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 14),
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceDark,
                  ),
                ),
                SizedBox(height: _onb(context, 2)),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 12),
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariantDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
