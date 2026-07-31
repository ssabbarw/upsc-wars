import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/daily_war_cloud_service.dart';

/// Super-user review of tonight's private paper (before public publish).
class DailyWarAdminPreviewScreen extends HookConsumerWidget {
  const DailyWarAdminPreviewScreen({super.key, required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final loading = useState(true);
    final error = useState<String?>(null);
    final preview = useState<DailyWarAdminPreview?>(null);
    final questions = useState<List<TestQuestion>>(const []);
    final missingUuids = useState<List<String>>(const []);

    useEffect(() {
      var cancelled = false;
      unawaited(() async {
        try {
          const cloud = DailyWarCloudService();
          final p = await cloud.adminPreview(dateId: dateId);
          if (cancelled) return;
          if (p == null) {
            error.value = 'Preview failed. Generate today’s War first.';
            loading.value = false;
            return;
          }
          preview.value = p;

          final repo = await ref.read(testEngineRepositoryProvider.future);
          final loaded = <TestQuestion>[];
          final missing = <String>[];
          for (final uuid in p.privateUuids) {
            if (cancelled) return;
            final q = await repo.loadStandaloneQuestionByUuid(uuid);
            if (q == null) {
              missing.add(uuid);
            } else {
              loaded.add(q);
            }
          }
          if (cancelled) return;
          questions.value = loaded;
          missingUuids.value = missing;
          loading.value = false;
        } on Object catch (e) {
          if (cancelled) return;
          error.value = e.toString();
          loading.value = false;
        }
      }());
      return () => cancelled = true;
    }, [dateId]);

    return Scaffold(
      appBar: AppBar(
        title: Text('War preview · $dateId', style: AppTextStyles.h3()),
      ),
      body: loading.value
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSpacing.md),
                  Text('Loading private paper…'),
                ],
              ),
            )
          : error.value != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  error.value!,
                  style: AppTextStyles.bodyMd().copyWith(color: AppColors.wrong),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (preview.value case final p?) ...[
                  _MetaCard(preview: p),
                  const SizedBox(height: AppSpacing.md),
                  Text('Tonight’s topics', style: AppTextStyles.label()),
                  const SizedBox(height: AppSpacing.xs),
                  for (final t in p.topics)
                    Text(
                      '• ${t['subject']} — ${t['topic']}',
                      style: AppTextStyles.bodySm(),
                    ),
                  if (p.nextTopics.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Tomorrow teaser', style: AppTextStyles.label()),
                    const SizedBox(height: AppSpacing.xs),
                    for (final t in p.nextTopics)
                      Text(
                        '• ${t['subject']} — ${t['topic']}',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Questions (${questions.value.length}'
                    '${missingUuids.value.isEmpty ? '' : ', ${missingUuids.value.length} missing'})',
                    style: AppTextStyles.h3(),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < questions.value.length; i++)
                  _QuestionReviewCard(
                    index: i + 1,
                    question: questions.value[i],
                  ),
                for (final uuid in missingUuids.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Missing in local bank: $uuid',
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.wrong,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.preview});

  final DailyWarAdminPreview preview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${preview.kind.toUpperCase()} · ${preview.status}',
            style: AppTextStyles.label(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preview.isPubliclyPublished
                ? 'Public UUIDs live (${preview.publicUuids.length})'
                : 'Private only — not published to clients yet',
            style: AppTextStyles.bodySm().copyWith(
              color: preview.isPubliclyPublished
                  ? AppColors.warning
                  : AppColors.correct,
            ),
          ),
          Text(
            '${preview.questionCount} questions · '
            '${preview.privateUuids.length} private UUIDs',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  const _QuestionReviewCard({required this.index, required this.question});

  final int index;
  final TestQuestion question;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final correct = question.correctOption.toLowerCase();

    Widget option(String key, String text) {
      final isCorrect = key == correct;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '(${key.toUpperCase()}) ',
              style: AppTextStyles.labelSm().copyWith(
                color: isCorrect ? AppColors.correct : scheme.onSurface,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodySm().copyWith(
                  color: isCorrect ? AppColors.correct : scheme.onSurface,
                  fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        initiallyExpanded: index == 1,
        title: Text(
          'Q$index · ${question.subject} / ${question.topic}',
          style: AppTextStyles.label(),
        ),
        subtitle: Text(
          'Answer: ${correct.toUpperCase()}'
          '${question.trapType != null && question.trapType!.isNotEmpty ? ' · trap: ${question.trapType}' : ''}',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          SelectableText(
            question.displayText,
            style: AppTextStyles.bodyMd(),
          ),
          const SizedBox(height: AppSpacing.md),
          option('a', question.optionA),
          option('b', question.optionB),
          option('c', question.optionC),
          option('d', question.optionD),
          if ((question.conceptAnchor ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Concept', style: AppTextStyles.labelSm()),
            Text(question.conceptAnchor!, style: AppTextStyles.bodySm()),
          ],
          if ((question.finalExplanation ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Explanation', style: AppTextStyles.labelSm()),
            Text(question.finalExplanation!, style: AppTextStyles.bodySm()),
          ],
          if (question.eliminationLogic.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Elimination', style: AppTextStyles.labelSm()),
            Text(
              question.eliminationLogic.join('\n'),
              style: AppTextStyles.bodySm(),
            ),
          ],
          if ((question.strongDistractor ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Strong distractor', style: AppTextStyles.labelSm()),
            Text(question.strongDistractor!, style: AppTextStyles.bodySm()),
          ],
          if ((question.upscTrapExplanation ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('UPSC trap', style: AppTextStyles.labelSm()),
            Text(question.upscTrapExplanation!, style: AppTextStyles.bodySm()),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            question.uuid,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
