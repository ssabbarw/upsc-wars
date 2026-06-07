import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/extensions/context_extensions.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../home/providers/auth_providers.dart';
import '../domain/entities/community_user.dart';
import '../domain/qotd_models.dart';
import '../providers/community_providers.dart';
import '../providers/qotd_providers.dart';
import 'community_user_profile_sheet.dart';

Future<void> showQotdAnswerersBottomSheet(
  BuildContext parentContext,
  WidgetRef ref, {
  required String postId,
  required String statsLine,
}) async {
  await showModalBottomSheet<void>(
    context: parentContext,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.52,
        minChildSize: 0.32,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
          return Padding(
            padding: EdgeInsets.only(bottom: systemBottomInset(ctx)),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Who answered', style: AppTextStyles.h3()),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      statsLine,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (c, ref, _) {
                    final async = ref.watch(qotdPostAttemptsProvider(postId));
                    return async.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, err) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Could not load attempts.',
                            style: AppTextStyles.bodySm().copyWith(
                              color: scheme.error,
                            ),
                          ),
                        ),
                      ),
                      data: (rows) {
                        if (rows.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                'No attempts yet.',
                                style: AppTextStyles.bodySm().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          itemBuilder: (context, i) {
                            return _QotdAnswererRow(
                              entry: rows[i],
                              onOpenProfile: (e) async {
                                Navigator.of(parentContext).pop();
                                await _openAnswererProfile(
                                  parentContext,
                                  ref,
                                  e,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            ),
          );
        },
      );
    },
  );
}

class _QotdAnswererRow extends StatelessWidget {
  const _QotdAnswererRow({required this.entry, required this.onOpenProfile});

  final QotdAttemptEntry entry;
  final Future<void> Function(QotdAttemptEntry e) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final rawName = (entry.authorName ?? '').trim().isEmpty
        ? 'UPSC Warrior'
        : entry.authorName!.trim();
    final viewer = FirebaseAuth.instance.currentUser;
    final name = displayNameForViewer(
      name: rawName,
      viewerUid: viewer?.uid,
      subjectUid: entry.uid,
      viewerEmail: viewer?.email,
      subjectEmail: entry.authorEmail,
    );
    final border = entry.isCorrect
        ? (isDark ? AppColors.correct : AppColors.correct)
        : (isDark ? AppColors.wrong : AppColors.wrong);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await onOpenProfile(entry);
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              TappableCircularAvatar(
                imageUrl: AppConstants.profileImageUrlOrDefault(
                  entry.authorPhotoUrl,
                ),
                displayName: name,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      entry.isCorrect ? 'Correct' : 'Wrong',
                      style: AppTextStyles.caption().copyWith(
                        color: entry.isCorrect
                            ? (isDark
                                  ? AppColors.correctTextDark
                                  : AppColors.correctText)
                            : (isDark
                                  ? AppColors.wrongTextDark
                                  : AppColors.wrongText),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: border, width: 1.5),
                  color: entry.isCorrect
                      ? (isDark
                            ? AppColors.correctBgDark.withValues(alpha: 0.35)
                            : AppColors.correctBg.withValues(alpha: 0.45))
                      : (isDark
                            ? AppColors.wrongBgDark.withValues(alpha: 0.35)
                            : AppColors.wrongBg.withValues(alpha: 0.45)),
                ),
                child: Text(
                  entry.pickedOption,
                  style: AppTextStyles.label().copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

CommunityUser _fallbackUser(QotdAttemptEntry e) {
  final email = (e.authorEmail ?? '').trim().toLowerCase();
  return CommunityUser(
    email: email,
    name: (e.authorName ?? '').trim().isEmpty
        ? 'UPSC Warrior'
        : e.authorName!.trim(),
    photoUrl: AppConstants.profileImageUrlOrDefault(e.authorPhotoUrl),
    lastOnlineTime: 0,
    acceptingBattleInvites: true,
    isInBattleTill: null,
    appVersion: null,
    telegram: null,
    instagram: null,
    optionalContact: null,
    status: null,
    openChallengeTimestamp: null,
    openChallengeSubject: null,
  );
}

Future<void> _openAnswererProfile(
  BuildContext context,
  WidgetRef ref,
  QotdAttemptEntry e,
) async {
  final email = (e.authorEmail ?? '').trim().toLowerCase();
  if (email.isEmpty) {
    if (context.mounted) {
      AppToast.showText(context, 'Profile is not available for this attempt yet.');
    }
    return;
  }
  CommunityUser user = _fallbackUser(e);
  try {
    final fresh = await ref
        .read(communityRepositoryProvider)
        .fetchCommunityUserByEmail(email);
    if (fresh != null) user = fresh;
  } catch (_) {}
  if (!context.mounted) return;
  final me = ref.read(authStateChangesProvider).asData?.value?.email;
  await showCommunityUserProfileSheet(context, ref, user, currentUserEmail: me);
}
