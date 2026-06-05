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
    show TrapDescription, trapDescriptionsProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

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
                AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Row(children: [
                IconButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/weak-areas'),
                  icon: const Icon(Icons.chevron_left),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trap Patterns', style: AppTextStyles.h2()),
                    trapsAsync.when(
                      data: (groups) => Text(
                        '${groups.length} pattern${groups.length == 1 ? '' : 's'} identified',
                        style: AppTextStyles.bodySm()
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ]),
            ),
            Expanded(
              child: trapsAsync.when(
                loading: () => _skeleton(scheme),
                error: (e, st) => Center(
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(weakTrapGroupsProvider),
                    child: const Text('Retry'),
                  ),
                ),
                data: (groups) {
                  if (groups.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No trap patterns yet',
                              style: AppTextStyles.h3()
                                  .copyWith(color: scheme.onSurface),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Patterns will appear here as you attempt more questions',
                              style: AppTextStyles.bodySm()
                                  .copyWith(color: scheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final descriptions = descriptionsAsync.when(
                    data: (map) => map,
                    loading: () => <String, TrapDescription>{},
                    error: (_, _) => <String, TrapDescription>{},
                  );

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: groups.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _TrapCard(
                      group: groups[i],
                      entry: descriptions[groups[i].trapType],
                      border: border,
                      scheme: scheme,
                    ),
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
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
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

class _TrapCard extends StatelessWidget {
  const _TrapCard({
    required this.group,
    required this.entry,
    required this.border,
    required this.scheme,
  });

  final TrapPatternGroup group;
  final TrapDescription? entry;
  final Color border;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // Use display_name from JSON; fall back to computed name if JSON hasn't loaded yet
    final displayName = entry?.displayName ??
        group.trapType
            .split('-')
            .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');

    return GestureDetector(
      onTap: () => context
          .push('/weak-areas/trap/${Uri.encodeComponent(group.trapType)}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: AppTextStyles.bodyMd()
                        .copyWith(color: scheme.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${group.questionCount} ${group.questionCount == 1 ? 'question' : 'questions'}',
                    style: AppTextStyles.caption()
                        .copyWith(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
            if (entry?.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                entry!.description,
                style: AppTextStyles.bodySm()
                    .copyWith(color: scheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
