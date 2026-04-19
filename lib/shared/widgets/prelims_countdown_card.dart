import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/constants/prelims_countdown.dart';
import '../../core/services/prelims_widget_sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

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

    useEffect(() {
      unawaited(PrelimsWidgetSyncService.sync());
      return null;
    }, [now.value.day]);

    final timerLabel = PrelimsCountdown.timerLabel(now: now.value);
    final quote = PrelimsCountdown.quoteForDate(now: now.value);
    final cardColor = isDark ? AppColors.infoBgDark : AppColors.infoBg;
    final quoteColor = isDark ? AppColors.infoTextDark : AppColors.infoText;
    final showHomeWidgetHint =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPSC PRELIMS COUNTDOWN',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurface,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Days : Hours : Min : Sec',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            timerLabel,
            style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            quote,
            style: AppTextStyles.bodySm().copyWith(color: quoteColor),
          ),
          // if (showHomeWidgetHint) ...[
          //   const SizedBox(height: AppSpacing.sm),
          //   Row(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Icon(
          //         Icons.widgets_outlined,
          //         size: 16,
          //         color: scheme.onSurfaceVariant,
          //       ),
          //       const SizedBox(width: AppSpacing.xs),
          //       Expanded(
          //         child: Text(
          //           'You can also add this countdown as a widget on your device home screen.',
          //           style: AppTextStyles.caption().copyWith(
          //             color: scheme.onSurfaceVariant,
          //             height: 1.3,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
        ],
      ),
    );
  }
}
