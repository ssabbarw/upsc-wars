import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Scale vs ~390dp shortest side (phone-first baseline); clamped for large/small devices.
double _onbScale(BuildContext context) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  return (shortest / 390).clamp(0.78, 1.22);
}

double _onb(BuildContext context, double designPx) =>
    designPx * _onbScale(context);

/// Four-step first-run onboarding (score story → mechanism → diagnosis → loop).
class OnboardingFlowScreen extends HookConsumerWidget {
  const OnboardingFlowScreen({super.key});

  static const int _pageCount = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final page = useState(0);
    final firstScreenCtaReady = useMemoized(
      () => ValueNotifier(false),
      const [],
    );
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLast = page.value == _pageCount - 1;
    final hPad = _onb(context, 20);
    final vPadSm = _onb(context, 8);

    useEffect(() {
      return () {
        firstScreenCtaReady.dispose();
      };
    }, [firstScreenCtaReady]);

    void goNext() {
      if (!isLast) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        unawaited(_complete(ref, context));
      }
    }

    // final screenBackground = isLast
    //     ? AppColors.primaryDeep
    //     : AppColors.correctTextDark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        // backgroundColor: screenBackground,
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
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) {
                        page.value = i;
                        if (i != 0) {
                          firstScreenCtaReady.value = false;
                        }
                      },
                      children: [
                        _ScoreStoryPage(
                          firstScreenCtaReady: firstScreenCtaReady,
                        ),
                        const _MechanismPage(),
                        const _DiagnosisPage(),
                        const _LoopPage(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      vPadSm,
                      hPad,
                      _onb(context, 4),
                    ),
                    child: _DotRow(
                      index: page.value,
                      count: _pageCount,
                      dark: isLast,
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

Future<void> _complete(WidgetRef ref, BuildContext context) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.patternInterruptOnboardingSeen = true;
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
  const _ScoreStoryPage({required this.firstScreenCtaReady});

  final ValueNotifier<bool> firstScreenCtaReady;

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
          firstScreenCtaReady: widget.firstScreenCtaReady,
          pageController: _revealScroll,
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
              'Find topics and subjects where your \'confident\' or \'intelligent guess\' answers are usually wrong',
        ),
        SizedBox(height: _onb(context, 6)),
        _DiscoverChevronTile(
          icon: Icons.trending_down_rounded,
          iconColor: AppColors.wrong,
          text: 'Find topics where  your intelligent guesses are most accurate',
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
    required this.firstScreenCtaReady,
    required this.pageController,
  });

  final ValueNotifier<bool> firstScreenCtaReady;
  final PageController pageController;

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

  void _enableFirstScreenCta() {
    if (!mounted) return;
    if (widget.firstScreenCtaReady.value) return;
    widget.firstScreenCtaReady.value = true;
  }

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
    if (mounted) {
      _enableFirstScreenCta();
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
                    setState(() => _pageIndex = i);
                    if (i == 1) {
                      _enableFirstScreenCta();
                    }
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

class _MechanismPage extends StatelessWidget {
  const _MechanismPage();

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
        Text('HOW IT WORKS', style: _eyebrow(context, false)),
        SizedBox(height: _onb(context, 8)),
        Text(
          'We track what normal tests miss.',
          style: _headline(context, false),
        ),
        SizedBox(height: _onb(context, 6)),

        Text(
          'UPSC WARS IDENTIFIES:',
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 12),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: _onb(context, 8)),
        const _IdentifiesRow(
          icon: Icons.visibility_off_outlined,
          text: 'Blind spots',
        ),
        const _IdentifiesRow(
          icon: Icons.psychology_outlined,
          text: 'Overconfidence patterns',
        ),
        const _IdentifiesRow(
          icon: Icons.trending_down_rounded,
          text: 'Weak topics',
        ),
        const _IdentifiesRow(
          icon: Icons.cancel_rounded,
          text: 'Negative marking traps',
        ),
        SizedBox(height: _onb(context, 8)),
        Text(
          'We show you where your prelims marks are actually being lost.',
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 14),
            height: 1.4,
            fontWeight: FontWeight.w400,
            color: AppColors.onSurfaceVariantLight,
          ),
        ),
        SizedBox(height: _onb(context, 10)),
        Wrap(
          spacing: _onb(context, 6),
          runSpacing: _onb(context, 6),
          children: [
            _ConfidenceChip(
              label: 'Sure',
              bg: AppColors.primaryDark,
              fg: AppColors.onPrimary,
              border: AppColors.primaryDeep,
            ),
            _ConfidenceChip(
              label: 'Intelligent guess',
              bg: AppColors.warningBg,
              fg: AppColors.warningText,
              border: AppColors.warning.withValues(alpha: 0.4),
            ),
            _ConfidenceChip(
              label: 'Pure guess',
              bg: AppColors.infoBg,
              fg: AppColors.infoText,
              border: AppColors.info.withValues(alpha: 0.35),
            ),
          ],
        ),
        SizedBox(height: _onb(context, 10)),
        const _MechanismDangerCallout(),
      ],
    );
  }
}

/// Rich callout: when a wrong pick meets high confidence, it becomes the
/// highest-priority “danger” pattern — not a flat A+B=C equation.
class _MechanismDangerCallout extends StatelessWidget {
  const _MechanismDangerCallout();

  @override
  Widget build(BuildContext context) {
    double o(double x) => _onb(context, x);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(o(14), o(14), o(14), o(16)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(o(6) + AppRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.wrongBg,
            Color.lerp(AppColors.wrongBg, AppColors.wrong, 0.07)!,
          ],
        ),
        border: Border.all(color: AppColors.wrong.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.wrong.withValues(alpha: 0.12),
            blurRadius: o(10),
            offset: Offset(0, o(4)),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.wrong.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Padding(
                  padding: EdgeInsets.all(o(6)),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: o(20),
                    color: AppColors.wrong,
                  ),
                ),
              ),
              SizedBox(width: o(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The pattern that costs you the most',
                      style: GoogleFonts.dmSans(
                        fontSize: o(13.5),
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        letterSpacing: 0.15,
                        color: AppColors.wrongText,
                      ),
                    ),
                    SizedBox(height: o(4)),
                    Text(
                      'When you miss a question but you were “sure” — that’s a danger signal, not just a wrong tick.',
                      style: GoogleFonts.dmSans(
                        fontSize: o(12),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariantLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: o(14)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _MechanismFactorPill(
                  icon: Icons.cancel_outlined,
                  label: 'Wrong',
                  line2: 'answer',
                  emphasis: true,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(o(4), 0, o(4), o(8)),
                child: Text(
                  '+',
                  style: GoogleFonts.dmSans(
                    fontSize: o(18),
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray600,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: _MechanismFactorPill(
                  icon: Icons.verified_user_outlined,
                  label: '“Sure”',
                  line2: 'confidence',
                  emphasis: false,
                ),
              ),
            ],
          ),
          SizedBox(height: o(8)),
          Center(
            child: Icon(
              Icons.arrow_downward_rounded,
              size: o(18),
              color: AppColors.wrong.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: o(8)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: o(12), vertical: o(11)),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimaryLight.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(o(6) + AppRadius.md),
              border: Border.all(
                color: AppColors.wrong.withValues(alpha: 0.4),
                width: o(1.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: o(20),
                  color: AppColors.wrong,
                ),
                SizedBox(width: o(8)),
                Flexible(
                  child: Text(
                    'Danger zone — the leak prelims tests hide',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: o(13.5),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: 0.1,
                      color: AppColors.wrongText,
                    ),
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

class _MechanismFactorPill extends StatelessWidget {
  const _MechanismFactorPill({
    required this.icon,
    required this.label,
    required this.line2,
    required this.emphasis,
  });

  final IconData icon;
  final String label;
  final String line2;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    double o(double x) => _onb(context, x);
    final border = emphasis
        ? AppColors.wrong.withValues(alpha: 0.45)
        : AppColors.gray200.withValues(alpha: 0.8);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfacePrimaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg + 2),
        border: Border.all(color: border, width: o(1.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: o(10), vertical: o(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: o(20),
              color: emphasis ? AppColors.wrong : AppColors.primaryDark,
            ),
            SizedBox(width: o(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: o(13.5),
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: AppColors.onSurfaceLight,
                    ),
                  ),
                  Text(
                    line2,
                    style: GoogleFonts.dmSans(
                      fontSize: o(11),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppColors.onSurfaceVariantLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentifiesRow extends StatelessWidget {
  const _IdentifiesRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _onb(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: _onb(context, 24), color: AppColors.primaryDark),
          SizedBox(width: _onb(context, 12)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 15),
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _onb(context, 12),
        vertical: _onb(context, 8),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: _onb(context, 13),
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Page 3 ────────────────────────────────────────────────────────────────

class _DiagnosisPage extends StatelessWidget {
  const _DiagnosisPage();

  @override
  Widget build(BuildContext context) {
    return _onboardingFittedPage(
      padding: EdgeInsets.fromLTRB(
        _onb(context, 22),
        _onb(context, 6),
        _onb(context, 22),
        _onb(context, 2),
      ),
      children: [
        Text('DEEP DIAGNOSIS', style: _eyebrow(context, false)),
        SizedBox(height: _onb(context, 8)),
        Text(
          'Not just answers. Real exam intelligence.',
          style: _headline(context, false),
        ),
        SizedBox(height: _onb(context, 6)),
        Text(
          'Every question comes with:',
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 15),
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceLight,
          ),
        ),
        SizedBox(height: _onb(context, 4)),
        const _FeatureLine(
          icon: Icons.hub_outlined,
          text: 'Strong distractor and trap-pattern summaries',
        ),
        Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
        const _FeatureLine(
          icon: Icons.analytics_outlined,
          text: 'Confidence-tier review after every session',
        ),
        Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
        const _FeatureLine(
          icon: Icons.adjust_outlined,
          text: 'Weak areas mapped to subtopics you keep missing',
        ),
        Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
        const _FeatureLine(
          icon: Icons.refresh_rounded,
          text: 'Revision queue that prioritises real risk',
        ),
        SizedBox(height: _onb(context, 6)),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: EdgeInsets.all(_onb(context, 10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.school_outlined,
                  color: AppColors.correctTextDark,
                  size: _onb(context, 24),
                ),
                SizedBox(width: _onb(context, 10)),
                Expanded(
                  child: Text(
                    'You don\'t just solve questions. You learn how UPSC traps aspirants.',
                    style: GoogleFonts.dmSans(
                      fontSize: _onb(context, 15),
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceDark,
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

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _onb(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: _onb(context, 22), color: AppColors.primary),
          SizedBox(width: _onb(context, 12)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 15),
                height: 1.45,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 4 ────────────────────────────────────────────────────────────────

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
