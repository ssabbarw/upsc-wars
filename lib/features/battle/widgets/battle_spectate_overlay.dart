import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/router/app_router.dart' show rootNavigatorKey;
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/widgets/dismissible_modal_sheet.dart';
import 'package:upsc_wars/features/battle/providers/battle_spectate_provider.dart';
import 'package:upsc_wars/features/battle/widgets/battle_live_scoreboard.dart';
import '../../../l10n/l10n.dart';

/// True while the spectate bottom sheet is on screen (hides the FAB chip).
class BattleSpectateSheetOpenNotifier extends StateNotifier<bool> {
  BattleSpectateSheetOpenNotifier() : super(false);

  void setOpen(bool value) => state = value;
}

final battleSpectateSheetOpenProvider =
    StateNotifierProvider<BattleSpectateSheetOpenNotifier, bool>(
      (ref) => BattleSpectateSheetOpenNotifier(),
    );

String _opponentShortName(String opponentName) {
  final w = opponentName
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (w.isEmpty) return appL10n.bsoYourOpp;
  return w.first;
}

String battleSpectateVerdictLine(BattleSpectateState s) {
  final diff = s.playerPoints - s.opponentPoints;
  if (s.opponentCaughtUp || s.timerExpired) {
    if (diff.abs() < 0.001) {
      return appL10n.bsoTie;
    }
    if (diff > 0) {
      return appL10n.bsoYouAhead;
    }
    return appL10n.bsoOppAhead;
  }
  if (diff > 0.5) {
    return appL10n.bsoYouAheadNow;
  }
  if (diff < -0.5) {
    return appL10n.bsoOppAheadNow;
  }
  return appL10n.bsoClose;
}

String battleSpectateStatusSubline(BattleSpectateState s) {
  final short = _opponentShortName(s.opponentName);
  if (s.opponentPaperSubmitted && !s.opponentCaughtUp) {
    return appL10n.bsoSubmitted(short);
  }
  if (s.opponentCaughtUp) {
    return appL10n.bsoLockedAll(short);
  }
  if (s.timerExpired) {
    return appL10n.bsoTimerEnded;
  }
  return appL10n.bsoStillWorking(short);
}

Offset? _decodeFabOffset(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(',');
  if (parts.length != 2) return null;
  final dx = double.tryParse(parts[0].trim());
  final dy = double.tryParse(parts[1].trim());
  if (dx == null || dy == null) return null;
  return Offset(dx, dy);
}

String _encodeFabOffset(Offset o) =>
    '${o.dx.toStringAsFixed(1)},${o.dy.toStringAsFixed(1)}';

Offset _defaultFabTopLeft(Size canvas, MediaQueryData mq, Size fab) {
  return Offset(
    canvas.width - fab.width - AppSpacing.md,
    canvas.height - mq.padding.bottom - 88 - fab.height,
  );
}

Offset _clampFabTopLeft(Offset o, Size canvas, MediaQueryData mq, Size fab) {
  const margin = AppSpacing.sm;
  final pad = mq.padding;
  final minLeft = pad.left + margin;
  final minTop = pad.top + margin;
  final maxLeft = math.max(
    minLeft,
    canvas.width - fab.width - pad.right - margin,
  );
  final maxTop = math.max(
    minTop,
    canvas.height - fab.height - pad.bottom - margin,
  );
  return Offset(o.dx.clamp(minLeft, maxLeft), o.dy.clamp(minTop, maxTop));
}

/// FAB close (X): confirm before stopping while the opponent is still playing.
/// When the battle is already settled, stops immediately (same as the sheet).
///
/// Uses [rootNavigatorKey] for the dialog because [BattleSpectateFabHost] may
/// sit above the route [Navigator], so its own [BuildContext] cannot push
/// routes.
Future<void> promptStopLiveDuelFromFab(WidgetRef ref) async {
  final s = ref.read(battleSpectateProvider);
  if (s == null) return;

  if (s.battleSettled) {
    ref.read(battleSpectateProvider.notifier).stop();
    return;
  }

  final dialogContext = rootNavigatorKey.currentContext;
  if (dialogContext == null) return;

  final ok = await showDialog<bool>(
    context: dialogContext,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.bsoCloseTitle, style: AppTextStyles.h3()),
      content: Text(
        ctx.l10n.bsoCloseBody(_opponentShortName(s.opponentName)),
        style: AppTextStyles.bodyMd(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.bsoStop),
        ),
      ],
    ),
  );
  if (ok == true) {
    ref.read(battleSpectateProvider.notifier).stop();
  }
}

/// Stops spectating from the sheet. If the user cancels the confirmation
/// dialog, returns false and leaves spectate running. When the battle is
/// settled, stops without a dialog.
Future<bool> tryStopBattleSpectate(BuildContext context, WidgetRef ref) async {
  final s = ref.read(battleSpectateProvider);
  if (s == null) return true;

  if (s.battleSettled) {
    ref.read(battleSpectateProvider.notifier).stop();
    return true;
  }

  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.l10n.bsoLeaveTitle, style: AppTextStyles.h3()),
      content: Text(
        ctx.l10n.bsoLeaveBody(_opponentShortName(s.opponentName)),
        style: AppTextStyles.bodyMd(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.bsoKeepWatching),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.l10n.bsoStop),
        ),
      ],
    ),
  );
  if (ok == true) {
    ref.read(battleSpectateProvider.notifier).stop();
    return true;
  }
  return false;
}

/// Global overlay: floating spectate control on every route until dismissed.
class BattleSpectateFabHost extends HookConsumerWidget {
  const BattleSpectateFabHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(battleSpectateProvider);
    final sheetOpen = ref.watch(battleSpectateSheetOpenProvider);

    final tick = useState(0);
    useEffect(() {
      if (s == null) return null;
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        tick.value++;
      });
      return t.cancel;
    }, [s?.sessionId]);

    final fabTopLeft = useState<Offset?>(null);
    final fabSize = useState(const Size(200, 48));
    final persistTimer = useRef<Timer?>(null);

    useEffect(() {
      Future(() async {
        try {
          final prefs = await ref.read(prefsServiceProvider.future);
          final parsed = _decodeFabOffset(prefs.battleSpectateFabPosition);
          if (parsed != null) {
            fabTopLeft.value = parsed;
          }
        } catch (_) {}
      });
      return () {
        persistTimer.value?.cancel();
      };
    }, const []);

    if (s == null || sheetOpen) return const SizedBox.shrink();

    final settled = s.battleSettled;
    final accent = settled ? AppColors.info : AppColors.primary;
    final duelIcon = settled ? Icons.flag_rounded : Icons.sensors_rounded;
    final duelLabel = settled
        ? context.l10n.bsoBattleOver
        : context.l10n.bsoLiveDuel;

    void schedulePersistFab(Offset topLeft) {
      persistTimer.value?.cancel();
      persistTimer.value = Timer(const Duration(milliseconds: 450), () async {
        try {
          final prefs = await ref.read(prefsServiceProvider.future);
          prefs.battleSpectateFabPosition = _encodeFabOffset(topLeft);
        } catch (_) {}
      });
    }

    // [Positioned] must be a direct child of the root [Stack] in
    // [MaterialApp.router] `builder` — not wrapped in [LayoutBuilder].
    final mq = MediaQuery.of(context);
    final canvas = mq.size;
    final sz = fabSize.value;
    final defaultPos = _defaultFabTopLeft(canvas, mq, sz);
    final topLeft = _clampFabTopLeft(
      fabTopLeft.value ?? defaultPos,
      canvas,
      mq,
      sz,
    );

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final base = fabTopLeft.value ?? defaultPos;
          final next = _clampFabTopLeft(base + details.delta, canvas, mq, sz);
          fabTopLeft.value = next;
          schedulePersistFab(next);
        },
        child: Material(
          elevation: 10,
          color: accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: settled
                ? BorderSide(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                    width: 2,
                  )
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => openBattleSpectateSheet(ref),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.xl),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(duelIcon, color: AppColors.onPrimary, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        duelLabel,
                        style: AppTextStyles.label().copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => promptStopLiveDuelFromFab(ref),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.xl),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    4,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: Icon(
                    Icons.close,
                    color: AppColors.onPrimary.withValues(alpha: 0.92),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleSpectateSheetBody extends HookConsumerWidget {
  const _BattleSpectateSheetBody({
    required this.sheetContext,
    required this.maxH,
  });

  final BuildContext sheetContext;
  final double maxH;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(sheetContext).colorScheme;
    final viewPad = MediaQuery.viewPaddingOf(sheetContext).bottom;

    final s = ref.watch(battleSpectateProvider);
    final tick = useState(0);
    useEffect(() {
      if (s == null) return null;
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        tick.value++;
      });
      return t.cancel;
    }, [s?.sessionId]);

    useEffect(() {
      if (s != null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!sheetContext.mounted) return;
        // Only dismiss this bottom sheet — never pop the route below it.
        final route = ModalRoute.of(sheetContext);
        if (route?.isCurrent ?? false) {
          Navigator.of(sheetContext).pop();
        }
      });
      return null;
    }, [s == null]);

    if (s == null) {
      return const SizedBox.shrink();
    }

    final settled = s.battleSettled;
    final accent = settled ? AppColors.info : AppColors.primary;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Material(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.08),
            scheme.surface,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg + viewPad,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  battleSpectateVerdictLine(s),
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  battleSpectateStatusSubline(s),
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                BattleLiveScoreboard(sessionId: s.sessionId),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => tryStopBattleSpectate(sheetContext, ref),
                  icon: const Icon(Icons.visibility_off_outlined, size: 20),
                  label: Text(context.l10n.bsoStopFollowing),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(context.l10n.bsoClosePanel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openBattleSpectateSheet(WidgetRef ref) async {
  final anchor = rootNavigatorKey.currentContext;
  if (anchor == null) return;

  ref.read(battleSpectateSheetOpenProvider.notifier).setOpen(true);
  try {
    await showModalBottomSheet<void>(
      context: anchor,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxH = MediaQuery.sizeOf(sheetContext).height * 0.92;
        return DismissOnScrimTap(
          child: _BattleSpectateSheetBody(
            sheetContext: sheetContext,
            maxH: maxH,
          ),
        );
      },
    );
  } finally {
    ref.read(battleSpectateSheetOpenProvider.notifier).setOpen(false);
  }
}
