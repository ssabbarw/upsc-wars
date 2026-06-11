import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../memory_pairs/domain/memory_pair_scoring.dart';
import '../../memory_pairs/domain/memory_pair_shuffle.dart';
import '../data/onboarding_memory_pairs_data.dart';

double _onbScale(BuildContext context) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  return (shortest / 390).clamp(0.78, 1.22);
}

double _onb(BuildContext context, double designPx) =>
    designPx * _onbScale(context);

/// Onboarding demo: lightweight match board (not the full Memory Pairs game).
class OnboardingMemoryPairsPage extends HookWidget {
  const OnboardingMemoryPairsPage({
    super.key,
    required this.onSkip,
    required this.onContinue,
  });

  final VoidCallback onSkip;
  final VoidCallback onContinue;

  static const _pairs = kOnboardingFundamentalRightsPairs;

  @override
  Widget build(BuildContext context) {
    final showResult = useState(false);
    final skipSecondsLeft = useState(3);
    final skipEnabled = useState(false);

    final selKey = useState<int?>(null);
    final selVal = useState<int?>(null);
    final matched = useState(<int>{});
    final wrong = useState<({int k, int v})?>(null);
    final lock = useState(false);
    final errors = useState(0);
    final elapsed = useState(0);
    final started = useState(false);

    final keyOrder = useMemoized(
      () => shuffleIndices(_pairs.length, 3),
      const [],
    );
    final valOrder = useMemoized(
      () => shuffleIndices(_pairs.length, 11),
      const [],
    );

    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (timer) {
        final next = skipSecondsLeft.value - 1;
        if (next <= 0) {
          skipEnabled.value = true;
          timer.cancel();
        } else {
          skipSecondsLeft.value = next;
        }
      });
      return t.cancel;
    }, const []);

    useEffect(() {
      if (!started.value || showResult.value) return null;
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value++;
      });
      return t.cancel;
    }, [started.value, showResult.value]);

    useEffect(() {
      if (selKey.value == null || selVal.value == null) return null;
      lock.value = true;
      final k = selKey.value!;
      final v = selVal.value!;

      if (k == v) {
        final t = Timer(const Duration(milliseconds: 240), () {
          matched.value = {...matched.value, k};
          selKey.value = null;
          selVal.value = null;
          lock.value = false;
        });
        return t.cancel;
      }

      errors.value++;
      wrong.value = (k: k, v: v);
      final t = Timer(const Duration(milliseconds: 620), () {
        wrong.value = null;
        selKey.value = null;
        selVal.value = null;
        lock.value = false;
      });
      return t.cancel;
    }, [selKey.value, selVal.value]);

    useEffect(() {
      if (matched.value.length != _pairs.length) return null;
      final t = Timer(const Duration(milliseconds: 400), () {
        showResult.value = true;
      });
      return t.cancel;
    }, [matched.value.length]);

    void begin() {
      if (!started.value) started.value = true;
    }

    void tapKey(int pid) {
      if (showResult.value || lock.value || matched.value.contains(pid)) return;
      begin();
      selKey.value = selKey.value == pid ? null : pid;
    }

    void tapVal(int pid) {
      if (showResult.value || lock.value || matched.value.contains(pid)) return;
      begin();
      selVal.value = selVal.value == pid ? null : pid;
    }

    _TileState stateFor(int pid, bool isKey) {
      if (matched.value.contains(pid)) return _TileState.matched;
      final w = wrong.value;
      if (w != null) {
        if (isKey && w.k == pid || !isKey && w.v == pid) {
          return _TileState.wrong;
        }
      }
      if (isKey && selKey.value == pid) return _TileState.selected;
      if (!isKey && selVal.value == pid) return _TileState.selected;
      return _TileState.idle;
    }

    final hPad = _onb(context, 22);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, _onb(context, 4), hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _onb(context, 8),
                  vertical: _onb(context, 4),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(_onb(context, 6)),
                ),
                child: Text(
                  'QUICK DEMO',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 10),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: skipEnabled.value ? onSkip : null,
                style: TextButton.styleFrom(
                  foregroundColor: skipEnabled.value
                      ? AppColors.onSurfaceVariantLight
                      : AppColors.gray400,
                  padding: EdgeInsets.symmetric(horizontal: _onb(context, 10)),
                ),
                child: Text(
                  skipEnabled.value
                      ? 'Skip'
                      : 'Skip (${skipSecondsLeft.value})',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _onb(context, 8)),
          if (!showResult.value) ...[
            Text(
              'Try a quick match',
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 22),
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.onSurfaceLight,
              ),
            ),
            SizedBox(height: _onb(context, 6)),
            Text(
              'Tap an article, then its matching right. '
              'This is just a taste — not a test.',
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 14),
                height: 1.45,
                color: AppColors.onSurfaceVariantLight,
              ),
            ),
            SizedBox(height: _onb(context, 10)),
            Row(
              children: [
                Text(
                  '${matched.value.length}/${_pairs.length} matched',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariantLight,
                  ),
                ),
                const Spacer(),
                if (started.value)
                  Text(
                    formatMemoryPairTime(elapsed.value),
                    style: GoogleFonts.dmSans(
                      fontSize: _onb(context, 12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceVariantLight,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            SizedBox(height: _onb(context, 8)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ARTICLES',
                    style: GoogleFonts.dmSans(
                      fontSize: _onb(context, 10),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.onSurfaceVariantLight,
                    ),
                  ),
                ),
                SizedBox(width: _onb(context, 8)),
                Expanded(
                  child: Text(
                    'RIGHTS',
                    style: GoogleFonts.dmSans(
                      fontSize: _onb(context, 10),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.onSurfaceVariantLight,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _onb(context, 6)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final columnWidth = (constraints.maxWidth - gap) / 2;
                  final allTexts = [
                    for (final p in _pairs) ...[p.termEn, p.answerEn],
                  ];
                  final tileHeight = _uniformTileHeight(
                    context: context,
                    columnWidth: columnWidth,
                    texts: allTexts,
                  );

                  return SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (final pid in keyOrder)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _OnbMatchTile(
                                    text: _pairs[pid].termEn,
                                    height: tileHeight,
                                    state: stateFor(pid, true),
                                    onTap: () => tapKey(pid),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: Column(
                            children: [
                              for (final pid in valOrder)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _OnbMatchTile(
                                    text: _pairs[pid].answerEn,
                                    height: tileHeight,
                                    state: stateFor(pid, false),
                                    onTap: () => tapVal(pid),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: _OnboardingMatchResult(
                  seconds: elapsed.value,
                  errors: errors.value,
                  pairsCount: _pairs.length,
                  onContinue: onContinue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingMatchResult extends StatelessWidget {
  const _OnboardingMatchResult({
    required this.seconds,
    required this.errors,
    required this.pairsCount,
    required this.onContinue,
  });

  final int seconds;
  final int errors;
  final int pairsCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _onb(context, 56),
          height: _onb(context, 56),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: _onb(context, 32),
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: _onb(context, 16)),
        Text(
          'Nice — all matched!',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 24),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.onSurfaceLight,
          ),
        ),
        SizedBox(height: _onb(context, 8)),
        Text(
          'Revision games like this train recall in under a minute — '
          'without the pressure of a full mock.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 14),
            height: 1.5,
            color: AppColors.onSurfaceVariantLight,
          ),
        ),
        SizedBox(height: _onb(context, 14)),
        Text(
          '${formatMemoryPairTime(seconds)} · $pairsCount pairs'
          '${errors > 0 ? ' · $errors mismatches' : ''}',
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 13),
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariantLight,
          ),
        ),
        SizedBox(height: _onb(context, 24)),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: _onb(context, 14)),
            minimumSize: Size(double.infinity, _onb(context, 48)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
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
    );
  }
}

enum _TileState { idle, selected, matched, wrong }

const double _kTileFontSize = 12;
const double _kTileMinHeight = 44;

double _uniformTileHeight({
  required BuildContext context,
  required double columnWidth,
  required List<String> texts,
}) {
  const hPad = 10.0 + 16;
  const vPad = 12.0;
  final textStyle = GoogleFonts.dmSans(
    fontSize: _onb(context, _kTileFontSize),
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  final maxTextWidth = max(36.0, columnWidth - hPad);

  var maxHeight = _kTileMinHeight;
  final painter = TextPainter(textDirection: TextDirection.ltr);
  for (final text in texts) {
    painter
      ..text = TextSpan(text: text, style: textStyle)
      ..textAlign = TextAlign.center
      ..layout(maxWidth: maxTextWidth);
    maxHeight = max(maxHeight, painter.height + vPad);
  }
  return maxHeight;
}

class _OnbMatchTile extends StatelessWidget {
  const _OnbMatchTile({
    required this.text,
    required this.height,
    required this.state,
    required this.onTap,
  });

  final String text;
  final double height;
  final _TileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final interactive = state != _TileState.matched;

    final bg = switch (state) {
      _TileState.selected => AppColors.primary,
      _TileState.matched => AppColors.primaryLight.withValues(alpha: 0.45),
      _TileState.wrong => AppColors.wrongBg,
      _ => AppColors.surfaceSecondaryLight,
    };
    final fg = switch (state) {
      _TileState.selected => Colors.white,
      _TileState.matched => AppColors.primaryDark,
      _TileState.wrong => AppColors.wrong,
      _ => AppColors.onSurfaceLight,
    };
    final border = switch (state) {
      _TileState.selected => AppColors.primary,
      _TileState.matched => AppColors.primary.withValues(alpha: 0.35),
      _TileState.wrong => AppColors.wrong.withValues(alpha: 0.5),
      _ => AppColors.borderLight,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: height,
      width: double.infinity,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: interactive ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state == _TileState.matched) ...[
                    Icon(Icons.check, size: 12, color: fg),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: _onb(context, _kTileFontSize),
                        fontWeight: FontWeight.w600,
                        color: fg,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
