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
    final splitDragLocksPage = useMemoized(
      () => ValueNotifier(false),
      const [],
    );
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isLast = page.value == _pageCount - 1;

    useEffect(() {
      return () {
        firstScreenCtaReady.dispose();
        splitDragLocksPage.dispose();
      };
    }, [firstScreenCtaReady, splitDragLocksPage]);

    void goNext() {
      if (!isLast) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _complete(ref, context);
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isLast
            ? AppColors.primaryDeep
            : AppColors.surfacePrimaryLight,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _ProgressSegments(
                  index: page.value,
                  count: _pageCount,
                  dark: isLast,
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: splitDragLocksPage,
                  builder: (context, locksPage, _) {
                    return PageView(
                      controller: pageController,
                      physics: locksPage && page.value == 0
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      onPageChanged: (i) {
                        page.value = i;
                        if (i != 0) {
                          firstScreenCtaReady.value = false;
                          splitDragLocksPage.value = false;
                        }
                      },
                      children: [
                        _ScoreStoryPage(
                          firstScreenCtaReady: firstScreenCtaReady,
                          splitDragLocksPage: splitDragLocksPage,
                        ),
                        const _MechanismPage(),
                        const _DiagnosisPage(),
                        const _LoopPage(),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: _DotRow(
                  index: page.value,
                  count: _pageCount,
                  dark: isLast,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 12 + bottom),
                child: ValueListenableBuilder<bool>(
                  valueListenable: firstScreenCtaReady,
                  builder: (context, firstReady, _) {
                    final pageIndex = page.value;
                    final onFirst = pageIndex == 0;
                    final blocked = onFirst && !firstReady;
                    return FilledButton(
                      onPressed: blocked ? null : goNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: isLast
                            ? AppColors.primary
                            : AppColors.gray900,
                        foregroundColor: isLast
                            ? AppColors.onPrimary
                            : AppColors.surfacePrimaryLight,
                        disabledBackgroundColor: AppColors.gray900.withValues(
                          alpha: 0.4,
                        ),
                        disabledForegroundColor: AppColors.surfacePrimaryLight
                            .withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Opacity(
                        opacity: blocked ? 0.5 : 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              switch (pageIndex) {
                                0 => 'Tell Me More',
                                1 => 'Show Me My Blind Spots',
                                2 => 'Start My Analysis Test',
                                _ => 'Start My First Diagnostic Test',
                              },
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (pageIndex == 0) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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

class _ProgressSegments extends StatelessWidget {
  const _ProgressSegments({
    required this.index,
    required this.count,
    required this.dark,
  });

  final int index;
  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final inactive = dark
        ? AppColors.onSurfaceDark.withValues(alpha: 0.2)
        : AppColors.borderLight;
    final active = AppColors.primary;
    return Row(
      children: List.generate(count, (i) {
        final filled = i <= index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4,
              decoration: BoxDecoration(
                color: filled ? active : inactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DotRow extends StatelessWidget {
  const _DotRow({required this.index, required this.count, required this.dark});

  final int index;
  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: on ? 18 : 7,
            height: 7,
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

TextStyle _eyebrow(bool onDark) => GoogleFonts.dmSans(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.6,
  color: onDark ? AppColors.correctTextDark : AppColors.primaryDark,
);

TextStyle _headline(bool onDark) => GoogleFonts.dmSans(
  fontSize: 26,
  height: 1.15,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  color: onDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
);

TextStyle _body(bool onDark) => GoogleFonts.dmSans(
  fontSize: 15,
  height: 1.5,
  fontWeight: FontWeight.w400,
  color: onDark
      ? AppColors.onSurfaceVariantDark
      : AppColors.onSurfaceVariantLight,
);

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

  static const double _handleSize = 36;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final leftFrac = _leftFraction.clamp(0.5, 1.0);
        final splitX = w * leftFrac;
        final rightW = math.max(0.0, w - splitX);
        final handleLeft = (splitX - _handleSize / 2).clamp(
          0.0,
          w - _handleSize,
        );

        Widget leftColumn() {
          return ColoredBox(
            color: AppColors.surfacePrimaryDark,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR LATEST TEST',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.onSurfaceVariantDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '82',
                          style: GoogleFonts.dmSans(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: AppColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: ' / 100',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariantDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Accuracy',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariantDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '82%',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.correctTextDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Rank',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariantDark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Text(
                          'High',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.correctTextDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Strong attempt',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.correctTextDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_rounded,
                            size: 14,
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
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.wrongTextDark,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'HIDDEN RISK DETECTED',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.wrongTextDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '8',
                          style: GoogleFonts.dmSans(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: AppColors.wrongTextDark,
                          ),
                        ),
                        TextSpan(
                          text: ' confident mistakes',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: AppColors.onSurfaceDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.onSurfaceDark.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real exam cost',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariantDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '−5.28 marks',
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
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
            height: 220,
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
                  width: _handleSize,
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
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
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
class _ScoreStoryPage extends StatelessWidget {
  const _ScoreStoryPage({
    required this.firstScreenCtaReady,
    required this.splitDragLocksPage,
  });

  final ValueNotifier<bool> firstScreenCtaReady;
  final ValueNotifier<bool> splitDragLocksPage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/app_icon.png',
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPSC WARS',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PREPARE. DIAGNOSE. CONQUER.',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Divider(),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: GoogleFonts.dmSans(
                fontSize: 24,
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
                    fontSize: 24,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _RevealTrialCard(firstScreenCtaReady: firstScreenCtaReady),
          const SizedBox(height: 20),
          // _DraggableSplitScoreCard(splitDragLocksPage: splitDragLocksPage),
          const SizedBox(height: 16),
          Text(
            'DISCOVER INSIGHTS LIKE',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          _DiscoverChevronTile(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.summaryOrange,
            text:
                'Find topics and subjects where your \'confident\' or \'intelligent guess\' answers are usually wrong — the danger zone.',
          ),
          const SizedBox(height: 8),
          _DiscoverChevronTile(
            icon: Icons.trending_down_rounded,
            iconColor: AppColors.wrong,
            text: 'Hidden mark leaks that test scores hide.',
          ),
          const SizedBox(height: 8),
          _DiscoverChevronTile(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: AppColors.primary,
            text: 'Trap patterns UPSC uses again and again.',
          ),
        ],
      ),
    );
  }
}

/// Trial: vertical [PageView] (typical stats vs UPSC Wars); pager dots sit
/// on top of the slides (semi-transparent pill, trailing side).
class _RevealTrialCard extends StatefulWidget {
  const _RevealTrialCard({required this.firstScreenCtaReady});

  final ValueNotifier<bool> firstScreenCtaReady;

  @override
  State<_RevealTrialCard> createState() => _RevealTrialCardState();
}

class _RevealTrialCardState extends State<_RevealTrialCard> {
  static const double _pageHeight = 220;

  /// Scroll offset for peek: almost 50% of the next slide visible; kept a
  /// hair under half the viewport so [PageView] does not snap to page 1.
  double get _peekScrollOffset => _pageHeight * 0.5 - 1;

  late final PageController _pageController = PageController();

  int _pageIndex = 0;
  bool _ctaGateScheduled = false;

  void _scheduleCtaAfterHiddenSeen() {
    if (_ctaGateScheduled || !mounted) return;
    _ctaGateScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      widget.firstScreenCtaReady.value = true;
    });
  }

  Future<void> _playSwipeUpHint() async {
    if (!mounted || _pageIndex != 0) return;
    for (var w = 0;
        w < 12 && mounted && !_pageController.hasClients;
        w++) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted || !_pageController.hasClients || _pageIndex != 0) return;
    final target = _peekScrollOffset.clamp(0.0, _pageHeight * 0.499);
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  TextStyle _leakMeta() {
    return GoogleFonts.dmSans(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: AppColors.onSurfaceDark.withValues(alpha: 0.88),
    );
  }

  Widget _surfaceSlide() {
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
            width: 3,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Typical test series stats:',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0.1,
                    color: AppColors.correctTextDark.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '80',
                            style: GoogleFonts.dmSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              letterSpacing: -1,
                              color: AppColors.correctTextDark,
                            ),
                          ),
                          TextSpan(
                            text: ' / 100',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
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
                      padding: const EdgeInsets.only(right: 40),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.4),
                              AppColors.primary.withValues(alpha: 0.18),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: AppColors.correctTextDark.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 15,
                                color: AppColors.correctTextDark,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Strong attempt',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
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
                const SizedBox(height: 8),
                Text(
                  'Swipe up for how UPSC Wars reads the same attempt.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
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

  Widget _hiddenSlide() {
    final leakMeta = _leakMeta();
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UPSC Wars advantage:',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: 0.1,
                color: AppColors.wrongTextDark.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.gpp_bad_rounded,
                        size: 22,
                        color: AppColors.wrongTextDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '8 high-confidence misses',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: AppColors.wrongTextDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Answers you were sure about — wrong anyway.',
                              style: leakMeta,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '≈ −5.28 marks after negative marking',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.wrongTextDark.withValues(
                                  alpha: 0.9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                        size: 22,
                        color: AppColors.summaryOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '5 educated guesses — wrong',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: AppColors.summaryOrange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Smart elimination still burns the same penalty.',
                              style: leakMeta,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Same marking hit, different story',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
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
          ],
        ),
      ),
    );
  }

  /// Vertical pager dots drawn on top of the slides (not in a side gutter).
  Widget _overlayVerticalDots() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (i) {
        final active = i == _pageIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              width: 6,
              height: active ? 20 : 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Two slides — swipe up on the card (or tap the dots)',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
            letterSpacing: 0.15,
            color: AppColors.onSurfaceVariantLight,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _pageHeight,
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
                    if (i == 1) _scheduleCtaAfterHiddenSeen();
                  },
                  children: [_surfaceSlide(), _hiddenSlide()],
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfacePrimaryLight.withValues(
                          alpha: 0.38,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gray200.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gray900.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 10,
                        ),
                        child: _overlayVerticalDots(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceLight,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.gray400, size: 22),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW IT WORKS', style: _eyebrow(false)),
          const SizedBox(height: 14),
          Text('We track what normal tests miss.', style: _headline(false)),
          const SizedBox(height: 8),
          Text(
            'That turns raw scores into something the exam actually punishes: confident errors.',
            style: _body(false),
          ),
          const SizedBox(height: 22),
          Text(
            'UPSC WARS IDENTIFIES:',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          _IdentifiesRow(
            icon: Icons.visibility_off_outlined,
            text: 'Blind spots',
          ),
          _IdentifiesRow(
            icon: Icons.psychology_outlined,
            text: 'Overconfidence patterns',
          ),
          _IdentifiesRow(
            icon: Icons.trending_down_rounded,
            text: 'Weak topics',
          ),
          _IdentifiesRow(
            icon: Icons.cancel_rounded,
            text: 'Negative marking traps',
          ),
          const SizedBox(height: 12),
          Text(
            'We show you where your prelims marks are actually being lost.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariantLight,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimaryLight,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.wrong, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _EqIcon(Icons.close_rounded, AppColors.wrong),
                    Text(
                      ' + ',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceLight,
                      ),
                    ),
                    _EqIcon(Icons.psychology_rounded, AppColors.wrong),
                    Text(
                      ' = ',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceLight,
                      ),
                    ),
                    _EqIcon(Icons.gps_fixed_rounded, AppColors.wrong),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Wrong answer + Sure (high confidence) = Danger zone',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.wrongText,
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

class _IdentifiesRow extends StatelessWidget {
  const _IdentifiesRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 15,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _EqIcon extends StatelessWidget {
  const _EqIcon(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.wrongBg.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

// ── Page 3 ────────────────────────────────────────────────────────────────

class _DiagnosisPage extends StatelessWidget {
  const _DiagnosisPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEEP DIAGNOSIS', style: _eyebrow(false)),
          const SizedBox(height: 14),
          Text(
            'Not just answers. Real exam intelligence.',
            style: _headline(false),
          ),
          const SizedBox(height: 14),
          Text(
            'Every question comes with:',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceLight,
            ),
          ),
          const SizedBox(height: 6),
          _FeatureLine(
            icon: Icons.hub_outlined,
            text: 'Strong distractor and trap-pattern summaries',
          ),
          Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          _FeatureLine(
            icon: Icons.analytics_outlined,
            text: 'Confidence-tier review after every session',
          ),
          Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          _FeatureLine(
            icon: Icons.adjust_outlined,
            text: 'Weak areas mapped to subtopics you keep missing',
          ),
          Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          _FeatureLine(
            icon: Icons.refresh_rounded,
            text: 'Revision queue that prioritises real risk',
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school_outlined,
                    color: AppColors.correctTextDark,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You don\'t just solve questions. You learn how UPSC traps aspirants.',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.45,
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
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 15,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DAILY COMPETITIVE LOOP', style: _eyebrow(true)),
          const SizedBox(height: 14),
          Text('Consistency clears prelims.', style: _headline(true)),
          const SizedBox(height: 10),
          Text(
            'Short, focused reps — history, progress, and community — so preparation feels structured, not random.',
            style: _body(true),
          ),
          const SizedBox(height: 22),
          _LoopMiniCard(
            color: AppColors.correctBgDark,
            border: AppColors.primary.withValues(alpha: 0.45),
            icon: Icons.topic_outlined,
            iconColor: AppColors.correctTextDark,
            title: 'Topic-wise mastery',
            subtitle: 'Drills tied to the syllabus, not loose MCQs.',
          ),
          const SizedBox(height: 10),
          _LoopMiniCard(
            color: AppColors.warningBgDark,
            border: AppColors.warning.withValues(alpha: 0.4),
            icon: Icons.history_rounded,
            iconColor: AppColors.warningTextDark,
            title: 'Session history',
            subtitle: 'See what you attempted and where it hurt.',
          ),
          const SizedBox(height: 10),
          _LoopMiniCard(
            color: AppColors.infoBgDark,
            border: AppColors.info.withValues(alpha: 0.45),
            icon: Icons.groups_outlined,
            iconColor: AppColors.infoTextDark,
            title: 'Battles & community',
            subtitle: 'Pressure that reveals gaps revision fixes.',
          ),
          const SizedBox(height: 10),
          _LoopMiniCard(
            color: AppColors.wrongBgDark.withValues(alpha: 0.65),
            border: AppColors.wrong.withValues(alpha: 0.35),
            icon: Icons.flag_outlined,
            iconColor: AppColors.wrongTextDark,
            title: 'Prelims countdown',
            subtitle: 'Daily loop tuned to the calendar, not vibes.',
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                color: AppColors.primary,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Preparation should feel like progress, not randomness.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfacePrimaryDark.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
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
