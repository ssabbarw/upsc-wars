import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../practice_tests/providers/practice_catalog_provider.dart';
import '../../practice_tests/widgets/practice_insights_view.dart';

/// Season stats in the same shape as a subject or topic: accuracy, Sure and
/// educated guess, traps, then confident mistakes and guess mistakes.
///
/// All subjects rolls ratings and traps across every subject, and lists
/// confident mistakes and guesses by subject. A subject pill keeps only
/// that subject.
class StatsScreen extends HookConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = GoRouterState.of(context).uri.queryParameters['subject'];
    final catalog = ref.watch(practiceCatalogProvider);
    final scheme = Theme.of(context).colorScheme;

    useEffect(() {
      unawaited(
        Analytics.track(ref, StatsViewedEvent(subject: selected ?? 'all')),
      );
      return null;
    }, [selected]);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Text(
                context.l10n.statsTitle,
                style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _Pills(
                selected: selected,
                onSelect: (slug) {
                  if (slug == null) {
                    context.go('/stats');
                  } else {
                    context.go(
                      '/stats?subject=${Uri.encodeQueryComponent(slug)}',
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: catalog.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(practiceCatalogProvider),
                    child: Text(context.l10n.commonRetry),
                  ),
                ),
                data: (_) {
                  if (selected == null) {
                    return const PracticeSubjectInsightsView.all();
                  }
                  return PracticeSubjectInsightsView(
                    key: ValueKey(selected),
                    subject: selected,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pills extends StatelessWidget {
  const _Pills({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Pill(
            label: context.l10n.statsAllSubjects,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final def in SubjectConstants.ordered) ...[
            const SizedBox(width: AppSpacing.sm),
            _Pill(
              label: def.displayName,
              selected: selected == def.slug,
              onTap: () => onSelect(def.slug),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.16),
      labelStyle: AppTextStyles.caption().copyWith(
        color: selected ? AppColors.primary : scheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
