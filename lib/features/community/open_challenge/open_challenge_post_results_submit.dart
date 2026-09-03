import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../shared/auth/ensure_account_sign_in.dart';

import '../../../core/domain/entities/session_result.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/providers/auth_providers.dart';
import '../data/open_challenge_repository.dart';
import '../domain/entities/community_user.dart';
import '../open_challenge/open_challenge_create_availability.dart';
import '../open_challenge/open_challenge_exam_context.dart';
import '../open_challenge/open_challenge_exam_registry.dart';
import '../providers/community_providers.dart';
import '../providers/open_challenge_providers.dart';
import '../../../shared/widgets/app_toast.dart';

/// Thrown when [performOpenChallengePostResultsPublish] blocks create (24h local cooldown).
final class OpenChallengePublishCooldownException implements Exception {
  OpenChallengePublishCooldownException(this.bodyCopy);
  final String bodyCopy;
}

/// Firestore publish / save-after-exam for open-challenge create or accept flows.
Future<void> performOpenChallengePostResultsPublish({
  required WidgetRef ref,
  required BuildContext context,
  required String sessionId,
  required SessionResult result,
}) async {
  final ctx = ref.read(openChallengeExamRegistryProvider).peek(sessionId);
  if (ctx == null) {
    throw StateError('Missing open challenge context.');
  }

  if (ctx.kind == OpenChallengeExamKind.create) {
    final prefs = await ref.read(prefsServiceProvider.future);
    final avail = OpenChallengeCreateAvailability.fromPrefs(prefs);
    if (!avail.allowed) {
      throw OpenChallengePublishCooldownException(avail.bodyCopy);
    }
  }

  // Guests take the exam without an account; the leaderboard is keyed by email,
  // so sign-in is asked for here — after they have seen the value, not before.
  if (!context.mounted) {
    throw StateError('Publish cancelled.');
  }
  final signedIn = await ensureAccountSignedIn(
    context: context,
    ref: ref,
    reason: 'Sign in to save your score to the leaderboard.',
  );
  if (!signedIn) {
    throw StateError('You must be signed in.');
  }

  // The auth stream may not have emitted yet right after a fresh sign-in.
  final user =
      FirebaseAuth.instance.currentUser ??
      ref.read(authStateChangesProvider).asData?.value;
  final email = user?.email?.toLowerCase().trim();
  if (email == null || email.isEmpty) {
    throw StateError('You must be signed in.');
  }

  final db = ref.read(userDatabaseProvider);
  final rows = await db.sessionQuestionsDao.getSessionQuestionsOrdered(sessionId);
  final attempts = <String, String>{};
  for (final r in rows) {
    final o = r.selectedOption?.trim().toLowerCase();
    if (o != null && o.isNotEmpty) {
      attempts[r.questionUuid] = o;
    }
  }
  final score = result.correct;

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

  if (kDebugMode) {
    debugPrint(
      '[OpenChallenge:publish] kind=${ctx.kind} sessionId=$sessionId '
      'email=$email score=$score answerMapSize=${attempts.length} '
      'profile.name=${profile.name}',
    );
  }

  final repo = ref.read(openChallengeRepositoryProvider);
  if (ctx.kind == OpenChallengeExamKind.create) {
    await repo.createChallengeDocument(
      creatorEmailKey: email,
      questionUuids: ctx.questionUuids,
      subject: ctx.subjectDisplay,
      profile: profile,
      attemptsByQuestionUuid: attempts,
      score: score,
      reviewSessionId: sessionId,
    );
    await recordOpenChallengePublished(ref);
    ref.read(openChallengeExamRegistryProvider).take(sessionId);
    ref.invalidate(openChallengesListProvider);
    ref.invalidate(homeOpenChallengesProvider);
    if (context.mounted) {
      context.go('/community?tab=open_challenge');
    }
  } else {
    final cid = ctx.existingChallengeId;
    if (cid == null || cid.isEmpty) {
      throw StateError('Missing challenge id.');
    }
    if (kDebugMode) {
      debugPrint(
        '[OpenChallenge:publish] accept BEFORE addAttempt challengeId=$cid '
        'participantEmailKey=$email',
      );
    }
    await repo.addAttemptTransaction(
      challengeId: cid,
      participantEmailKey: email,
      profile: profile,
      attemptsByQuestionUuid: attempts,
      score: score,
      reviewSessionId: sessionId,
    );
    if (kDebugMode) {
      debugPrint(
        '[OpenChallenge:publish] accept AFTER addAttempt challengeId=$cid '
        'invalidating detail provider',
      );
    }
    ref.read(openChallengeExamRegistryProvider).take(sessionId);
    ref.invalidate(openChallengesListProvider);
    ref.invalidate(homeOpenChallengesProvider);
    ref.invalidate(openChallengeDetailProvider(cid));
    if (context.mounted) {
      context.go(
        '/community/open-challenges/$cid?origin=accept_flow',
      );
    }
  }
}

/// Full-screen loader + publish for accept flow (replaces normal results UI).
class OpenChallengeAcceptResultsShell extends ConsumerStatefulWidget {
  const OpenChallengeAcceptResultsShell({
    super.key,
    required this.sessionId,
    required this.result,
  });

  final String sessionId;
  final SessionResult result;

  @override
  ConsumerState<OpenChallengeAcceptResultsShell> createState() =>
      _OpenChallengeAcceptResultsShellState();
}

class _OpenChallengeAcceptResultsShellState
    extends ConsumerState<OpenChallengeAcceptResultsShell> {
  var _submitting = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      await performOpenChallengePostResultsPublish(
        ref: ref,
        context: context,
        sessionId: widget.sessionId,
        result: widget.result,
      );
    } catch (e) {
      if (mounted) {
        final msg = '$e'.contains('already_attempted')
            ? 'You have already attempted this challenge.'
            : '$e'.contains('challenge_expired')
                ? 'This challenge has expired.'
                : '$e'.contains('must be signed in')
                    ? 'Sign in to save your score to the leaderboard.'
                    : '$e';
        AppToast.showText(context, msg);
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_failed) {
      return ColoredBox(
        color: scheme.surface,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not save your score',
                    style: AppTextStyles.h3(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Check your connection and try again.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            setState(() => _failed = false);
                            unawaited(_run());
                          },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Publishing your score',
                  style: AppTextStyles.h2().copyWith(
                    color: scheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Locking your answers onto the leaderboard — almost there.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
