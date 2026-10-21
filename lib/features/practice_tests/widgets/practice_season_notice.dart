import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/l10n.dart';
import '../providers/practice_catalog_provider.dart';

var _seasonNoticeRunning = false;

/// One-time note when a new prelims season reshuffles the numbered tests.
class PracticeSeasonNotice extends ConsumerWidget {
  const PracticeSeasonNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(practiceCatalogProvider, (previous, next) {
      final catalog = next.asData?.value;
      if (catalog == null) return;
      final year = catalog.season.year;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        unawaited(_maybeShow(context, ref, year));
      });
    });
    return const SizedBox.shrink();
  }

  Future<void> _maybeShow(BuildContext context, WidgetRef ref, int year) async {
    if (_seasonNoticeRunning) return;
    _seasonNoticeRunning = true;
    try {
      final prefs = await ref.read(prefsServiceProvider.future);
      final seen = int.tryParse(
        prefs.getString(PrefKeys.practiceSeasonNotice) ?? '',
      );
      if (seen == year) return;
      final previous = year - 1;
      final hadPrevious = await ref
          .read(userDatabaseProvider)
          .sessionsDao
          .hasCompletedPracticeTestsForSeason(previous);
      await prefs.setString(PrefKeys.practiceSeasonNotice, '$year');
      if (!hadPrevious || !context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Text(ctx.l10n.practiceNewSeason),
        ),
      );
    } finally {
      _seasonNoticeRunning = false;
    }
  }
}
