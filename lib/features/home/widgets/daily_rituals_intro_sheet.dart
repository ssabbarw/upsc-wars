import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../domain/daily_rituals.dart';
import '../../../l10n/l10n.dart';

Future<List<DailyRitualCopy>> _enabledDailyRituals(
  ProviderContainer container,
) async {
  final caShots = await container.read(caShotsRemoteEnabledProvider.future);
  final dailyCa = await container.read(dailyCaRemoteEnabledProvider.future);
  final dailyWar = await container.read(dailyWarRemoteEnabledProvider.future);
  return DailyRituals.enabledItems(
    caShotsEnabled: caShots,
    dailyCaEnabled: dailyCa,
    dailyWarEnabled: dailyWar,
  );
}

/// One-time Home sheet: CA Shots, Daily CA Test, Daily Battle — only rows
/// whose Remote Config flags are on. Skipped when none are enabled.
Future<void> maybeShowDailyRitualsIntro({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  if (kIsWeb) return;
  final container = ProviderScope.containerOf(context, listen: false);
  await Future<void>.delayed(const Duration(milliseconds: 700));
  if (!context.mounted) return;
  if (!TickerMode.valuesOf(context).enabled) return;
  if (GoRouter.of(context).routeInformationProvider.value.uri.path != '/') {
    return;
  }
  if (ModalRoute.of(context)?.isCurrent != true) return;

  final kill = container.read(killSwitchProvider).asData?.value;
  if (kill?.isActive ?? false) return;

  final enabled = await _enabledDailyRituals(container);
  if (enabled.isEmpty) return;
  final enabledIds = enabled.map((r) => r.id).toSet();

  final prefs = await container.read(prefsServiceProvider.future);
  if (!DailyRituals.shouldShowIntro(
    onboardingSeen: prefs.patternInterruptOnboardingSeen,
    introSeen: prefs.dailyRitualsIntroSeen,
    openedIds: prefs.dailyRitualsOpenedIds,
    enabledIds: enabledIds,
  )) {
    if (!prefs.dailyRitualsIntroSeen &&
        enabledIds.every(prefs.dailyRitualsOpenedIds.contains)) {
      prefs.dailyRitualsIntroSeen = true;
    }
    return;
  }

  if (!context.mounted) return;
  await showDailyRitualsIntroSheet(context, ref, items: enabled);
}

Future<void> showDailyRitualsIntroSheet(
  BuildContext context,
  WidgetRef ref, {
  bool fromHelp = false,
  List<DailyRitualCopy>? items,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final enabled = items ?? await _enabledDailyRituals(container);
  if (enabled.isEmpty) return;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: AppColors.transparent,
    builder: (ctx) => DismissOnScrimTap(
      child: _DailyRitualsIntroSheet(fromHelp: fromHelp, items: enabled),
    ),
  );
}

class _DailyRitualsIntroSheet extends ConsumerStatefulWidget {
  const _DailyRitualsIntroSheet({
    required this.fromHelp,
    required this.items,
  });

  final bool fromHelp;
  final List<DailyRitualCopy> items;

  @override
  ConsumerState<_DailyRitualsIntroSheet> createState() =>
      _DailyRitualsIntroSheetState();
}

class _DailyRitualsIntroSheetState
    extends ConsumerState<_DailyRitualsIntroSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_markSeenAndLog());
    });
  }

  Future<void> _markSeenAndLog() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.dailyRitualsIntroSeen = true;
    if (!mounted) return;
    unawaited(
      Analytics.track(
        ref,
        FeatureViewedEvent(
          featureName: 'daily_rituals_intro',
          subject: widget.fromHelp ? 'help' : 'home',
          source: widget.fromHelp ? 'keep_going_help' : 'home_auto',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = sheetBottomPadding(context, base: AppSpacing.md);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.ritualsIntroTitle,
                style: AppTextStyles.h2().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                switch (widget.items.length) {
                  1 => context.l10n.ritualsIntroOne,
                  2 => context.l10n.ritualsIntroTwo,
                  _ => context.l10n.ritualsIntroThree,
                },
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < widget.items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _RitualRow(
                  ritual: widget.items[i],
                  isDark: isDark,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  context.l10n.commonGotIt,
                  style: AppTextStyles.label().copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
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

class _RitualRow extends StatelessWidget {
  const _RitualRow({
    required this.ritual,
    required this.isDark,
  });

  final DailyRitualCopy ritual;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ritual.accent.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(ritual.icon, color: ritual.accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ritual.title,
                    style: AppTextStyles.label().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ritual.when,
                    style: AppTextStyles.caption().copyWith(
                      color: ritual.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ritual.body,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
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
