import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
    final controller = useTabController(
      initialLength: 3,
      initialIndex: initialTabIndex.clamp(0, 2),
    );
    useListenable(controller);
    final scheme = Theme.of(context).colorScheme;

    return PopToShellHomeScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Progress', style: AppTextStyles.h3()),
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
                  Tab(text: 'Daily Wars History', height: 40),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: controller.index,
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
