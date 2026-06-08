import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_ca_schedule.dart';

class DailyCaHomeCard extends HookWidget {
  const DailyCaHomeCard({super.key, required this.borderColor});

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nowIst = useState(DailyCaSchedule.nowIst());

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        nowIst.value = DailyCaSchedule.nowIst();
      });
      return timer.cancel;
    }, const []);

    final ist = nowIst.value;
    final todayPublished = DailyCaSchedule.isPublishedForDate(ist);
    final todayIsTestDay = DailyCaSchedule.isTestDay(ist);
    final countdown = DailyCaSchedule.formatCountdown(
      DailyCaSchedule.timeUntilNextPublish(referenceIst: ist),
    );

    String subtitle;
    if (!todayIsTestDay) {
      subtitle = 'Sunday rest · next test in $countdown';
    } else if (!todayPublished) {
      subtitle = 'Today\'s test at 9 PM IST · $countdown';
    } else {
      subtitle = 'Today\'s test is live';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/daily-ca'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.newspaper_rounded,
                  color: isDark ? AppColors.infoTextDark : AppColors.infoText,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Current Affairs',
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
