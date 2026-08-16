import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/super_user_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/community_bot.dart';
import '../providers/community_providers.dart';

/// "Bot" chip for super-users only. Invisible to everyone else.
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
        ref.watch(trafficBotIndexProvider).asData?.value ?? TrafficBotIndex.empty;
    if (!index.matches(email: email, uid: uid)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          child: Text(
            'Bot',
            style: AppTextStyles.labelSm().copyWith(
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
