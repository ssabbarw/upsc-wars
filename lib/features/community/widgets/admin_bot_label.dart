import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/super_user_provider.dart';
import '../domain/community_bot.dart';
import '../providers/community_providers.dart';

/// Quiet admin-only mark. Invisible to everyone else.
///
/// A 5px outline dot plus a "Bot" tooltip — readable if you know to look,
/// not a labelled chip.
class AdminBotLabel extends ConsumerWidget {
  const AdminBotLabel({super.key, this.email, this.uid});

  final String? email;
  final String? uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isSuperUserProvider)) {
      return const SizedBox.shrink();
    }
    final index =
        ref.watch(trafficBotIndexProvider).asData?.value ??
        TrafficBotIndex.empty;
    if (!index.matches(email: email, uid: uid)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Bot',
      waitDuration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: SizedBox(
          width: 12,
          height: 12,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 5, height: 5),
            ),
          ),
        ),
      ),
    );
  }
}
