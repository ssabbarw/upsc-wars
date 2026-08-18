import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/fcm_token_sync_service.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../push_spot_test/widgets/push_notification_preview_card.dart';
import '../data/admin_pulse_draft_store.dart';
import '../data/fomo_pulse_article_fetch.dart';
import '../data/fomo_pulse_cloud_service.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';
import '../providers/fomo_pulse_providers.dart';
import '../widgets/fomo_pulse_hero_image.dart';
import '../widgets/fomo_pulse_question_block.dart';

class FomoPulseArticleScreen extends HookConsumerWidget {
  const FomoPulseArticleScreen({super.key, required this.args});

  final FomoPulseArticleArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleCtrl = useTextEditingController();
    final bodyCtrl = useTextEditingController();
    useListenable(titleCtrl);
    useListenable(bodyCtrl);

    final preview = useState<FomoPulseArticlePreview?>(null);
    final previewLoading = useState(false);
    final draft = useState<FomoPulseDraft?>(args.savedDraft);
    final generating = useState(false);
    final translating = useState(false);
    final sending = useState(false);
    final sendTarget = useState(FomoPulseSendTarget.self);
    final scheme = Theme.of(context).colorScheme;
    final draftStore = useMemoized(AdminPulseDraftStore.new);

    final sourceUrl = args.sourceUrl;

    useEffect(() {
      if (args.savedDraft != null) {
        titleCtrl.text = args.savedDraft!.notificationTitle;
        bodyCtrl.text = args.savedDraft!.notificationBody;
      }
      return null;
    }, const []);

    useEffect(() {
      if (sourceUrl.isEmpty) return null;
      unawaited(() async {
        previewLoading.value = true;
        try {
          preview.value = await ref
              .read(fomoPulseCloudServiceProvider)
              .previewArticle(sourceUrl);
        } catch (e, st) {
          debugPrint('FomoPulseArticleScreen.previewArticle failed: $e');
          debugPrintStack(stackTrace: st);
          preview.value = null;
        } finally {
          previewLoading.value = false;
        }
      }());
      return null;
    }, [sourceUrl]);

    final heading = () {
      final fromPreview = preview.value?.ogTitle.trim() ?? '';
      if (fromPreview.isNotEmpty) return fromPreview;
      if (args.heading.isNotEmpty) return args.heading;
      return '';
    }();

    final summary = () {
      final fromDraft = draft.value?.newsSummary.trim() ?? '';
      if (fromDraft.isNotEmpty) return fromDraft;
      final fromHarvest = args.summary;
      if (fromHarvest.isNotEmpty) return fromHarvest;
      return preview.value?.ogDescription.trim() ?? '';
    }();

    final imageUrl = draft.value?.imageUrl.isNotEmpty == true
        ? draft.value!.imageUrl
        : (preview.value?.imageUrl ?? '');
    final imageSource = draft.value?.imageSource.isNotEmpty == true
        ? draft.value!.imageSource
        : (preview.value?.imageSource ?? '');

    Future<void> makeQuestion() async {
      generating.value = true;
      try {
        final cloud = ref.read(fomoPulseCloudServiceProvider);
        final FomoPulseDraft next;
        if (args.isHarvest) {
          next = await cloud.generateFromHarvest(
            draftDate: args.draftDate!,
            draftId: args.candidate!.draftId,
            imageUrl: imageUrl,
            imageSource: imageSource,
          );
        } else {
          var articleText = await fetchArticleTextFromUrl(sourceUrl);
          if ((articleText == null || articleText.length < 40) &&
              summary.isNotEmpty) {
            articleText = summary;
          }
          if ((articleText == null || articleText.length < 40) &&
              heading.isNotEmpty &&
              summary.isNotEmpty) {
            articleText = '$heading\n$summary';
          }
          if (articleText != null && articleText.length >= 40) {
            debugPrint(
              'FomoPulseArticleScreen: using on-device article text '
              '(${articleText.length} chars)',
            );
          } else {
            debugPrint(
              'FomoPulseArticleScreen: no on-device text; server will fetch',
            );
          }
          next = await cloud.generateFromUrl(
            sourceUrl,
            imageUrl: imageUrl,
            imageSource: imageSource,
            articleText: articleText,
          );
        }
        draft.value = next;
        titleCtrl.text = next.notificationTitle;
        bodyCtrl.text = next.notificationBody;
        // Auto-save so LLM isn't called again for the same URL.
        final draftId = AdminPulseDraft.idFromUrl(next.sourceUrl);
        unawaited(
          draftStore.save(
            AdminPulseDraft(
              id: draftId,
              savedAt: DateTime.now(),
              status: AdminPulseDraftStatus.draft,
              draft: next,
            ),
          ),
        );
      } catch (e, st) {
        final message = FomoPulseCloudService.describeCallableError(e);
        debugPrint('FomoPulseArticleScreen.makeQuestion failed: $message');
        debugPrintStack(stackTrace: st);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not make question: $message')),
          );
        }
      } finally {
        generating.value = false;
      }
    }

    Future<void> translate() async {
      final current = draft.value;
      if (current == null) return;
      translating.value = true;
      try {
        draft.value = await ref
            .read(fomoPulseCloudServiceProvider)
            .translateDraft(current);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hindi added to this Pulse.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Translate failed: $e')),
          );
        }
      } finally {
        translating.value = false;
      }
    }

    Future<void> send() async {
      final d = draft.value;
      if (d == null) return;
      final title = titleCtrl.text.trim();
      final body = bodyCtrl.text.trim();
      if (title.isEmpty || body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Heading and subheading are required.')),
        );
        return;
      }
      if (sendTarget.value == FomoPulseSendTarget.broadcast) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Broadcast Pulse?'),
            content: Text(
              'Sends to all devices on '
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
        // The draft can carry no image of its own (preview resolved after
        // generation, or a saved draft predates it). Send the image the
        // composer is actually showing.
        final updated = d.copyWith(
          notificationTitle: title,
          notificationBody: body,
          imageUrl: imageUrl,
          imageSource: imageSource,
        );
        final outcome = await ref.read(fomoPulsePushServiceProvider).send(
              updated,
              sendTarget.value,
            );
        debugPrint(
          'FomoPulseArticle.send: sent=${outcome.sent} '
          'reason=${outcome.reason} target=${outcome.target} '
          'pulseId=${outcome.pulseId} error=${outcome.error}',
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(outcome.userMessage)),
        );
        if (outcome.sent) {
          final sentStatus = sendTarget.value == FomoPulseSendTarget.broadcast
              ? AdminPulseDraftStatus.sentBroadcast
              : AdminPulseDraftStatus.sentSelf;
          unawaited(
            draftStore.updateStatus(
              AdminPulseDraft.idFromUrl(updated.sourceUrl),
              sentStatus,
              draft: updated,
            ),
          );
          // Pre-cache the pulse so tapping the notification works offline.
          final pid = outcome.pulseId;
          if (pid != null) {
            unawaited(
              ref
                  .read(fomoPulseRepositoryProvider)
                  .loadPulse(pid)
                  .then((_) {})
                  .catchError((_) {}),
            );
          }
          Navigator.of(context).pop();
        }
      } finally {
        sending.value = false;
      }
    }

    final current = draft.value;
    final points = current?.upscPoints.isNotEmpty == true
        ? current!.upscPoints
        : (args.candidate?.upscPoints ?? const <String>[]);

    final hasPreviewData =
        preview.value != null || args.heading.isNotEmpty || args.summary.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse article')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (previewLoading.value && !hasPreviewData) ...[
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Loading article preview…',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ] else ...[
            if (previewLoading.value)
              const LinearProgressIndicator(),
            FomoPulseHeroImage(
              imageUrl: imageUrl,
              imageSource: imageSource,
            ),
            if (imageUrl.isNotEmpty) const SizedBox(height: AppSpacing.md),
            if (heading.isNotEmpty)
              Text(
                heading,
                style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w800),
              ),
            if (args.candidate?.gsSubject.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                args.candidate!.gsSubject,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (summary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                summary,
                style: AppTextStyles.bodySm().copyWith(height: 1.4),
              ),
            ],
            if (points.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('UPSC points', style: AppTextStyles.label()),
              const SizedBox(height: AppSpacing.xs),
              ...points.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('• $p', style: AppTextStyles.bodySm()),
                ),
              ),
            ],
            if (sourceUrl.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(sourceUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  Uri.tryParse(sourceUrl)?.host.replaceFirst('www.', '') ??
                      'Open article',
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          if (current == null)
            FilledButton.icon(
              onPressed: generating.value ||
                      previewLoading.value ||
                      (!args.isHarvest && sourceUrl.isEmpty)
                  ? null
                  : () => unawaited(makeQuestion()),
              icon: generating.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                generating.value ? 'Making question…' : 'Make question',
              ),
            )
          else ...[
            Text('Notification', style: AppTextStyles.label()),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Heading',
                helperText: 'Shown as the notification title. Editable.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Subheading',
                helperText: 'Shown under the title. Editable.',
              ),
              maxLines: 3,
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
                question: current.question,
                picked: null,
                onPick: (_) {},
                busy: true,
              ),
            ),
            if (current.question.hasHindi) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Hindi translation is attached and will be stored on this Pulse.',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: translating.value || current.question.hasHindi
                  ? null
                  : () => unawaited(translate()),
              icon: translating.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.translate),
              label: Text(
                current.question.hasHindi
                    ? 'Hindi added'
                    : translating.value
                        ? 'Translating…'
                        : 'Translate to Hindi',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Post notification', style: AppTextStyles.label()),
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
                  : const Icon(Icons.campaign_outlined),
              label: Text(
                sendTarget.value == FomoPulseSendTarget.broadcast
                    ? 'Post broadcast'
                    : 'Post to my device',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
