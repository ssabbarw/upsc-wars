import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../home/providers/auth_providers.dart';
import '../data/open_challenge_repository.dart';
import '../domain/entities/community_user.dart';
import '../data/qotd_local_post_limit.dart';
import '../providers/community_providers.dart';
import '../providers/qotd_providers.dart';
import '../../../shared/widgets/app_toast.dart';
import 'qotd_post_comment_sheet.dart';

Future<void> showShareQotdSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String questionUuid,
  required String correctOption,
}) async {
  await showQotdPostCommentSheet(
    context,
    onPost: (comment) async {
      final user = ref.read(authStateChangesProvider).asData?.value;
      final email = user?.email?.toLowerCase().trim();
      if (email == null || email.isEmpty) {
        throw Exception('You must be signed in.');
      }
      CommunityUser? extraUser;
      try {
        extraUser = await ref
            .read(communityRepositoryProvider)
            .fetchCommunityUserByEmail(email);
      } catch (_) {}

      final profile = profileFromFirebaseUser(
        emailLower: email,
        displayName: extraUser?.name ?? user?.displayName ?? 'UPSC Warrior',
        photoUrl: extraUser?.photoUrl ?? user?.photoURL,
        telegram: extraUser?.telegram,
        instagram: extraUser?.instagram,
        status: extraUser?.status,
      );

      final prefs = await ref.read(prefsServiceProvider.future);
      final maxPerWindow = await ref.read(qotdMaxPostsPerDayProvider.future);
      QotdLocalPostLimit.assertCanPost(prefs, maxPerWindow);
      await ref.read(qotdRepositoryProvider).createPost(
            questionUuid: questionUuid,
            comment: comment,
            correctOption: correctOption,
            author: profile,
          );
      QotdLocalPostLimit.recordPost(prefs);
      ref.invalidate(qotdFeedNotifierProvider);
      if (context.mounted) {
        AppToast.showText(context, 'Posted to Community QOTD');
      }
    },
  );
}
