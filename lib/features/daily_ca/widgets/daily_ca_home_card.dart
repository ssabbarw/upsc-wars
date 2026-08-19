import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/battle_messaging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/widgets/today_loop_card.dart';
import '../domain/daily_ca_schedule.dart';
import 'daily_ca_unavailable_sheet.dart';

/// Newspaper quiz on home — hero, tile, or banner depending on the Today hub.
class DailyCaHomeCard extends HookConsumerWidget {
  const DailyCaHomeCard({
    super.key,
    required this.paperDate,
    required this.isTodaysPaper,
    required this.completed,
    required this.questionCount,
    required this.onStart,
    this.questionsReady = true,
    this.loading = false,
    this.emphasized = false,
    this.layout = TodayLoopLayout.hero,
  });

  final DateTime? paperDate;
  final bool isTodaysPaper;
  final bool completed;
  final int questionCount;
  final VoidCallback? onStart;

  /// False when the clock says a paper is open but Firestore has no questions.
  final bool questionsReady;
  final bool loading;

  /// Time-of-day hero — kept for call sites; [layout] owns the paint.
  final bool emphasized;
  final TodayLoopLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.infoTextDark : AppColors.infoText;
    final background = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final date = paperDate;

    // Whether we should offer the notify-me primer in the footer.
    // Only relevant on hero layout when the paper is not yet live.
    final notifyPrimerVisible = useState(false);
    final primerLoading = useState(false);

    final notPaperLiveYet =
        layout == TodayLoopLayout.hero && !kIsWeb && !questionsReady && !completed;

    useEffect(() {
      if (!notPaperLiveYet) {
        // Paper became live (or layout changed) — hide primer immediately.
        notifyPrimerVisible.value = false;
        return null;
      }
      var cancelled = false;
      BattleMessagingService.notificationsAreEnabled().then((enabled) {
        if (!cancelled) notifyPrimerVisible.value = !enabled;
      });
      return () => cancelled = true;
    }, [notPaperLiveYet]);

    final String title;
    final String subtitle;
    final String cta;
    if (date == null) {
      title = 'Paper quiz';
      subtitle = 'Opens at 6 AM — yesterday\'s news, today\'s questions.';
      cta = 'Soon';
    } else if (!questionsReady) {
      title = isTodaysPaper
          ? "Today's paper"
          : '${DateFormat('d MMM').format(date)} paper';
      subtitle = layout == TodayLoopLayout.tile
          ? 'Not live yet'
          : 'Questions are being prepared. Check back shortly.';
      cta = 'Soon';
    } else if (completed) {
      title = isTodaysPaper
          ? "Today's paper"
          : '${DateFormat('d MMM').format(date)} paper';
      subtitle = layout == TodayLoopLayout.tile
          ? 'Quiz done'
          : 'Quiz done. Open the explanations if a line still nags.';
      cta = layout == TodayLoopLayout.hero ? 'Open answers' : 'Answers';
    } else {
      title = isTodaysPaper
          ? "Today's paper"
          : '${DateFormat('d MMM').format(date)} paper';
      subtitle = layout == TodayLoopLayout.tile
          ? 'Yesterday\'s news, $questionCount Q'
          : '$questionCount-question test on yesterday\'s news.';
      cta = layout == TodayLoopLayout.hero ? 'Start the quiz' : 'Start';
    }

    Widget? footer;
    if (layout == TodayLoopLayout.hero) {
      if (notifyPrimerVisible.value) {
        footer = _NotifyMePrimer(
          accent: accent,
          loading: primerLoading.value,
          onTap: () async {
            if (primerLoading.value) return;
            primerLoading.value = true;
            try {
              await BattleMessagingService.requestPushAuthorizationIfNotDetermined(
                source: 'ca_card_not_live',
              );
              notifyPrimerVisible.value = false;
            } finally {
              primerLoading.value = false;
            }
          },
        );
      } else {
        footer = GestureDetector(
          onTap: () => context.push('/daily-ca'),
          child: Text(
            'All papers',
            style: AppTextStyles.labelSm().copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }

    return TodayLoopCard(
      layout: layout,
      eyebrow: 'CURRENT',
      title: title,
      subtitle: subtitle,
      cta: cta,
      icon: Icons.newspaper_rounded,
      accent: accent,
      background: background,
      onTap: questionsReady
          ? onStart
          : () {
              showDailyCaUnavailableSheet(
                context: context,
                availableFrom: DailyCaSchedule.nextOpensAt(),
                pendingLive: date != null,
                onSeeHistory: () {
                  if (context.mounted) context.push('/daily-ca');
                },
              );
            },
      done: completed,
      loading: loading,
      showNow: emphasized && layout == TodayLoopLayout.hero,
      footer: footer,
    );
  }
}

class _NotifyMePrimer extends StatelessWidget {
  const _NotifyMePrimer({
    required this.accent,
    required this.loading,
    required this.onTap,
  });

  final Color accent;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: accent),
            )
          else
            Icon(Icons.notifications_none_rounded, size: 15, color: accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Notify me when live',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm().copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
