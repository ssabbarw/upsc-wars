import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/services/fcm_token_sync_service.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../push_spot_test/widgets/push_notification_preview_card.dart';
import '../data/fomo_pulse_cloud_service.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';
import '../widgets/fomo_pulse_question_block.dart';

enum _ComposerTab { harvest, url }

class FomoPulseComposerScreen extends HookConsumerWidget {
  const FomoPulseComposerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(_ComposerTab.harvest);
    final urlCtrl = useTextEditingController();
    final titleCtrl = useTextEditingController();
    final bodyCtrl = useTextEditingController();
    final draft = useState<FomoPulseDraft?>(null);
    final generating = useState(false);
    final sending = useState(false);
    final sendTarget = useState(FomoPulseSendTarget.self);
    final harvestLoading = useState(true);
    final harvestDate = useState<String?>(null);
    final candidates = useState<List<FomoPulseHarvestCandidate>>([]);
    final selectedCandidate = useState<FomoPulseHarvestCandidate?>(null);
    final scheme = Theme.of(context).colorScheme;

    useEffect(() {
      unawaited(() async {
        harvestLoading.value = true;
        try {
          final cloud = ref.read(fomoPulseCloudServiceProvider);
          final result = await cloud.listHarvestCandidates();
          harvestDate.value = result.draftDate;
          candidates.value = result.candidates;
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not load harvest: $e')),
            );
          }
        } finally {
          harvestLoading.value = false;
        }
      }());
      return null;
    }, []);

    void applyDraft(FomoPulseDraft d) {
      draft.value = d;
      titleCtrl.text = d.notificationTitle;
      bodyCtrl.text = d.notificationBody;
    }

    Future<void> generateFromHarvest(FomoPulseHarvestCandidate c) async {
      final date = harvestDate.value;
      if (date == null) return;
      generating.value = true;
      try {
        final cloud = ref.read(fomoPulseCloudServiceProvider);
        final d = await cloud.generateFromHarvest(
          draftDate: date,
          draftId: c.draftId,
        );
        applyDraft(d);
        selectedCandidate.value = c;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generate failed: $e')),
          );
        }
      } finally {
        generating.value = false;
      }
    }

    Future<void> generateFromUrl() async {
      final url = urlCtrl.text.trim();
      if (url.isEmpty) return;
      generating.value = true;
      try {
        final cloud = ref.read(fomoPulseCloudServiceProvider);
        final d = await cloud.generateFromUrl(url);
        applyDraft(d);
        selectedCandidate.value = null;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generate failed: $e')),
          );
        }
      } finally {
        generating.value = false;
      }
    }

    Future<void> send() async {
      final d = draft.value;
      if (d == null) return;
      if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and body are required.')),
        );
        return;
      }
      if (sendTarget.value == FomoPulseSendTarget.broadcast) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Broadcast Pulse?'),
            content: Text(
              'Sends to all devices on topic '
              '"${FomoPulseConstants.broadcastFcmTopic}".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Broadcast'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      sending.value = true;
      try {
        await FcmTokenSyncService.syncForCurrentUser();
        final updated = FomoPulseDraft(
          notificationTitle: titleCtrl.text.trim(),
          notificationBody: bodyCtrl.text.trim(),
          newsSummary: d.newsSummary,
          sourceUrl: d.sourceUrl,
          question: d.question,
          harvestDraftDate: d.harvestDraftDate,
          harvestDraftId: d.harvestDraftId,
        );
        final outcome = await ref.read(fomoPulsePushServiceProvider).send(
              updated,
              sendTarget.value,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(outcome.userMessage)),
        );
      } finally {
        sending.value = false;
      }
    }

    final currentDraft = draft.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse composer')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SegmentedButton<_ComposerTab>(
            segments: const [
              ButtonSegment(
                value: _ComposerTab.harvest,
                label: Text("Today's news"),
              ),
              ButtonSegment(
                value: _ComposerTab.url,
                label: Text('URL'),
              ),
            ],
            selected: {tab.value},
            onSelectionChanged: (s) => tab.value = s.first,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (tab.value == _ComposerTab.harvest) ...[
            if (harvestLoading.value)
              const Center(child: CircularProgressIndicator())
            else if (candidates.value.isEmpty)
              Text(
                'No CA draft available. Run daily CA pipeline or use URL tab.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              ...candidates.value.map((c) {
                final selected = selectedCandidate.value?.draftId == c.draftId;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  color: selected
                      ? scheme.primaryContainer.withValues(alpha: 0.35)
                      : null,
                  child: ListTile(
                    title: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${c.gsSubject} · ★${c.newsImportance}',
                      style: AppTextStyles.caption(),
                    ),
                    trailing: generating.value && selected
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: generating.value
                        ? null
                        : () => unawaited(generateFromHarvest(c)),
                  ),
                );
              }),
          ] else ...[
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Article URL',
                hintText: 'https://…',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: generating.value
                  ? null
                  : () => unawaited(generateFromUrl()),
              icon: generating.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Generate from URL'),
            ),
          ],
          if (currentDraft != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Review', style: AppTextStyles.h3()),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Notification title'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Notification body'),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            PushNotificationPreviewCard(
              title: titleCtrl.text,
              body: bodyCtrl.text,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('MCQ', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: FomoPulseQuestionBlock(
                question: currentDraft.question,
                picked: null,
                onPick: (_) {},
                busy: true,
              ),
            ),
            if (currentDraft.newsSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                currentDraft.newsSummary,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Send to', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<FomoPulseSendTarget>(
              segments: const [
                ButtonSegment(
                  value: FomoPulseSendTarget.self,
                  label: Text('My device'),
                ),
                ButtonSegment(
                  value: FomoPulseSendTarget.broadcast,
                  label: Text('Broadcast'),
                ),
              ],
              selected: {sendTarget.value},
              onSelectionChanged: (s) => sendTarget.value = s.first,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: sending.value ? null : () => unawaited(send()),
              icon: sending.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                sendTarget.value == FomoPulseSendTarget.broadcast
                    ? 'Review & broadcast'
                    : 'Send to my device',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
