import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../../daily_war/screens/daily_war_history_screen.dart';
import '../../history/screens/history_screen.dart';
import 'progress_screen.dart';

/// Shell tab that hosts Progress, Test History, and Daily Wars History.
class ProgressHubScreen extends HookConsumerWidget {
  const ProgressHubScreen({super.key, this.initialTabIndex = 0});

  /// 0 = Progress, 1 = Test History, 2 = Daily Wars History.
  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(initialTabIndex.clamp(0, 2));
    final scheme = Theme.of(context).colorScheme;

    return PopToShellHomeScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Progress', style: AppTextStyles.h3()),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  for (final entry in const [
                    (0, 'Progress'),
                    (1, 'Test History'),
                    (2, 'Daily Wars History'),
                  ]) ...[
                    if (entry.$1 > 0) const SizedBox(width: 8),
                    _HubPill(
                      label: entry.$2,
                      selected: tab.value == entry.$1,
                      onTap: () => tab.value = entry.$1,
                      scheme: scheme,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: tab.value,
                children: const [
                  ProgressScreen(embedded: true),
                  HistoryScreen(embedded: true),
                  DailyWarHistoryScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubPill extends StatelessWidget {
  const _HubPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSm().copyWith(
              color: selected ? Colors.white : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
