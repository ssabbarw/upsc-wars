import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_result.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/providers/auth_providers.dart';
import '../data/open_challenge_repository.dart';
import '../domain/entities/community_user.dart';
import '../open_challenge/open_challenge_create_availability.dart';
import '../open_challenge/open_challenge_post_eligibility.dart';
import '../providers/community_providers.dart';
import '../providers/open_challenge_providers.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../l10n/l10n.dart';

/// Encourages posting a strong 10-question exam as a community open challenge.
class OpenChallengePostFromResultsCard extends ConsumerStatefulWidget {
  const OpenChallengePostFromResultsCard({
    super.key,
    required this.sessionId,
    required this.result,
  });

  final String sessionId;
  final SessionResult result;

  @override
  ConsumerState<OpenChallengePostFromResultsCard> createState() =>
      _OpenChallengePostFromResultsCardState();
}

class _OpenChallengePostFromResultsCardState
    extends ConsumerState<OpenChallengePostFromResultsCard> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    if (!shouldOfferPostAsOpenChallenge(widget.result)) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final availAsync = ref.watch(openChallengeCreateAvailabilityProvider);
    return availAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => _postCard(context, scheme, allowed: true, avail: null),
      data: (avail) =>
          _postCard(context, scheme, allowed: avail.allowed, avail: avail),
    );
  }

  Widget _postCard(
    BuildContext context,
    ColorScheme scheme, {
    required bool allowed,
    required OpenChallengeCreateAvailability? avail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.ocShareChallenge, style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.ocGreatScore(widget.result.correct),
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (!allowed && avail != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                avail.bodyCopy,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Tooltip(
              message: allowed
                  ? context.l10n.ocPublishCommunity
                  : avail?.tooltipLine ?? context.l10n.ocTempUnavailable,
              child: FilledButton.tonal(
                onPressed: (!allowed || _busy) ? null : _onPost,
                child: Text(
                  _busy
                      ? context.l10n.ocPosting
                      : context.l10n.ocPostAsChallenge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPost() async {
    if (_busy) return;
    final prefs = await ref.read(prefsServiceProvider.future);
    if (!OpenChallengeCreateAvailability.fromPrefs(prefs).allowed) return;
    setState(() => _busy = true);
    final context = this.context;
    try {
      final user = ref.read(authStateChangesProvider).asData?.value;
      final email = user?.email?.toLowerCase().trim();
      if (email == null || email.isEmpty) {
        throw StateError('Sign in to post a challenge.');
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

      final db = ref.read(userDatabaseProvider);
      final repo = ref.read(openChallengeRepositoryProvider);
      await repo.createChallengeFromCompletedSession(
        userDatabase: db,
        sessionId: widget.sessionId,
        creatorEmailKey: email,
        profile: profile,
      );
      await recordOpenChallengePublished(ref);
      ref.invalidate(openChallengesListProvider);
      if (context.mounted) {
        context.go('/community?tab=open_challenge');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showText(context, '$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
