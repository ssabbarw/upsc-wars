import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/constants/timed_exam_debug_constants.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/battle/data/battle_invite_cloud_service.dart';
import 'package:upsc_wars/features/battle/data/battle_match_firestore_service.dart';
import 'package:upsc_wars/features/battle/domain/entities/battle_invite_target.dart';
import 'package:upsc_wars/features/battle/domain/services/battle_name_service.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

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
        title: const Text('Configure battle'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
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
                            : 'One subject · 10 MCQs · Timed '
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
                                  for (final subject in subjects)
                                    SizedBox(
                                      width: _tileWidth,
                                      height: _tileHeight,
                                      child: _SubjectPickTile(
                                        label: subject.displayName,
                                        selected:
                                            _selectedSubject ==
                                            subject.subject,
                                        onTap:
                                            () => setState(
                                              () => _selectedSubject =
                                                  subject.subject,
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
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (e, st) => Center(
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
                  onPressed:
                      _submitting || _selectedSubject == null
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
                  child:
                      _submitting
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
      final invite = widget.invite;
      final opponentName =
          invite != null
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
        const cloud = BattleInviteCloudService();
        final inviteOutcome = await cloud.sendBattleInvite(
          guestEmail: invite.email,
          sessionId: sessionId,
          hostDisplayName: playerName,
          subjectLabel: subject,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(inviteOutcome.userFacingMessage)),
        );
      }

      if (!context.mounted) return;
      final photo = playerPhotoUrl?.trim();
      final opponentPhoto = invite?.photoUrl?.trim();
      context.go(
        '/battle/wait/$sessionId',
        extra: {
          'playerName': playerName,
          'opponentName': opponentName,
          if (photo != null && photo.isNotEmpty) 'playerPhotoUrl': photo,
          if (opponentPhoto != null && opponentPhoto.isNotEmpty)
            'opponentPhotoUrl': opponentPhoto,
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SubjectPickTile extends StatelessWidget {
  const _SubjectPickTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fill =
        selected
            ? (isDark
                ? AppColors.primaryDeep.withValues(alpha: 0.45)
                : AppColors.primaryLight)
            : scheme.surface;
    final border =
        selected
            ? AppColors.primary
            : (isDark ? AppColors.borderDark : AppColors.borderLight);
    final borderW = selected ? 2.0 : 1.0;

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 108,
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: borderW),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm().copyWith(
              color: selected
                  ? (isDark ? AppColors.onPrimary : AppColors.primaryDeep)
                  : scheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
