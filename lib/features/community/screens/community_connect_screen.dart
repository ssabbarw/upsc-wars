import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../battle/domain/entities/battle_invite_target.dart';
import '../domain/entities/community_user.dart';

class CommunityConnectScreen extends StatelessWidget {
  const CommunityConnectScreen({super.key, this.selectedUser});

  final Object? selectedUser;

  @override
  Widget build(BuildContext context) {
    final user = selectedUser is CommunityUser
        ? selectedUser as CommunityUser
        : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Connect')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user == null
                  ? 'Start a random battle connect.'
                  : 'Challenge ${user.name} in a battle.',
              style: AppTextStyles.bodyMd(),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    () => context.push(
                      '/battle/config',
                      extra:
                          user == null
                              ? null
                              : BattleInviteTarget(
                                email: user.email.toLowerCase(),
                                displayName: user.name,
                                photoUrl:
                                    user.photoUrl.trim().isEmpty
                                        ? null
                                        : user.photoUrl,
                              ),
                    ),
                child: Text(
                  user == null ? 'Random Connect' : 'Start Challenge',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You will briefly see joined players, then battle auto-starts.',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
      ),
    );
  }
}
