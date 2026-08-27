import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/daily_ca_providers.dart';
import '../widgets/daily_ca_leaderboard_view.dart';

class DailyCaLeaderboardScreen extends ConsumerWidget {
  const DailyCaLeaderboardScreen({super.key, required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(dailyCaLeaderboardProvider(dateId));
    final mineAsync = ref.watch(dailyCaMySubmissionProvider(dateId));
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final scheme = Theme.of(context).colorScheme;

    Future<void> refresh() async {
      ref.invalidate(dailyCaLeaderboardProvider(dateId));
      ref.invalidate(dailyCaMySubmissionProvider(dateId));
      await Future.wait([
        ref.read(dailyCaLeaderboardProvider(dateId).future),
        ref.read(dailyCaMySubmissionProvider(dateId).future),
      ]);
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Paper ranks',
          style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: lbAsync.when(
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
                      'No ranks yet. Be the first to finish today\'s paper.',
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
      ),
    );
  }
}
