import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/trap_descriptions_provider.dart'
    show trapDescriptionsProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../providers/trap_example_provider.dart';
import '../widgets/trap_example_sheet.dart';
import '../widgets/trap_pattern_visual.dart';

class TrapPatternDetailScreen extends ConsumerWidget {
  const TrapPatternDetailScreen({super.key, required this.trapType});
  final String trapType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final descriptionsAsync = ref.watch(trapDescriptionsProvider);
    final language = watchAppLanguage(ref);

    final decoded = Uri.decodeComponent(trapType);
    final trapEntry = descriptionsAsync.when(
      data: (map) => map[decoded],
      loading: () => null,
      error: (_, _) => null,
    );
    final displayName = trapEntry?.displayName ?? _titleCaseSlug(decoded);
    final description = trapEntry?.descriptionFor(language);
    final exampleAsync = ref.watch(trapExampleProvider(decoded));

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
                    trapType: decoded,
                    size: 32,
                    iconSize: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      displayName,
                      style: AppTextStyles.h2(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
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
                        color: isDark
                            ? AppColors.primaryDeep
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        description,
                        style: AppTextStyles.bodySm().copyWith(
                          color: isDark
                              ? AppColors.onPrimary
                              : AppColors.primaryDeep,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text(
                    context.l10n.trapsExampleEyebrow,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.wrong,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  exampleAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => Text(
                      context.l10n.trapsExampleLoadFailed,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    data: (example) {
                      if (example == null) {
                        return Text(
                          context.l10n.trapsNoExample,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return TrapExampleMcq(
                        example: example,
                        language: language,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleCaseSlug(String slug) {
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
