import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/domain/entities/trap_pattern_group.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/trap_descriptions_provider.dart'
    show trapDescriptionsProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/trap_pattern_catalog.dart';
import '../widgets/trap_example_sheet.dart';
import '../widgets/trap_pattern_card.dart';
import '../widgets/trap_patterns_tracking_note.dart';
import '../../../l10n/l10n.dart';

class TrapPatternsScreen extends HookConsumerWidget {
  const TrapPatternsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      unawaited(Analytics.track(ref, const TrapAwarenessOpenedEvent()));
      return null;
    }, const []);

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final trapsAsync = ref.watch(weakTrapGroupsProvider);
    final descriptionsAsync = ref.watch(trapDescriptionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/weak-areas'),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trap Patterns', style: AppTextStyles.h2()),
                      descriptionsAsync.when(
                        data: (descriptions) {
                          final groups = trapsAsync.asData?.value ?? const [];
                          final caught = groups
                              .where((g) => g.questionCount > 0)
                              .length;
                          return Text(
                            caught == 0
                                ? context.l10n.trapsCatalogCount(
                                    descriptions.length,
                                  )
                                : context.l10n.trapsCaughtOfTotal(
                                    caught,
                                    descriptions.length,
                                  ),
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: descriptionsAsync.when(
                loading: () => _skeleton(scheme),
                error: (e, st) => Center(
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(trapDescriptionsProvider),
                    child: Text(context.l10n.commonRetry),
                  ),
                ),
                data: (descriptions) {
                  if (descriptions.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.trapsNoCatalog,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  final groups = trapsAsync.maybeWhen(
                    data: (g) => g,
                    orElse: () => const <TrapPatternGroup>[],
                  );
                  final items = TrapPatternCatalog.merge(
                    descriptions: descriptions,
                    groups: groups,
                  );

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      if (i == 0) return TrapPatternsTrackingNote();
                      final item = items[i - 1];
                      return TrapPatternCard(
                        item: item,
                        border: border,
                        onOpen: () => context.push(
                          '/weak-areas/trap/${Uri.encodeComponent(item.trapType)}',
                        ),
                        onSeeExample: () => unawaited(
                          showTrapExampleSheet(
                            context: context,
                            trapType: item.trapType,
                            displayName: item.displayName,
                            blurb: item.blurb,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeleton(ColorScheme scheme) => ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xxl,
    ),
    itemCount: 4,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (_, _) => Container(
      height: 96,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );
}
