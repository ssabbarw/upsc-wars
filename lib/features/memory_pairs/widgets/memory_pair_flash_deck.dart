import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_models.dart';
import '../../../l10n/l10n.dart';

/// Stacked flashcards: tap to flip, swipe any direction for next (loops).
class MemoryPairFlashDeck extends HookWidget {
  const MemoryPairFlashDeck({
    super.key,
    required this.pairs,
    required this.lang,
    required this.accentColor,
    required this.onPlay,
  });

  final List<MemoryPair> pairs;
  final String lang;
  final Color accentColor;
  final VoidCallback onPlay;

  static const _swipeThreshold = 64.0;
  static const _tapSlop = 8.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final index = useState(0);
    final flipped = useState(false);
    final dragOffset = useState(Offset.zero);
    final dragging = useState(false);
    final exitingOffset = useState<Offset?>(null);
    final dragStart = useRef<Offset?>(null);

    final flipController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    useEffect(() {
      flipController.animateTo(flipped.value ? 1.0 : 0.0);
      return null;
    }, [flipped.value]);

    useEffect(() {
      flipped.value = false;
      flipController.value = 0;
      return null;
    }, [index.value]);

    if (pairs.isEmpty) return const SizedBox.shrink();

    final pair = pairs[index.value % pairs.length];
    final term = pair.termForLang(lang);
    final answer = pair.answerForLang(lang);
    final ghostCount = math.min(3, pairs.length);

    Future<void> advanceNext(Offset flickDirection) async {
      if (pairs.length <= 1) return;
      final mag = flickDirection.distance;
      final dir = mag > 0 ? flickDirection / mag : const Offset(-1, 0);
      exitingOffset.value = dir * 480;
      await Future<void>.delayed(const Duration(milliseconds: 240));
      if (!context.mounted) return;
      exitingOffset.value = null;
      dragOffset.value = Offset.zero;
      index.value = (index.value + 1) % pairs.length;
    }

    void onPointerDown(PointerDownEvent e) {
      if (exitingOffset.value != null) return;
      dragStart.value = e.position;
      dragging.value = true;
      dragOffset.value = Offset.zero;
    }

    void onPointerMove(PointerMoveEvent e) {
      if (!dragging.value ||
          exitingOffset.value != null ||
          dragStart.value == null) {
        return;
      }
      dragOffset.value = e.position - dragStart.value!;
    }

    void onPointerEnd() {
      if (!dragging.value || exitingOffset.value != null) return;
      dragging.value = false;
      dragStart.value = null;
      final delta = dragOffset.value;

      if (delta.dx.abs() >= _swipeThreshold ||
          delta.dy.abs() >= _swipeThreshold) {
        advanceNext(delta);
        return;
      }
      if (delta.distance < _tapSlop) {
        flipped.value = !flipped.value;
      }
      dragOffset.value = Offset.zero;
    }

    final liveOffset = exitingOffset.value ?? dragOffset.value;
    final liveRotation = exitingOffset.value != null
        ? exitingOffset.value!.dx * 0.00025
        : dragOffset.value.dx * 0.0005;
    final liveOpacity = exitingOffset.value != null ? 0.0 : 1.0;

    double faceFontSize(String text) {
      if (text.length > 16) return 22;
      if (text.length > 10) return 27;
      return 32;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          _ProgressDots(
            count: pairs.length,
            current: index.value,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardW = constraints.maxWidth * 0.82;
                final cardH = math.min(constraints.maxHeight * 0.62, 300.0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final n in [3, 2, 1])
                      if (n <= ghostCount)
                        AnimatedScale(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          scale: exitingOffset.value != null && n == 1
                              ? 1.0
                              : 1.0 - n * 0.05,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            offset: Offset(
                              0,
                              (exitingOffset.value != null && n == 1
                                      ? 0
                                      : n * 10.0) /
                                  cardH,
                            ),
                            child: _DeckGhostCard(
                              width: cardW,
                              height: cardH,
                              isDark: isDark,
                            ),
                          ),
                        ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        key: ValueKey(index.value),
                        width: cardW,
                        height: cardH,
                        child: Listener(
                          onPointerDown: onPointerDown,
                          onPointerMove: onPointerMove,
                          onPointerUp: (_) => onPointerEnd(),
                          onPointerCancel: (_) => onPointerEnd(),
                          child: AnimatedContainer(
                            duration: dragging.value
                                ? Duration.zero
                                : const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            child: Transform.translate(
                              offset: liveOffset,
                              child: Transform.rotate(
                                angle: liveRotation,
                                child: Opacity(
                                  opacity: liveOpacity,
                                  child: AnimatedBuilder(
                                    animation: flipController,
                                    builder: (context, _) {
                                      final angle =
                                          flipController.value * math.pi;
                                      final showBack =
                                          flipController.value >= 0.5;
                                      return Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateY(angle),
                                        child: showBack
                                            ? Transform(
                                                alignment: Alignment.center,
                                                transform: Matrix4.identity()
                                                  ..rotateY(math.pi),
                                                child: _CardFace(
                                                  label: context.l10n.btAnswer,
                                                  text: answer,
                                                  fontSize: faceFontSize(
                                                    answer,
                                                  ),
                                                  background: AppColors.primary,
                                                  foreground: Colors.white,
                                                  labelColor: Colors.white70,
                                                  isDark: isDark,
                                                ),
                                              )
                                            : _CardFace(
                                                label: context.l10n.mpTerm,
                                                text: term,
                                                fontSize: faceFontSize(term),
                                                background: scheme.surface,
                                                foreground: scheme.onSurface,
                                                labelColor:
                                                    scheme.onSurfaceVariant,
                                                isDark: isDark,
                                              ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            flipped.value ? context.l10n.mpTapTerm : context.l10n.mpTapFlip,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${index.value + 1} / ${pairs.length}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm().copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(context.l10n.mpPlay),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
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

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.count,
    required this.current,
    required this.isDark,
  });

  final int count;
  final int current;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.1)),
          ),
        );
      }),
    );
  }
}

class _DeckGhostCard extends StatelessWidget {
  const _DeckGhostCard({
    required this.width,
    required this.height,
    required this.isDark,
  });

  final double width;
  final double height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.label,
    required this.text,
    required this.fontSize,
    required this.background,
    required this.foreground,
    required this.labelColor,
    required this.isDark,
  });

  final String label;
  final String text;
  final double fontSize;
  final Color background;
  final Color foreground;
  final Color labelColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: background == AppColors.primary
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: AppSpacing.md,
            left: 0,
            right: 0,
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.caption().copyWith(
                color: labelColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.h2().copyWith(
                  fontSize: fontSize,
                  color: foreground,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
