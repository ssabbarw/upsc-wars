import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../../home/providers/auth_providers.dart';
import '../providers/daily_ca_providers.dart';
import '../widgets/daily_ca_leaderboard_view.dart';
import '../../../l10n/l10n.dart';

class DailyCaLeaderboardScreen extends ConsumerWidget {
  const DailyCaLeaderboardScreen({super.key, required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final accountSignedIn = AuthSession.isAccountSignedIn(user);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Paper ranks',
          style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: accountSignedIn
          ? _SignedInRanksBody(dateId: dateId)
          : _SignInForRanksBody(
              onSignedIn: () {
                ref.invalidate(dailyCaLeaderboardProvider(dateId));
                ref.invalidate(dailyCaMySubmissionProvider(dateId));
              },
            ),
    );
  }
}

class _SignInForRanksBody extends ConsumerWidget {
  const _SignInForRanksBody({required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.dcaSignInLeaderboard,
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () async {
                final ok = await ensureAccountSignedIn(
                  context: context,
                  ref: ref,
                  reason: context.l10n.dcaSignInLeaderboard,
                );
                if (!ok || !context.mounted) return;
                onSignedIn();
              },
              child: Text(context.l10n.cpSignIn),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInRanksBody extends ConsumerWidget {
  const _SignedInRanksBody({required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(dailyCaLeaderboardProvider(dateId));
    final mineAsync = ref.watch(dailyCaMySubmissionProvider(dateId));
    final myUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';
    final scheme = Theme.of(context).colorScheme;

    Future<void> refresh() async {
      ref.invalidate(dailyCaLeaderboardProvider(dateId));
      ref.invalidate(dailyCaMySubmissionProvider(dateId));
      await Future.wait([
        ref.read(dailyCaLeaderboardProvider(dateId).future),
        ref.read(dailyCaMySubmissionProvider(dateId).future),
      ]);
    }

    return lbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          '$e',
          style: AppTextStyles.bodySm().copyWith(color: AppColors.wrong),
        ),
      ),
      data: (lb) {
        if (lb == null || lb.top.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.dcaNoRanks,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: DailyCaLeaderboardView(
            lb: lb,
            dateId: dateId,
            myUid: myUid,
            questionCount: lb.questionCount,
            mySubmission: mineAsync.asData?.value,
            isFrozen: lb.isFrozen,
          ),
        );
      },
    );
  }
}
