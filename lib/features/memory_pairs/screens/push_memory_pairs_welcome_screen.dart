import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/memory_pair_sets_data.dart';
import '../domain/memory_pair_models.dart';
import '../push/push_memory_pairs_launch_params.dart';
import '../widgets/memory_pair_shared_widgets.dart';
import '../../../l10n/l10n.dart';

/// Push / deep-link entry: welcome copy then [Start] → match game.
class PushMemoryPairsWelcomeScreen extends StatelessWidget {
  const PushMemoryPairsWelcomeScreen({super.key, required this.params});

  final PushMemoryPairsLaunchParams params;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final err = params.validationError;

    if (err != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          context.go('/');
        },
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.mpOpenFailed,
                    style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    err,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: () => context.go('/'),
                    child: Text(context.l10n.mpGoHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final set = memoryPairSetById(params.setId.trim())!;
    final playCount = set.difficulty.pairCount.clamp(0, set.pairs.length);
    final title = (params.title?.trim().isNotEmpty ?? false)
        ? params.title!.trim()
        : set.nameEn;
    final body = (params.body?.trim().isNotEmpty ?? false)
        ? params.body!.trim()
        : context.l10n.mpQuickDrill(playCount);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Spacer(flex: 1),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: set.accentColor.withValues(
                        alpha: isDark ? 0.22 : 0.14,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: set.accentColor.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(set.icon, size: 40, color: set.accentColor),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.mpRevisionGame,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2().copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
                        : scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MemoryPairDifficultyChip(difficulty: set.difficulty),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        context.l10n.mpPairsCount(playCount),
                        style: AppTextStyles.labelSm().copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        set.subjectLabelForLang('en'),
                        style: AppTextStyles.labelSm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                FilledButton(
                  onPressed: () => context.go(params.autoplayGameLocation),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    context.l10n.gmStart,
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.go('/memory-pairs'),
                  child: Text(context.l10n.mpBrowseAll),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
