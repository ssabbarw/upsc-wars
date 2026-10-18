import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../providers/user_block_providers.dart';
import '../widgets/admin_bot_label.dart';
import '../../../l10n/l10n.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final emailsAsync = ref.watch(blockedUserEmailsProvider);
    final profilesAsync = ref.watch(blockedUserProfilesProvider);
    final profiles = profilesAsync.value ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: emailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(blockedUserEmailsProvider),
            child: Text(context.l10n.commonRetry),
          ),
        ),
        data: (emails) {
          if (emails.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.blockedNone,
                      style: AppTextStyles.h3(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.blockedNote,
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (profilesAsync.isLoading && !profilesAsync.hasValue) {
            return const Center(child: CircularProgressIndicator());
          }

          final sorted = emails.toList()..sort();
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final email = sorted[index];
              final user = profiles[email];
              final name = (user?.name.trim().isNotEmpty ?? false)
                  ? user!.name.trim()
                  : 'UPSC Warrior';
              return Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      TappableCircularAvatar(
                        imageUrl: user?.photoUrl,
                        displayName: name,
                        size: 42,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: AppTextStyles.label(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AdminBotLabel(email: email),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: () => _unblock(context, ref, email, name),
                        child: Text(context.l10n.blockedUnblock),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    String email,
    String name,
  ) async {
    HapticFeedback.selectionClick();
    try {
      await ref
          .read(blockedUserEmailsProvider.notifier)
          .setBlocked(otherEmail: email, blocked: false);
      if (context.mounted) {
        AppToast.showText(context, context.l10n.blockedUnblocked(name));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showText(
          context,
          context.l10n.blockedUnblockFailed(e.toString()),
        );
      }
    }
  }
}
