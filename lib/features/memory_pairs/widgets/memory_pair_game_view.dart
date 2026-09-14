import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_models.dart';
import '../domain/memory_pair_scoring.dart';
import '../domain/memory_pair_shuffle.dart';

typedef MemoryPairGameDone = void Function(MemoryPairGameResult result);

class MemoryPairGameView extends HookWidget {
  const MemoryPairGameView({
    super.key,
    required this.pairs,
    required this.lang,
    required this.onDone,
    required this.onQuit,
  });

  final List<MemoryPair> pairs;
  final String lang;
  final MemoryPairGameDone onDone;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final selKey = useState<int?>(null);
    final selVal = useState<int?>(null);
    final matched = useState(<int>{});
    final wrong = useState<({int k, int v})?>(null);
    final lock = useState(false);
    final errors = useState(0);
    final weak = useState(<int>{});
    final paused = useState(false);
    final elapsed = useState(0);
    final started = useState(true);
    final celebrate = useState(false);
    final reported = useRef(false);

    final keyOrder = useMemoized(
      () => shuffleIndices(pairs.length, 7),
      [pairs],
    );
    final valOrder = useMemoized(
      () => shuffleIndices(pairs.length, 19),
      [pairs],
    );

    useEffect(() {
      if (!started.value || paused.value) return null;
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value++;
      });
      return t.cancel;
    }, [started.value, paused.value]);

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
      weak.value = {...weak.value, k, v};
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
      if (matched.value.length != pairs.length || pairs.isEmpty) return null;
      if (reported.value) return null;
      celebrate.value = true;
      final t = Timer(const Duration(milliseconds: 1500), () {
        if (reported.value) return;
        reported.value = true;
        final weakPairs = weak.value.map((i) => pairs[i]).toList();
        onDone(
          MemoryPairGameResult(
            seconds: elapsed.value,
            errors: errors.value,
            pairsCount: pairs.length,
            weakPairs: weakPairs,
          ),
        );
      });
      return t.cancel;
    }, [matched.value.length, pairs.length]);

    void tapKey(int pid) {
      if (lock.value || paused.value || matched.value.contains(pid)) return;
      selKey.value = selKey.value == pid ? null : pid;
    }

    void tapVal(int pid) {
      if (lock.value || paused.value || matched.value.contains(pid)) return;
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

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    formatMemoryPairTime(elapsed.value),
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        '${errors.value}',
                        style: AppTextStyles.h2().copyWith(
                          color: errors.value > 0
                              ? AppColors.wrong
                              : scheme.onSurfaceVariant,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Errors',
                        style: AppTextStyles.caption().copyWith(
                          color: errors.value > 0
                              ? AppColors.wrong
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => paused.value = true,
                    icon: const Icon(Icons.pause_circle_outline),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${matched.value.length}/${pairs.length} matched',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: pairs.isEmpty
                          ? 0
                          : matched.value.length / pairs.length,
                      minHeight: 5,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Terms',
                      style: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Answers',
                      style: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = AppSpacing.sm;
                  final columnWidth =
                      (constraints.maxWidth - AppSpacing.lg * 2 - gap) / 2;
                  final allTexts = [
                    for (final p in pairs) ...[
                      p.termForLang(lang),
                      p.answerForLang(lang),
                    ],
                  ];
                  final tileHeight = _uniformMatchTileHeight(
                    columnWidth: columnWidth,
                    texts: allTexts,
                    textScaler: MediaQuery.textScalerOf(context),
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (final pid in keyOrder)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _MatchTile(
                                    text: pairs[pid].termForLang(lang),
                                    minHeight: tileHeight,
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
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _MatchTile(
                                    text: pairs[pid].answerForLang(lang),
                                    minHeight: tileHeight,
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
          ],
        ),
        if (celebrate.value) ...[
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
          ),
          Center(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: scheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 40, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'All pairs matched',
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${formatMemoryPairTime(elapsed.value)} · ${errors.value} errors',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        if (paused.value)
          _PauseOverlay(
            time: formatMemoryPairTime(elapsed.value),
            errors: errors.value,
            onResume: () => paused.value = false,
            onQuit: onQuit,
          ),
      ],
    );
  }
}

enum _TileState { idle, selected, matched, wrong }

const double _kMatchTileFontSize = 14;
const double _kMatchTileLineHeight = 1.25;
const double _kMatchTileMinHeight = 52;
const double _kMatchTileHPad = 8;
const double _kMatchTileVPad = 8;
const double _kMatchTileCheckSize = 14;
const double _kMatchTileCheckGap = 4;

/// Same min height for every tile — sized to fit the longest wrapped label.
double _uniformMatchTileHeight({
  required double columnWidth,
  required List<String> texts,
  required TextScaler textScaler,
}) {
  // Always reserve check-icon space so matched tiles don't wrap tighter.
  const hPad = _kMatchTileHPad * 2 + _kMatchTileCheckSize + _kMatchTileCheckGap;
  const vPad = _kMatchTileVPad * 2;
  final textStyle = AppTextStyles.labelSm().copyWith(
    fontSize: _kMatchTileFontSize,
    fontWeight: FontWeight.w600,
    height: _kMatchTileLineHeight,
  );
  // Slightly narrower than layout width: Google Fonts metrics can differ from
  // TextPainter, which previously under-estimated wrap and clipped labels.
  final maxTextWidth = max(40.0, (columnWidth - hPad) * 0.92);

  var maxHeight = _kMatchTileMinHeight;
  final painter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    textScaler: textScaler,
  );
  for (final text in texts) {
    painter
      ..text = TextSpan(text: text, style: textStyle)
      ..layout(maxWidth: maxTextWidth);
    maxHeight = max(maxHeight, painter.height + vPad);
  }
  // Small buffer against remaining font-metric drift.
  return maxHeight + 4;
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.text,
    required this.minHeight,
    required this.state,
    required this.onTap,
  });

  final String text;
  final double minHeight;
  final _TileState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final interactive = state != _TileState.matched;
    final matched = state == _TileState.matched;

    final bg = switch (state) {
      _TileState.selected => AppColors.primary,
      _TileState.matched => isDark
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.primaryLight.withValues(alpha: 0.5),
      _TileState.wrong => isDark
          ? AppColors.wrong.withValues(alpha: 0.18)
          : AppColors.wrongBg,
      _ => scheme.surface,
    };
    final fg = switch (state) {
      _TileState.selected => Colors.white,
      _TileState.matched => AppColors.primary,
      _TileState.wrong => AppColors.wrong,
      _ => scheme.onSurface,
    };
    final border = switch (state) {
      _TileState.selected => AppColors.primary,
      _TileState.matched => AppColors.primary.withValues(alpha: 0.45),
      _TileState.wrong => AppColors.wrong,
      _ => isDark ? AppColors.borderDark : AppColors.borderLight,
    };

    final textStyle = AppTextStyles.labelSm().copyWith(
      fontSize: _kMatchTileFontSize,
      fontWeight: FontWeight.w600,
      color: fg,
      height: _kMatchTileLineHeight,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          onTap: interactive ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kMatchTileHPad,
              vertical: _kMatchTileVPad,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _kMatchTileCheckSize + _kMatchTileCheckGap,
                  child: matched
                      ? Icon(
                          Icons.check,
                          size: _kMatchTileCheckSize,
                          color: fg,
                        )
                      : null,
                ),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: textStyle,
                  ),
                ),
                // Keep label centered when the leading check slot is reserved.
                const SizedBox(width: _kMatchTileCheckSize + _kMatchTileCheckGap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.time,
    required this.errors,
    required this.onResume,
    required this.onQuit,
  });

  final String time;
  final int errors;
  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Material(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pause_circle_outline, size: 36),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Paused', style: AppTextStyles.h3()),
                  Text('$time · $errors errors'),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onResume,
                      child: const Text('Resume'),
                    ),
                  ),
                  TextButton(
                    onPressed: onQuit,
                    child: const Text('Quit to set'),
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
