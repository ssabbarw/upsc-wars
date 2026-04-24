import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/analytics/activation_milestones.dart';
import 'package:upsc_wars/core/analytics/analytics.dart';
import 'package:upsc_wars/core/analytics/analytics_events.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/constants/timed_exam_debug_constants.dart';
import 'package:upsc_wars/core/presentation/session_subject_label.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/data/battle_invite_cloud_service.dart';
import 'package:upsc_wars/features/battle/data/battle_match_firestore_service.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_invite_target.dart';
import 'package:upsc_wars/features/battle/domain/services/battle_name_service.dart';
import 'package:upsc_wars/features/community/providers/community_providers.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';
import 'package:upsc_wars/shared/widgets/test_config_sheet_widgets.dart';

class BattleConfigScreen extends ConsumerStatefulWidget {
  const BattleConfigScreen({super.key, this.invite});

  /// When set, starting the battle primes a human match and notifies [invite].
  final BattleInviteTarget? invite;

  @override
  ConsumerState<BattleConfigScreen> createState() => _BattleConfigScreenState();
}

class _BattleConfigScreenState extends ConsumerState<BattleConfigScreen> {
  String? _selectedSubject;
  bool _submitting = false;

  /// Sentinel for mixed-subject random battles (see [CreateSessionRepositoryImpl]).
  static const _miscSubjectKey = 'misc';

  static const _tileWidth = 108.0;
  static const _tileHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectTestListProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = ref.watch(authStateChangesProvider).asData?.value;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfaceSecondaryDark
          : AppColors.surfaceSecondaryLight,
      appBar: AppBar(
        title: Text('Configure battle', style: AppTextStyles.h3()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ColoredBox(
              color: isDark
                  ? AppColors.surfacePrimaryDark
                  : AppColors.surfacePrimaryLight,
              child: subjectsAsync.when(
                data: (subjects) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pick your battlefield',
                        style: AppTextStyles.h1().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.invite != null
                            ? 'Battle vs ${widget.invite!.displayName} · 10 MCQs · Timed '
                                  '(${(10 * kDebugSecondsPerQuestion / 60).round()} min)'
                            : 'Pick one subject or mixed misc · 10 MCQs · Timed '
                                  '(${(10 * kDebugSecondsPerQuestion / 60).round()} min)',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Subject',
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              SizedBox(
                                width: _tileWidth,
                                height: _tileHeight,
                                child: SubjectPickChipTile(
                                  label: 'Misc',
                                  selected: _selectedSubject == _miscSubjectKey,
                                  onTap: () => setState(
                                    () => _selectedSubject = _miscSubjectKey,
                                  ),
                                  scheme: scheme,
                                  isDark: isDark,
                                ),
                              ),
                              for (final subject in subjects)
                                SizedBox(
                                  width: _tileWidth,
                                  height: _tileHeight,
                                  child: SubjectPickChipTile(
                                    label: subject.displayName,
                                    selected:
                                        _selectedSubject == subject.subject,
                                    onTap: () => setState(
                                      () => _selectedSubject = subject.subject,
                                    ),
                                    scheme: scheme,
                                    isDark: isDark,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Timer runs during the battle. Answers lock in once chosen, with explanations shown so you learn as you go.',
                              style: AppTextStyles.caption().copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text(
                    'Could not load subjects',
                    style: AppTextStyles.body(),
                  ),
                ),
              ),
            ),
          ),
          Material(
            elevation: 8,
            shadowColor: AppColors.gray900.withValues(alpha: 0.08),
            color: isDark
                ? AppColors.surfacePrimaryDark
                : AppColors.surfacePrimaryLight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: _submitting || _selectedSubject == null
                      ? null
                      : () => _startBattle(
                          context,
                          me?.displayName ?? 'You',
                          me?.photoURL,
                        ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(
                          'Start battle',
                          style: AppTextStyles.label().copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBattle(
    BuildContext context,
    String playerName,
    String? playerPhotoUrl,
  ) async {
    final subject = _selectedSubject;
    if (subject == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final me = ref.read(authStateChangesProvider).asData?.value;
      final invite = widget.invite;
      var guestBlockedHost = false;
      if (invite != null) {
        final hostEmail = (me?.email ?? '').toLowerCase().trim();
        if (hostEmail.isEmpty) {
          throw StateError('Sign in required to invite a player');
        }
        final guestEmail = invite.email.toLowerCase().trim();
        final repo = ref.read(communityRepositoryProvider);
        final hostBlockedGuest = await repo.isUserBlocked(
          ownerEmail: hostEmail,
          otherEmail: guestEmail,
        );
        guestBlockedHost = await repo.isUserBlocked(
          ownerEmail: guestEmail,
          otherEmail: hostEmail,
        );
        if (hostBlockedGuest) {
          if (context.mounted) {
            AppToast.showText(
              context,
              'Unblock this player in Community before inviting them.',
            );
          }
          return;
        }
      }

      final uc = await ref.read(createSessionUseCaseProvider.future);
      final language = await ref.read(appLanguageProvider.future);
      final config = SessionConfig(
        subject: subject,
        mode: 'exam',
        questionCount: 10,
        isTimed: true,
        timeLimitSecs: 10 * kDebugSecondsPerQuestion,
        language: language,
        analyticsFeatureKey: 'mcq_battle',
      );
      final sessionId = await uc.execute(config);
      final opponentName = invite != null
          ? invite.displayName
          : BattleNameService.pickFromSeed(sessionId);

      if (invite != null) {
        final load = await ref.read(loadSessionUseCaseProvider.future);
        final active = await load.execute(sessionId);
        final uuids = active.questions.map((q) => q.uuid).toList();
        final hostEmail = (me?.email ?? '').toLowerCase().trim();
        if (hostEmail.isEmpty) {
          throw StateError('Sign in required to invite a player');
        }
        const matchSvc = BattleMatchFirestoreService();
        await matchSvc.primeHumanMatch(
          sessionId: sessionId,
          questionUuids: uuids,
          hostEmail: hostEmail,
          hostDisplayName: playerName,
          hostPhotoUrl: playerPhotoUrl?.trim(),
          guestEmail: invite.email,
          guestDisplayName: invite.displayName,
          subject: subject,
        );
        if (!context.mounted) return;
        if (guestBlockedHost) {
          unawaited(
            Analytics.track(
              ref,
              const BattleInviteOutcomeEvent(kind: 'blocked'),
            ),
          );
        } else {
          const cloud = BattleInviteCloudService();
          final inviteOutcome = await cloud.sendBattleInvite(
            guestEmail: invite.email,
            sessionId: sessionId,
            hostDisplayName: playerName,
            subjectLabel: displayNameForSessionSubject(subject),
          );
          unawaited(
            Analytics.track(
              ref,
              BattleInviteOutcomeEvent(kind: inviteOutcome.analyticsKind),
            ),
          );
          if (inviteOutcome.analyticsKind == 'push_ok') {
            unawaited(
              logActivationMilestoneOnce(
                ref,
                ActivationMilestones.firstBattleInvitePushOk,
              ),
            );
          }
          if (!context.mounted) return;
          final serverSaysBlocked =
              !inviteOutcome.notificationSent &&
              inviteOutcome.serverReason == 'blocked';
          if (!serverSaysBlocked) {
            AppToast.showText(context, inviteOutcome.userFacingMessage);
          }
        }
      }

      if (!context.mounted) return;
      final photo = playerPhotoUrl?.trim();
      final opponentPhoto = invite?.photoUrl?.trim();
      context.push(
        '/battle/wait/$sessionId',
        extra: {
          'playerName': playerName,
          'opponentName': opponentName,
          if (photo != null && photo.isNotEmpty) 'playerPhotoUrl': photo,
          if (opponentPhoto != null && opponentPhoto.isNotEmpty)
            'opponentPhotoUrl': opponentPhoto,
        },
      );
    } on FirebaseException catch (e, st) {
      debugPrint('Battle start FirebaseException: ${e.code} ${e.message}');
      debugPrintStack(stackTrace: st);
      if (context.mounted) {
        final msg = switch (e.code) {
          'permission-denied' =>
            'Could not save the battle room. Sign in and try again, or check Firestore rules.',
          'unavailable' =>
            'Firestore is temporarily unavailable. Check your connection and try again.',
          _ => e.message ?? 'Battle setup failed (${e.code}).',
        };
        AppToast.showText(context, msg);
      }
    } on TimeoutException catch (e, st) {
      debugPrint('Battle start timed out: $e');
      debugPrintStack(stackTrace: st);
      if (context.mounted) {
        AppToast.showText(
          context,
          'Saving the battle timed out. Check your internet connection and try again.',
        );
      }
    } catch (e, st) {
      debugPrint('Battle start: $e');
      debugPrintStack(stackTrace: st);
      if (context.mounted) {
        AppToast.showText(context, '$e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
