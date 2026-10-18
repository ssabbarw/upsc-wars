import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../../home/domain/start_daily_drill.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../theme/daily_war_theme.dart';
import '../../../l10n/l10n.dart';

/// What Daily War is, how two topics a day cover the map, and a warm-up CTA.
Future<void> showDailyWarExplainerSheet({
  required BuildContext context,
  List<DailyWarTopicRef> topics = const [],
  bool isGrand = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DailyWarExplainerSheet(
      hostContext: context,
      topics: topics,
      isGrand: isGrand,
    ),
  );
}

class _DailyWarExplainerSheet extends HookConsumerWidget {
  const _DailyWarExplainerSheet({
    required this.hostContext,
    required this.topics,
    required this.isGrand,
  });

  final BuildContext hostContext;
  final List<DailyWarTopicRef> topics;
  final bool isGrand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launching = useState(false);

    Future<void> revise() async {
      if (launching.value) return;
      launching.value = true;
      final subject = topics.isEmpty
          ? 'Polity'
          : DailyWarCopy.sessionSubjectSlug(topics.first.subjectSlug);
      final host = hostContext;
      final sheetNav = Navigator.of(context);
      try {
        sheetNav.pop();
        if (!host.mounted) return;
        await startDailyDrill(
          context: host,
          ref: ref,
          subject: subject,
          source: 'daily_war_explainer',
          completedToday: false,
          warTopics: topics,
        );
      } finally {
        launching.value = false;
      }
    }

    return DismissOnScrimTap(
      child: Padding(
        padding: EdgeInsets.only(bottom: sheetBottomPadding(context)),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: DwColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: DwColors.onDarkFaint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.dwExplainerHead,
                    style: DwText.dm(
                      size: 24,
                      weight: FontWeight.w800,
                      color: DwColors.onDark,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.dwExplainerSub,
                    style: DwText.dm(
                      size: 14,
                      weight: FontWeight.w500,
                      color: DwColors.onDarkMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (topics.isNotEmpty) ...[
                    Text(
                      isGrand
                          ? context.l10n.dwPaperIsTheseSat
                          : topics.length == 1
                          ? context.l10n.dwPaperIsThis
                          : context.l10n.dwPaperIsThese,
                      style: AppTextStyles.bodySm().copyWith(
                        color: DwColors.onDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in topics)
                          _TopicChip(
                            subject: DailyWarCopy.subjectDisplay(t.subjectSlug),
                            topic: t.topic,
                          ),
                      ],
                    ),
                  ] else
                    Text(
                      isGrand
                          ? context.l10n.dwWeekTopicsLand
                          : context.l10n.dwTonightTopicsLand,
                      style: AppTextStyles.bodySm().copyWith(
                        color: DwColors.onDarkMuted,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: launching.value
                          ? null
                          : () => unawaited(revise()),
                      style: FilledButton.styleFrom(
                        backgroundColor: DwColors.crimson,
                        foregroundColor: DwColors.onDark,
                        disabledBackgroundColor: DwColors.crimson.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: launching.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DwColors.onDark,
                              ),
                            )
                          : Text(
                              context.l10n.dwTry10,
                              style: AppTextStyles.label().copyWith(
                                color: DwColors.onDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.subject, required this.topic});

  final String subject;
  final String topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DwColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: DwColors.borderOnDark),
      ),
      child: Text(
        '$subject · $topic',
        style: AppTextStyles.bodySm().copyWith(
          color: DwColors.onDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
