import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../../history/screens/history_screen.dart';
import 'progress_screen.dart';

/// Shell tab that hosts Progress and History as in-screen tabs.
class ProgressHubScreen extends HookConsumerWidget {
  const ProgressHubScreen({super.key, this.initialTabIndex = 0});

  /// 0 = Progress, 1 = History.
  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeIndex = initialTabIndex.clamp(0, 1);
    final tabController = useTabController(
      initialLength: 2,
      initialIndex: safeIndex,
    );

    return PopToShellHomeScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Progress', style: AppTextStyles.h3()),
          bottom: TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Progress'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: const [
            ProgressScreen(embedded: true),
            HistoryScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
