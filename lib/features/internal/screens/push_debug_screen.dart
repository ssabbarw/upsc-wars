import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../memory_pairs/widgets/push_memory_pairs_debug_card.dart';
import '../../mini_games/widgets/push_revision_game_debug_card.dart';
import '../../push_spot_test/widgets/push_spot_test_debug_card.dart';

/// Admin-only tools to simulate push → in-app launch without FCM.
class PushDebugScreen extends StatelessWidget {
  const PushDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push debug')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          PushMemoryPairsDebugCard(),
          SizedBox(height: AppSpacing.sm),
          PushRevisionGameDebugCard(),
          SizedBox(height: AppSpacing.sm),
          PushSpotTestDebugCard(),
        ],
      ),
    );
  }
}
