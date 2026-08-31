import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/open_challenge_repository.dart';
import '../data/qotd_local_post_limit.dart';
import '../domain/entities/community_user.dart';
import '../providers/community_providers.dart';
import '../providers/qotd_providers.dart';
import 'qotd_post_comment_sheet.dart';
import 'qotd_what_is_sheet.dart';

/// First-time QOTD explainer, then the comment sheet.
///
/// Unsigned users can draft a comment, sign in, and return to the same sheet
/// with that text still filled in.
///
/// Returns `true` if a post was created.
Future<bool> showShareQotdSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String questionUuid,
  required String correctOption,
}) async {
  await maybeShowQotdWhatIsIntro(context: context, ref: ref);
  if (!context.mounted) return false;

  var draft = '';
  while (true) {
    if (!context.mounted) return false;
    final result = await showQotdPostCommentSheet(
      context,
      initialComment: draft,
      onPost: (comment) => _createQotdPost(
        ref: ref,
        questionUuid: questionUuid,
        correctOption: correctOption,
        comment: comment,
      ),
    );
    if (!context.mounted) return false;
    if (result.posted) {
      AppToast.showText(context, 'Posted to Community QOTD');
      unawaited(
        logActivationMilestoneOnce(ref, ActivationMilestones.firstQotdPosted),
      );
      return true;
    }
    if (!result.needsSignIn) return false;

    draft = result.comment;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!context.mounted) return false;

    final signedIn = await ensureAccountSignedIn(
      context: context,
      ref: ref,
      reason: 'Sign in to post to QOTD.',
    );
    if (!context.mounted) return false;
    if (!signedIn) {
      // Keep the draft; reopen so they can try again or dismiss.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      continue;
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
}

Future<void> _createQotdPost({
  required WidgetRef ref,
  required String questionUuid,
  required String correctOption,
  required String comment,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final email = AuthSession.emailOf(user);
  if (email == null || email.isEmpty) {
    throw Exception('Sign in to post to QOTD.');
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
}
