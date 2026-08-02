import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';
import '../widgets/daily_war_leaderboard_view.dart';

/// Full-screen “Tonight's war · leaderboard”.
class DailyWarLeaderboardScreen extends ConsumerWidget {
  const DailyWarLeaderboardScreen({super.key, required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(dailyWarArchiveProvider(dateId));
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: DwColors.surface,
      appBar: AppBar(
        backgroundColor: DwColors.surface,
        foregroundColor: DwColors.onDark,
        title: Text(
          'Tonight\'s war · leaderboard',
          style: DwText.dm(size: 16, weight: FontWeight.w700),
        ),
      ),
      body: archiveAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DwColors.crimsonBright),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: DwText.body(color: DwColors.crimsonBright)),
        ),
        data: (archive) {
          final lb = archive.leaderboard;
          if (lb == null || lb.top.isEmpty) {
            return Center(
              child: Text(
                'Leaderboard not ready yet.',
                style: DwText.body(),
              ),
            );
          }
          return DailyWarLeaderboardView(
            lb: lb,
            dateId: dateId,
            myUid: myUid,
            questionCount: archive.war.questionCount,
            mySubmission: archive.submission,
            isGrand: archive.war.isGrand,
          );
        },
      ),
    );
  }
}
