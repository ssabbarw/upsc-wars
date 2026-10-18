import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toast.dart';
import '../daily_ca_admin_constants.dart';
import '../domain/daily_ca_draft.dart';
import '../domain/daily_ca_schedule.dart';
import '../providers/daily_ca_admin_providers.dart';
import '../widgets/daily_ca_generate_action.dart';

class DailyCaReviewScreen extends HookConsumerWidget {
  const DailyCaReviewScreen({required this.isoDate, super.key});

  final String isoDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyCaDraftProvider(isoDate));
    final local = useState<List<DailyCaDraftQuestion>?>(null);
    final saving = useState(false);
    final publishing = useState(false);

    ref.listen(dailyCaDraftProvider(isoDate), (prev, next) {
      next.whenData((draft) {
        if (draft != null) local.value = draft.questions;
      });
    });

    final draft = async.asData?.value;
    final frozen = draft != null && draft.isFrozen() && draft.isPublished;

    Future<void> generateDraft({required bool force}) async {
      final result = await confirmAndGenerateDailyCa(
        context: context,
        cloud: ref.read(dailyCaAdminCloudServiceProvider),
        isoDate: isoDate,
        force: force,
      );
      if (!context.mounted || result == null) return;
      AppToast.showText(context, result.userMessage);
      if (result.wroteDraft || result.reason == 'already_exists') {
        ref.invalidate(dailyCaDraftProvider(isoDate));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('CA review · $isoDate'),
        actions: [
          if (draft != null && !frozen)
            IconButton(
              tooltip: 'Regenerate draft',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => generateDraft(force: true),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (draft) {
          if (draft == null) {
            final isSunday = DailyCaSchedule.isSunday(
              DailyCaSchedule.parseIsoDate(isoDate),
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSunday
                          ? 'Sunday has no current-affairs paper.'
                          : 'No draft for this date.',
                      style: AppTextStyles.body(),
                      textAlign: TextAlign.center,
                    ),
                    if (!isSunday) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'If the scheduled run missed (API limit), generate it now. '
                        'This usually takes 10–20 minutes.',
                        style: AppTextStyles.bodySm(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () => generateDraft(force: false),
                        child: const Text('Generate this day’s test'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }
          final questions = local.value ?? draft.questions;
          final chosen = questions.where((q) => q.chosen).length;
          final clockOpen = draft.isFrozen();
          final frozen = clockOpen && draft.isPublished;
          final canPublish =
              chosen >= DailyCaAdminConstants.minPublish &&
              chosen <= DailyCaAdminConstants.maxPublish &&
              !frozen;
          final canAutoPublish =
              !frozen &&
              !draft.isPublished &&
              questions.length >= DailyCaAdminConstants.minPublish;

          Future<void> save() async {
            saving.value = true;
            try {
              await ref
                  .read(dailyCaAdminCloudServiceProvider)
                  .saveDraft(
                    date: isoDate,
                    questions: questions.map((q) => q.raw).toList(),
                    chosenIds: [
                      for (final q in questions)
                        if (q.chosen) q.draftId,
                    ],
                  );
              if (context.mounted) {
                AppToast.showText(context, 'Saved');
              }
              ref.invalidate(dailyCaDraftProvider(isoDate));
            } catch (e) {
              if (context.mounted) {
                AppToast.showText(context, 'Save failed: $e');
              }
            } finally {
              saving.value = false;
            }
          }

          Future<void> autoPublish() async {
            publishing.value = true;
            try {
              final count = await ref
                  .read(dailyCaAdminCloudServiceProvider)
                  .autoPublish(date: isoDate);
              if (context.mounted) {
                AppToast.showText(
                  context,
                  count == 0
                      ? 'Auto-publish skipped (already live, Sunday, or <5 questions).'
                      : 'Published $count questions.',
                );
              }
              ref.invalidate(dailyCaDraftProvider(isoDate));
            } catch (e) {
              if (context.mounted) {
                AppToast.showText(context, 'Publish failed: $e');
              }
            } finally {
              publishing.value = false;
            }
          }

          Future<void> publish() async {
            publishing.value = true;
            try {
              await save();
              final count = await ref
                  .read(dailyCaAdminCloudServiceProvider)
                  .publish(
                    date: isoDate,
                    chosenIds: [
                      for (final q in questions)
                        if (q.chosen) q.draftId,
                    ],
                  );
              if (context.mounted) {
                AppToast.showText(
                  context,
                  'Published $count questions. Hindi translated.',
                );
              }
              ref.invalidate(dailyCaDraftProvider(isoDate));
            } catch (e) {
              if (context.mounted) {
                AppToast.showText(context, 'Publish failed: $e');
              }
            } finally {
              publishing.value = false;
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  frozen
                      ? 'This paper is live. Use question corrections for further edits.'
                      : clockOpen && !draft.isPublished
                      ? 'This paper should already be live. Publish or auto-publish the first 10 so the app can show it.'
                      : draft.isWeekendPack
                      ? 'Weekend pack (Sat+Sun news). Pick 5–10. Hindi runs on publish.'
                      : 'Pick 5–10. Hindi runs on publish.',
                  style: AppTextStyles.bodySm(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      '$chosen / ${DailyCaAdminConstants.maxPublish} selected',
                      style: AppTextStyles.label(),
                    ),
                    const Spacer(),
                    if (frozen)
                      Text('Live — frozen', style: AppTextStyles.caption())
                    else if (clockOpen && !draft.isPublished)
                      Text(
                        'Missing live paper — publish now',
                        style: AppTextStyles.caption(),
                      )
                    else if (draft.isPublished)
                      Text(
                        'Published · can republish until 6 AM',
                        style: AppTextStyles.caption(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: questions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return Card(
                      child: CheckboxListTile(
                        value: q.chosen,
                        onChanged: frozen
                            ? null
                            : (v) {
                                if (v == true &&
                                    chosen >=
                                        DailyCaAdminConstants.maxPublish) {
                                  AppToast.showText(
                                    context,
                                    'Max ${DailyCaAdminConstants.maxPublish}',
                                  );
                                  return;
                                }
                                final next = [...questions];
                                next[index] = q.copyChosen(v == true);
                                local.value = next;
                              },
                        title: Text(
                          q.preview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm(),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _Chip(q.gsSubject),
                              _Chip(q.questionType),
                              for (final tag in q.caTags) _Chip(tag),
                            ],
                          ),
                        ),
                        secondary: IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: frozen
                              ? null
                              : () async {
                                  final updated = await context
                                      .push<Map<String, dynamic>>(
                                        '/internal/daily-ca-review/$isoDate/edit',
                                        extra: q.raw,
                                      );
                                  if (updated == null) return;
                                  final next = [...questions];
                                  next[index] = DailyCaDraftQuestion.fromMap(
                                    updated,
                                    index,
                                  );
                                  if (q.chosen) {
                                    next[index] = next[index].copyChosen(true);
                                  }
                                  local.value = next;
                                },
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: frozen || saving.value || publishing.value
                              ? null
                              : save,
                          child: Text(saving.value ? 'Saving…' : 'Save'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: publishing.value
                              ? null
                              : canPublish
                              ? publish
                              : canAutoPublish
                              ? autoPublish
                              : null,
                          child: Text(
                            publishing.value
                                ? 'Publishing…'
                                : canPublish
                                ? (draft.isPublished ? 'Republish' : 'Publish')
                                : 'Auto-publish',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text(label, style: AppTextStyles.caption()),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
