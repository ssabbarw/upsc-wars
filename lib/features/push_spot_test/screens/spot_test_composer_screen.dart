import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/database/user_db.dart';
import '../../../core/parsers/question_display_text_parser.dart';
import '../../../core/providers/topics_subtopics_catalog_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/services/spot_test_push_cloud_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/pick_spot_composer_question.dart';
import '../push_spot_test_constants.dart';
import '../push_spot_test_launcher.dart';
import '../widgets/push_notification_preview_card.dart';

String? _firstCatalogTopic(TopicsSubtopicsCatalog catalog, String subject) {
  final topics = catalog[subject]?.keys.toList();
  if (topics == null || topics.isEmpty) return null;
  return topics.first;
}

/// Internal tool: pick catalog + optional MCQ, preview notification, send FCM.
class SpotTestComposerScreen extends HookConsumerWidget {
  const SpotTestComposerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(topicsSubtopicsCatalogProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Spot test composer')),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load catalog: $e')),
        data: (catalog) => _ComposerBody(catalog: catalog, scheme: scheme),
      ),
    );
  }
}

class _ComposerBody extends HookConsumerWidget {
  const _ComposerBody({required this.catalog, required this.scheme});

  final TopicsSubtopicsCatalog catalog;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = [
      for (final s in SubjectConstants.ordered)
        if (catalog.containsKey(s.slug)) s.slug,
      for (final key in catalog.keys)
        if (!SubjectConstants.ordered.any((s) => s.slug == key)) key,
    ];
    if (subjects.isEmpty) {
      return const Center(child: Text('Catalog is empty.'));
    }

    final subject = useState(subjects.first);
    final topic = useState<String?>(
      _firstCatalogTopic(catalog, subjects.first),
    );
    final subtopic = useState<String?>(null);
    final pinQuestion = useState(false);
    final pinnedQuestion = useState<Question?>(null);
    final excludeUuids = useState(<String>{});
    final shuffling = useState(false);

    final titleCtrl = useTextEditingController();
    final bodyCtrl = useTextEditingController();
    useListenable(titleCtrl);
    useListenable(bodyCtrl);
    final titleEdited = useState(false);
    final bodyEdited = useState(false);
    final sendTarget = useState(SpotTestSendTarget.self);

    void applyDefaultCopy() {
      if (!titleEdited.value || !bodyEdited.value) {
        final t = topic.value;
        final st = subtopic.value;
        if (!titleEdited.value && t != null) {
          titleCtrl.text = st != null && st.isNotEmpty
              ? 'Quick check · $t'
              : 'Quick check · $t';
        }
        if (!bodyEdited.value && t != null) {
          final focus = (st != null && st.isNotEmpty) ? st : t;
          bodyCtrl.text = '1 MCQ on $focus. Tap to try.';
        }
      }
    }

    useEffect(() {
      applyDefaultCopy();
      return null;
    }, [subject.value, topic.value, subtopic.value]);

    final topics = catalog[subject.value]?.keys.toList() ?? const <String>[];
    final subtopics = topic.value == null
        ? const <String>[]
        : catalog[subject.value]?[topic.value!] ?? const <String>[];

    Future<void> shuffleQuestion() async {
      if (topic.value == null) return;
      shuffling.value = true;
      try {
        final db = ref.read(userDatabaseProvider);
        var q = await pickSpotComposerQuestion(
          db,
          subject: subject.value,
          topic: topic.value!,
          subTopic: subtopic.value,
          excludeUuids: excludeUuids.value,
        );
        if (q == null && excludeUuids.value.isNotEmpty) {
          excludeUuids.value = {};
          q = await pickSpotComposerQuestion(
            db,
            subject: subject.value,
            topic: topic.value!,
            subTopic: subtopic.value,
          );
        }
        if (q != null) {
          pinnedQuestion.value = q;
          excludeUuids.value = {...excludeUuids.value, q.uuid};
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions for this selection.')),
          );
        }
      } finally {
        shuffling.value = false;
      }
    }

    Future<void> openSendReview() async {
      final title = titleCtrl.text.trim();
      final body = bodyCtrl.text.trim();
      if (title.isEmpty || body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and body are required.')),
        );
        return;
      }
      if (topic.value == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pick a topic.')));
        return;
      }
      if (pinQuestion.value && pinnedQuestion.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shuffle a question or turn off “Pin question”.'),
          ),
        );
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => _SendReviewSheet(
          title: title,
          body: body,
          subject: subject.value,
          topic: topic.value!,
          subtopic: subtopic.value,
          questionUuid: pinQuestion.value ? pinnedQuestion.value?.uuid : null,
          questionStem: pinQuestion.value
              ? _stemPreview(pinnedQuestion.value)
              : null,
          initialTarget: sendTarget.value,
          parentContext: context,
          ref: ref,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Pick subject, topic, and subtopic from the question-bank catalog. '
          'Shuffle an MCQ if you want a specific question.',
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Catalog', style: AppTextStyles.label()),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: subject.value,
          decoration: const InputDecoration(labelText: 'Subject'),
          items: [
            for (final s in subjects)
              DropdownMenuItem(
                value: s,
                child: Text(SubjectConstants.bySlug(s)?.displayName ?? s),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            subject.value = v;
            topic.value = _firstCatalogTopic(catalog, v);
            subtopic.value = null;
            pinnedQuestion.value = null;
            excludeUuids.value = {};
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: topic.value,
          decoration: InputDecoration(
            labelText: 'Topic',
            helperText: topics.isEmpty ? 'No topics in catalog' : null,
          ),
          items: [
            for (final t in topics) DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: topics.isEmpty
              ? null
              : (v) {
                  topic.value = v;
                  subtopic.value = null;
                  pinnedQuestion.value = null;
                  excludeUuids.value = {};
                },
        ),
        if (topic.value != null) ...[
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            value: subtopic.value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Subtopic (optional)',
              helperText: subtopics.isEmpty
                  ? 'No subtopics in catalog for this topic'
                  : '${subtopics.length} subtopics',
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any subtopic'),
              ),
              for (final s in subtopics)
                DropdownMenuItem(
                  value: s,
                  child: Text(s, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: subtopics.isEmpty
                ? null
                : (v) {
                    subtopic.value = v;
                    pinnedQuestion.value = null;
                    excludeUuids.value = {};
                  },
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Pin specific question', style: AppTextStyles.label()),
          subtitle: Text(
            'Shuffle until you find a good MCQ for this selection.',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          value: pinQuestion.value,
          onChanged: (v) {
            pinQuestion.value = v;
            if (!v) {
              pinnedQuestion.value = null;
              excludeUuids.value = {};
            }
          },
        ),
        if (pinQuestion.value) ...[
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton.icon(
            onPressed: shuffling.value || topic.value == null
                ? null
                : () => unawaited(shuffleQuestion()),
            icon: shuffling.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shuffle),
            label: Text(
              pinnedQuestion.value == null
                  ? 'Shuffle question'
                  : 'Shuffle again',
            ),
          ),
          if (pinnedQuestion.value != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _QuestionPreviewCard(question: pinnedQuestion.value!),
          ],
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Notification', style: AppTextStyles.label()),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            helperText: 'Shown in the notification tray',
          ),
          textInputAction: TextInputAction.next,
          onChanged: (_) => titleEdited.value = true,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: bodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Body',
            helperText: 'Supporting line under the title',
          ),
          maxLines: 3,
          onChanged: (_) => bodyEdited.value = true,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Live preview', style: AppTextStyles.caption()),
        const SizedBox(height: AppSpacing.xs),
        PushNotificationPreviewCard(title: titleCtrl.text, body: bodyCtrl.text),
        const SizedBox(height: AppSpacing.lg),
        Text('Send to', style: AppTextStyles.label()),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<SpotTestSendTarget>(
          segments: const [
            ButtonSegment(
              value: SpotTestSendTarget.self,
              label: Text('My device'),
              icon: Icon(Icons.phone_iphone_outlined, size: 18),
            ),
            ButtonSegment(
              value: SpotTestSendTarget.broadcast,
              label: Text('Broadcast'),
              icon: Icon(Icons.campaign_outlined, size: 18),
            ),
          ],
          selected: {sendTarget.value},
          onSelectionChanged: (s) => sendTarget.value = s.first,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          sendTarget.value == SpotTestSendTarget.self
              ? 'Delivers only to your signed-in device.'
              : 'Delivers to all devices subscribed to topic '
                    '"${PushSpotTestConstants.broadcastFcmTopic}". '
                    'Requires your email on the Cloud Function allowlist.',
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: topic.value == null
              ? null
              : () => unawaited(openSendReview()),
          icon: const Icon(Icons.send_outlined),
          label: const Text('Review & send'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: topic.value == null
              ? null
              : () => unawaited(
                  launchPushSpotTest(
                    context: context,
                    ref: ref,
                    subject: subject.value,
                    topic: topic.value!,
                    subTopic: subtopic.value,
                    questionUuid: pinQuestion.value
                        ? pinnedQuestion.value?.uuid
                        : null,
                  ),
                ),
          icon: const Icon(Icons.play_arrow_outlined),
          label: const Text('Preview test in app'),
        ),
      ],
    );
  }
}

String _stemPreview(Question? q) {
  if (q == null) return '';
  final raw = q.enDisplayText ?? '';
  if (raw.trim().isEmpty) return '(no display text)';
  return QuestionDisplayTextParser.parse(raw).stem.trim().isEmpty
      ? raw.trim()
      : QuestionDisplayTextParser.parse(raw).stem.trim();
}

class _QuestionPreviewCard extends StatelessWidget {
  const _QuestionPreviewCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stem = _stemPreview(question);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MCQ preview', style: AppTextStyles.caption()),
          const SizedBox(height: AppSpacing.xs),
          Text(stem, style: AppTextStyles.bodySm()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'UUID: ${question.uuid}',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _SendReviewSheet extends ConsumerStatefulWidget {
  const _SendReviewSheet({
    required this.title,
    required this.body,
    required this.subject,
    required this.topic,
    required this.subtopic,
    required this.questionUuid,
    required this.questionStem,
    required this.initialTarget,
    required this.parentContext,
    required this.ref,
  });

  final String title;
  final String body;
  final String subject;
  final String topic;
  final String? subtopic;
  final String? questionUuid;
  final String? questionStem;
  final SpotTestSendTarget initialTarget;
  final BuildContext parentContext;
  final WidgetRef ref;

  @override
  ConsumerState<_SendReviewSheet> createState() => _SendReviewSheetState();
}

class _SendReviewSheetState extends ConsumerState<_SendReviewSheet> {
  var _sending = false;
  late SpotTestSendTarget _target;

  @override
  void initState() {
    super.initState();
    _target = widget.initialTarget;
  }

  Future<bool> _confirmBroadcastIfNeeded() async {
    if (_target != SpotTestSendTarget.broadcast) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast to all users?'),
        content: Text(
          'This sends the spot-test notification to every device '
          'subscribed to "${PushSpotTestConstants.broadcastFcmTopic}". '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _send() async {
    if (_sending) return;
    if (!await _confirmBroadcastIfNeeded()) return;
    setState(() => _sending = true);
    try {
      const service = SpotTestPushCloudService();
      final outcome = await service.sendSpotTestNotification(
        SpotTestPushRequest(
          title: widget.title,
          body: widget.body,
          target: _target,
          subject: widget.subject,
          topic: widget.topic,
          subtopic: widget.subtopic,
          questionUuid: widget.questionUuid,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!widget.parentContext.mounted) return;
      ScaffoldMessenger.of(
        widget.parentContext,
      ).showSnackBar(SnackBar(content: Text(outcome.userFacingMessage)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Review & send', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<SpotTestSendTarget>(
            segments: const [
              ButtonSegment(
                value: SpotTestSendTarget.self,
                label: Text('My device'),
                icon: Icon(Icons.phone_iphone_outlined, size: 18),
              ),
              ButtonSegment(
                value: SpotTestSendTarget.broadcast,
                label: Text('Broadcast'),
                icon: Icon(Icons.campaign_outlined, size: 18),
              ),
            ],
            selected: {_target},
            onSelectionChanged: _sending
                ? null
                : (s) => setState(() => _target = s.first),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _target == SpotTestSendTarget.self
                ? 'Delivers only to your signed-in device.'
                : 'Delivers to all subscribed devices.',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PushNotificationPreviewCard(title: widget.title, body: widget.body),
          const SizedBox(height: AppSpacing.md),
          _PayloadRow(label: 'Subject', value: widget.subject),
          _PayloadRow(label: 'Topic', value: widget.topic),
          if (widget.subtopic != null && widget.subtopic!.isNotEmpty)
            _PayloadRow(label: 'Subtopic', value: widget.subtopic!),
          _PayloadRow(
            label: 'Question',
            value: widget.questionUuid ?? 'Random from topic/subtopic',
          ),
          if (widget.questionStem != null &&
              widget.questionStem!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.questionStem!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _sending
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _sending ? null : () => unawaited(_send()),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _target == SpotTestSendTarget.broadcast
                              ? 'Broadcast'
                              : 'Send',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayloadRow extends StatelessWidget {
  const _PayloadRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySm())),
        ],
      ),
    );
  }
}
