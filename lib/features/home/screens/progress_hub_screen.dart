import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../../history/screens/history_screen.dart';
import '../providers/today_hub_provider.dart';
import 'progress_screen.dart';

/// Shell tab that hosts Progress and Test History.
class ProgressHubScreen extends HookConsumerWidget {
  const ProgressHubScreen({super.key, this.initialTabIndex = 0});

  /// 0 = Progress, 1 = Test History.
  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTabController(
      initialLength: 2,
      initialIndex: initialTabIndex.clamp(0, 1),
    );
    useListenable(controller);
    final scheme = Theme.of(context).colorScheme;

    final hub = ref.watch(todayHubProvider);
    final fullDays = hub.fullDaysThisWeek;

    return PopToShellHomeScope(
      onInnerBack: () {
        if (controller.index == 0) return false;
        controller.animateTo(0);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Progress', style: AppTextStyles.h3()),
          bottom: fullDays > 0
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(32),
                  child: _WeekSummaryBanner(fullDays: fullDays),
                )
              : null,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: scheme.surface,
              child: TabBar(
                controller: controller,
                isScrollable: false,
                labelColor: AppColors.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                unselectedLabelStyle: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                tabs: const [
                  Tab(text: 'Progress', height: 40),
                  Tab(text: 'Test History', height: 40),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: controller.index,
                children: const [
                  ProgressScreen(embedded: true),
                  HistoryScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekSummaryBanner extends StatelessWidget {
  const _WeekSummaryBanner({required this.fullDays});

  final int fullDays;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
    final fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
    final label = fullDays == 7
        ? 'Perfect week — all 7 days sealed 🔥'
        : '$fullDays of 7 days sealed this week';

    return Container(
      width: double.infinity,
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
