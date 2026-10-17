import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/trap_descriptions_provider.dart'
    show trapDescriptionsProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../widgets/trap_example_sheet.dart';
import '../widgets/trap_pattern_visual.dart';

class TrapPatternDetailScreen extends HookConsumerWidget {
  const TrapPatternDetailScreen({super.key, required this.trapType});
  final String trapType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final trapsAsync = ref.watch(weakTrapGroupsProvider);
    final revisionAsync = ref.watch(revisionQueueItemsProvider);
    final descriptionsAsync = ref.watch(trapDescriptionsProvider);
    final loading = useState(false);

    final decoded = Uri.decodeComponent(trapType);
    final trapEntry = descriptionsAsync.when(
      data: (map) => map[decoded],
      loading: () => null,
      error: (_, _) => null,
    );
    final displayName =
        trapEntry?.displayName ??
        decoded
            .split('-')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
    final description = trapEntry?.description;
    final blurb = trapEntry?.blurb ?? '';

    return trapsAsync.when(
      loading: () => _scaffold(
        context,
        displayName,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => _scaffold(
        context,
        displayName,
        child: Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(weakTrapGroupsProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (groups) {
        final group = groups.where((g) => g.trapType == decoded).firstOrNull;

        Future<void> practice() async {
          if (loading.value || group == null || group.questionUuids.isEmpty) {
            return;
          }
          loading.value = true;
          try {
            final create = await ref.read(createSessionUseCaseProvider.future);
            final lang = await ref.read(appLanguageProvider.future);
            final id = await create.execute(
              SessionConfig(
                subject: 'revision',
                mode: 'learning',
                questionCount: group.questionUuids.length,
                isTimed: true,
                timeLimitSecs: 60,
                language: lang,
                specificQuestionUuids: group.questionUuids,
                analyticsFeatureKey: 'trap_awareness',
              ),
            );
            if (context.mounted) context.push('/test/$id');
          } finally {
            loading.value = false;
          }
        }

        final hasCaught = group != null && group.questionCount > 0;
        final caughtGroup = group;

        return _scaffold(
          context,
          displayName,
          bottomBar: hasCaught
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: loading.value ? null : practice,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      child: loading.value
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Practice This Trap Type'),
                    ),
                  ),
                )
              : null,
          child: caughtGroup == null
              ? _detailBody(
                  context: context,
                  scheme: scheme,
                  isDark: isDark,
                  border: border,
                  description: description,
                  blurb: blurb,
                  displayName: displayName,
                  decoded: decoded,
                  caughtCount: 0,
                  stems: const [],
                )
              : revisionAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _detailBody(
                    context: context,
                    scheme: scheme,
                    isDark: isDark,
                    border: border,
                    description: description,
                    blurb: blurb,
                    displayName: displayName,
                    decoded: decoded,
                    caughtCount: caughtGroup.questionCount,
                    stems: const [],
                  ),
                  data: (allItems) {
                    final items = allItems
                        .where(
                          (i) => caughtGroup.questionUuids.contains(
                            i.questionUuid,
                          ),
                        )
                        .toList();
                    return _detailBody(
                      context: context,
                      scheme: scheme,
                      isDark: isDark,
                      border: border,
                      description: description,
                      blurb: blurb,
                      displayName: displayName,
                      decoded: decoded,
                      caughtCount: caughtGroup.questionCount,
                      stems: items.map((i) => i.questionStem).toList(),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _detailBody({
    required BuildContext context,
    required ColorScheme scheme,
    required bool isDark,
    required Color border,
    required String? description,
    required String blurb,
    required String displayName,
    required String decoded,
    required int caughtCount,
    required List<String> stems,
  }) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        if (description != null && description.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primaryDeep : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              description,
              style: AppTextStyles.bodySm().copyWith(
                color: isDark ? AppColors.onPrimary : AppColors.primaryDeep,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            caughtCount == 0
                ? 'Caught you 0× — not enough data yet'
                : '$caughtCount ${caughtCount == 1 ? 'question' : 'questions'} caught by this trap',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => unawaited(
              showTrapExampleSheet(
                context: context,
                trapType: decoded,
                displayName: displayName,
                blurb: blurb,
              ),
            ),
            child: const Text('See example'),
          ),
        ),
        if (stems.isNotEmpty) const SizedBox(height: AppSpacing.sm),
        ...stems.map(
          (stem) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Text(
              stem,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.readingFont(
                AppTextStyles.bodyMd().copyWith(color: scheme.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scaffold(
    BuildContext context,
    String title, {
    required Widget child,
    Widget? bottomBar,
  }) {
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
                        : context.go('/weak-areas/traps'),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  TrapPatternIconWell(
                    trapType: Uri.decodeComponent(trapType),
                    size: 32,
                    iconSize: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.h2(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(top: false, child: bottomBar),
    );
  }
}
