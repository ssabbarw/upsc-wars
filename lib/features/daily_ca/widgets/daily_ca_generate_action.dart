import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/daily_ca_admin_cloud_service.dart';

Future<DailyCaGenerateResult?> confirmAndGenerateDailyCa({
  required BuildContext context,
  required DailyCaAdminCloudService cloud,
  required String isoDate,
  bool force = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(force ? 'Overwrite CA draft?' : 'Generate CA test?'),
        content: Text(
          force
              ? 'This replaces the English draft for $isoDate. '
                    'Existing picks are lost. Harvesting news usually takes '
                    '10–20 minutes. You will get a review notification when it '
                    'is ready.'
              : 'Harvest news and write English drafts for $isoDate. '
                    'Use this when tonight’s scheduled run missed (API limit). '
                    'It usually takes 10–20 minutes. You will get a review '
                    'notification when it is ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(force ? 'Overwrite' : 'Generate'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return null;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Generating $isoDate…\nKeep the app open, or wait for the '
                  'review notification.',
                  style: AppTextStyles.bodySm(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    return await cloud.generate(date: isoDate, force: force);
  } on DailyCaAdminException catch (e) {
    return DailyCaGenerateResult(
      ok: false,
      skipped: false,
      date: isoDate,
      questionCount: 0,
      error: e.message,
    );
  } catch (e) {
    return DailyCaGenerateResult(
      ok: false,
      skipped: false,
      date: isoDate,
      questionCount: 0,
      error: e.toString(),
    );
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
