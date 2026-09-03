import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/session_subject_label.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../home/providers/auth_providers.dart';
import '../domain/open_challenge_models.dart';
import '../open_challenge/open_challenge_launch_exam.dart';
import '../providers/open_challenge_providers.dart';
import '../widgets/admin_bot_label.dart';

class OpenChallengeDetailScreen extends ConsumerStatefulWidget {
  const OpenChallengeDetailScreen({
    super.key,
    required this.challengeId,
    this.backToCommunityOpenTab = false,
  });

  final String challengeId;

  /// Back from leaderboard → Community with Open challenge tab (post-accept flow).
  final bool backToCommunityOpenTab;

  @override
  ConsumerState<OpenChallengeDetailScreen> createState() =>
      _OpenChallengeDetailScreenState();
}

class _OpenChallengeDetailScreenState
    extends ConsumerState<OpenChallengeDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.backToCommunityOpenTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.invalidate(openChallengeDetailProvider(widget.challengeId));
      });
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        ref.invalidate(openChallengeDetailProvider(widget.challengeId));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(openChallengeDetailProvider(widget.challengeId));
    final me = ref
        .watch(authStateChangesProvider)
        .asData
        ?.value
        ?.email
        ?.toLowerCase()
        .trim();

    final canPop = context.canPop();
    void leave() {
      if (widget.backToCommunityOpenTab || !canPop) {
        context.go('/community?tab=open_challenge');
        return;
      }
      context.pop();
    }

    return PopScope(
      canPop: canPop && !widget.backToCommunityOpenTab,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        leave();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: leave,
          ),
          title: Text('Challenge', style: AppTextStyles.h3()),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$e', style: AppTextStyles.bodyMd()),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(
                      openChallengeDetailProvider(widget.challengeId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (detail) {
            if (detail == null) {
              return Center(
                child: Text(
                  'Challenge not found',
                  style: AppTextStyles.bodyMd(),
                ),
              );
            }
            if (kDebugMode) {
              final keys = detail.attemptsByEmail.keys.toList()..sort();
              debugPrint(
                '[OpenChallenge:ui] detailScreen id=${widget.challengeId} '
                'me=$me attemptKeys=$keys attemptCount=${detail.attemptsByEmail.length}',
              );
            }
            final creator = detail.creatorEntry();
            final board = detail.leaderboardRows();
            final myEntry = (me != null && me.isNotEmpty)
                ? detail.attemptsByEmail[me]
                : null;
            final myRank = myEntry == null
                ? null
                : board.indexWhere((r) => r.profile.email.toLowerCase() == me);
            final leader = board.isEmpty ? null : board.first;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(openChallengeDetailProvider(widget.challengeId));
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    openChallengeSubjectTitle(detail.subject),
                    style: AppTextStyles.h2(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (creator != null) ...[
                    Row(
                      children: [
                        TappableCircularAvatar(
                          imageUrl: creator.profile.photoUrl,
                          displayName: displayNameForViewer(
                            name: creator.profile.name,
                            viewerEmail: me,
                            subjectEmail: creator.profile.email,
                          ),
                          size: 40,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Created by ${displayNameForViewer(name: creator.profile.name, viewerEmail: me, subjectEmail: creator.profile.email)}',
                                      style: AppTextStyles.label(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AdminBotLabel(email: creator.profile.email),
                                ],
                              ),
                              Text(
                                _relativeCreated(detail.createdAt),
                                style: AppTextStyles.caption().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!detail.isExpired &&
                      detail.effectiveExpiresAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Live till ${DateFormat('d MMM, h:mm a').format(detail.effectiveExpiresAt!.toLocal())}',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (detail.isExpired) ...[
                    Text(
                      'This challenge has expired (challenges last 24 hours).',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else if (myEntry == null) ...[
                    _AcceptChallengeCallout(
                      challengeId: widget.challengeId,
                      subject: detail.subject,
                      questionUuids: detail.questionUuids,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    Text(
                      'Your score: ${myEntry.score} / 10',
                      style: AppTextStyles.label(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (myRank == 0)
                      Text(
                        'You are the winner so far 🏆',
                        style: AppTextStyles.bodyMd().copyWith(
                          color: scheme.primary,
                        ),
                      )
                    else if (leader != null &&
                        leader.profile.email.toLowerCase() != me)
                      Text(
                        '${displayNameForViewer(name: leader.profile.name, viewerEmail: me, subjectEmail: leader.profile.email)} has beaten your score',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (myEntry.reviewSessionId != null &&
                        myEntry.reviewSessionId!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/history/${myEntry.reviewSessionId}'),
                        icon: const Icon(Icons.menu_book_outlined, size: 20),
                        label: const Text('Review explanations'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text('Leaderboard', style: AppTextStyles.label()),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < board.length; i++) ...[
                    _LeaderTile(
                      rank: i + 1,
                      row: board[i],
                      viewerEmail: me,
                      highlight:
                          me != null &&
                          board[i].profile.email.toLowerCase() == me,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AcceptChallengeCallout extends ConsumerStatefulWidget {
  const _AcceptChallengeCallout({
    required this.challengeId,
    required this.subject,
    required this.questionUuids,
  });

  final String challengeId;
  final String subject;
  final List<String> questionUuids;

  @override
  ConsumerState<_AcceptChallengeCallout> createState() =>
      _AcceptChallengeCalloutState();
}

class _AcceptChallengeCalloutState
    extends ConsumerState<_AcceptChallengeCallout> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                final signedIn = await ensureAccountSignedIn(
                  context: context,
                  ref: ref,
                  reason: 'Sign in to accept this challenge.',
                );
                if (!signedIn || !mounted) return;
                await launchOpenChallengeExam(
                  ref,
                  context,
                  OpenChallengeExamArgs.accept(
                    challengeId: widget.challengeId,
                    subject: widget.subject,
                    questionUuids: widget.questionUuids,
                  ),
                );
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      child: _busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            )
          : const Text('Accept Challenge'),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  const _LeaderTile({
    required this.rank,
    required this.row,
    required this.viewerEmail,
    required this.highlight,
  });

  final int rank;
  final OpenChallengeLeaderboardRow row;
  final String? viewerEmail;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nameLabel = displayNameForViewer(
      name: row.profile.name,
      viewerEmail: viewerEmail,
      subjectEmail: row.profile.email,
    );
    return Material(
      color: highlight
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            TappableCircularAvatar(
              imageUrl: row.profile.photoUrl,
              displayName: nameLabel,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nameLabel,
                          style: AppTextStyles.label(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AdminBotLabel(email: row.profile.email),
                    ],
                  ),
                  Text(
                    _attemptedLabel(row.attemptedAt),
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text('${row.score}/10', style: AppTextStyles.label()),
          ],
        ),
      ),
    );
  }
}

String _relativeCreated(DateTime? createdAt) {
  if (createdAt == null) return '';
  final diff = DateTime.now().difference(createdAt);
  if (diff.inSeconds < 60) return 'Created just now';
  if (diff.inMinutes < 60) return 'Created ${diff.inMinutes}m ago';
  if (diff.inHours < 48) return 'Created ${diff.inHours}h ago';
  return 'Created ${diff.inDays}d ago';
}

String _attemptedLabel(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 120) return '${diff.inMinutes}m ago';
  if (diff.inHours < 48) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
