import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/prelims_countdown.dart';
import '../../core/providers/prelims_date_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/l10n.dart';

/// Compact one-line prelims countdown for the home screen.
class PrelimsDaysInfo extends ConsumerWidget {
  const PrelimsDaysInfo({super.key});

  static String label({DateTime? now, DateTime? targetDate}) {
    final days = PrelimsCountdown.daysLeft(now: now, targetDate: targetDate);
    if (days <= 0) return appL10n.pcToday;
    if (days == 1) return appL10n.pcOneDay;
    return appL10n.pcDays(days);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final prelimsDate =
        ref.watch(prelimsDateProvider).value ?? PrelimsCountdown.prelimsDate;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_outlined, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label(targetDate: prelimsDate),
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class PrelimsCountdownCard extends HookWidget {
  const PrelimsCountdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = useState(DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        now.value = DateTime.now();
      });
      return timer.cancel;
    }, const []);

    final timerLabel = PrelimsCountdown.timerLabel(now: now.value);
    final cardColor = isDark ? AppColors.infoBgDark : AppColors.infoBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.l10n.pcTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurface,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.pcUnits,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            timerLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1().copyWith(
              color: scheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
