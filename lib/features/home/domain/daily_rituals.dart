import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../daily_war/domain/daily_war_copy.dart';

/// The three daily current-affairs / live-test rituals on Home.
abstract final class DailyRitualIds {
  static const caShots = 'ca_shots';
  static const dailyCa = 'daily_ca';
  static const dailyWar = 'daily_war';

  static const all = {caShots, dailyCa, dailyWar};
}

class DailyRitualCopy {
  const DailyRitualCopy({
    required this.id,
    required this.title,
    required this.when,
    required this.body,
    required this.route,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String title;
  final String when;
  final String body;
  final String route;
  final IconData icon;
  final Color accent;
}

/// Shared titles / routes for the intro sheet and Home NEW badges.
abstract final class DailyRituals {
  static const items = <DailyRitualCopy>[
    DailyRitualCopy(
      id: DailyRitualIds.caShots,
      title: 'CA Shots',
      when: 'Through the day',
      body: 'Breaking news brief + 1 MCQ. Two minutes when a shot lands.',
      route: '/ca-shot',
      icon: Icons.bolt_rounded,
      accent: AppColors.primary,
    ),
    DailyRitualCopy(
      id: DailyRitualIds.dailyCa,
      title: 'Daily Current Affairs Test',
      when: 'Opens 6 AM',
      body: "Yesterday's news as a scored paper. Revise any past day.",
      route: '/daily-ca',
      icon: Icons.article_outlined,
      accent: AppColors.info,
    ),
    DailyRitualCopy(
      id: DailyRitualIds.dailyWar,
      title: DailyWarCopy.dailyEventName,
      when: '9 PM · Mon–Fri',
      body: 'All-India live static GS paper. Same questions, then the rank.',
      route: '/daily-war',
      icon: Icons.shield_outlined,
      accent: AppColors.wrong,
    ),
  ];

  /// Rituals whose Remote Config flags are on (`ca_shots_enabled`,
  /// `daily_ca_enabled`, `daily_war_enabled`).
  static List<DailyRitualCopy> enabledItems({
    required bool caShotsEnabled,
    required bool dailyCaEnabled,
    required bool dailyWarEnabled,
  }) {
    return [
      if (caShotsEnabled)
        items.firstWhere((r) => r.id == DailyRitualIds.caShots),
      if (dailyCaEnabled)
        items.firstWhere((r) => r.id == DailyRitualIds.dailyCa),
      if (dailyWarEnabled)
        items.firstWhere((r) => r.id == DailyRitualIds.dailyWar),
    ];
  }

  /// First-run intro: after onboarding, once, unless every **enabled** ritual
  /// was already opened. Hidden when [enabledIds] is empty.
  static bool shouldShowIntro({
    required bool onboardingSeen,
    required bool introSeen,
    required Set<String> openedIds,
    Set<String> enabledIds = DailyRitualIds.all,
  }) {
    if (!onboardingSeen || introSeen) return false;
    if (enabledIds.isEmpty) return false;
    return !enabledIds.every(openedIds.contains);
  }
}

final dailyRitualsOpenedProvider = FutureProvider<Set<String>>((ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  return prefs.dailyRitualsOpenedIds;
});

Future<void> markDailyRitualOpened(WidgetRef ref, String id) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (!prefs.markDailyRitualOpened(id)) return;
  ref.invalidate(dailyRitualsOpenedProvider);
}
