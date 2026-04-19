import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/legacy.dart'
    show StateNotifier, StateNotifierProvider;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/router/app_router.dart' show rootNavigatorKey;
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/providers/battle_spectate_provider.dart';
import 'package:upsc_wars/features/battle/widgets/battle_live_scoreboard.dart';

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
  if (w.isEmpty) return 'Your opponent';
  return w.first;
}

String battleSpectateVerdictLine(BattleSpectateState s) {
  final diff = s.playerPoints - s.opponentPoints;
  if (s.opponentCaughtUp || s.timerExpired) {
    if (diff.abs() < 0.001) {
      return 'Tie on points.';
    }
    if (diff > 0) {
      return 'You were ahead on points.';
    }
    return 'Your opponent was ahead on points.';
  }
  if (diff > 0.5) {
    return 'You are ahead on points (for now).';
  }
  if (diff < -0.5) {
    return 'Your opponent is ahead on points (for now).';
  }
  return 'Scores are very close.';
}

String battleSpectateStatusSubline(BattleSpectateState s) {
  final short = _opponentShortName(s.opponentName);
  if (s.opponentCaughtUp) {
    return '$short has locked in every answer.';
  }
  if (s.timerExpired) {
    return 'The timer window ended; the room will not add more live marks.';
  }
  return '$short is still working through the paper.';
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
    builder:
        (ctx) => AlertDialog(
          title: Text('Close live duel?', style: AppTextStyles.h3()),
          content: Text(
            '${_opponentShortName(s.opponentName)} is still answering. '
            'Stop the live duel anyway?',
            style: AppTextStyles.bodyMd(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stop'),
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
    builder:
        (ctx) => AlertDialog(
          title: Text('Leave the live board?', style: AppTextStyles.h3()),
          content: Text(
            '${_opponentShortName(s.opponentName)} is still answering. '
            'Do you want to stop watching?',
            style: AppTextStyles.bodyMd(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep watching'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stop'),
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

    if (s == null || sheetOpen) return const SizedBox.shrink();

    final settled = s.battleSettled;
    final accent = settled ? AppColors.info : AppColors.primary;
    final duelIcon =
        settled ? Icons.check_circle_rounded : Icons.sensors_rounded;
    final duelLabel = settled ? 'They\'re done' : 'Live duel';

    final bottom = MediaQuery.of(context).padding.bottom + 88;

    return Positioned(
      right: AppSpacing.md,
      bottom: bottom,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: accent,
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

    if (s == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      });
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
                  onPressed: () async {
                    final stopped = await tryStopBattleSpectate(
                      sheetContext,
                      ref,
                    );
                    if (stopped && sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  icon: const Icon(Icons.visibility_off_outlined, size: 20),
                  label: const Text('Stop following'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Close panel'),
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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxH = MediaQuery.sizeOf(sheetContext).height * 0.92;
        return _BattleSpectateSheetBody(
          sheetContext: sheetContext,
          maxH: maxH,
        );
      },
    );
  } finally {
    ref.read(battleSpectateSheetOpenProvider.notifier).setOpen(false);
  }
}
