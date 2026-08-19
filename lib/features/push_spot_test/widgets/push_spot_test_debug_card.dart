import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/database/user_db.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../push_spot_test_launcher.dart';

/// Admin entry to exercise push spot-test flow without FCM.
class PushSpotTestDebugCard extends ConsumerWidget {
  const PushSpotTestDebugCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warningBgDark.withValues(alpha: 0.35)
            : AppColors.warningBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (isDark ? AppColors.warningTextDark : AppColors.warningText)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DEBUG · Push spot test',
            style: AppTextStyles.caption().copyWith(
              color: isDark ? AppColors.warningTextDark : AppColors.warningText,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start a 1-question spot test (same flow as notification tap).',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: () => unawaited(_openSheet(context, ref)),
            child: const Text('Configure & start 1Q test'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PushSpotDebugSheet(parentContext: context, ref: ref),
    );
  }
}

class _PushSpotDebugSheet extends ConsumerStatefulWidget {
  const _PushSpotDebugSheet({
    required this.parentContext,
    required this.ref,
  });

  final BuildContext parentContext;
  final WidgetRef ref;

  @override
  ConsumerState<_PushSpotDebugSheet> createState() =>
      _PushSpotDebugSheetState();
}

class _PushSpotDebugSheetState extends ConsumerState<_PushSpotDebugSheet> {
  final _subTopic = TextEditingController(text: '');
  final _questionUuid = TextEditingController(text: '');
  var _loading = false;
  var _catalogLoading = true;
  String? _catalogError;

  String? _subject;
  String? _topic;
  List<TopicQuestionCount> _topics = const [];
  List<String> _subTopics = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadCatalog());
  }

  @override
  void dispose() {
    _subTopic.dispose();
    _questionUuid.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final db = ref.read(userDatabaseProvider);
      final subjects = SubjectConstants.ordered.map((s) => s.slug).toList();
      var pickedSubject = 'Economy';
      if (!subjects.contains(pickedSubject)) {
        pickedSubject = subjects.isNotEmpty ? subjects.first : '';
      }
      final topics = pickedSubject.isEmpty
          ? <TopicQuestionCount>[]
          : await db.questionsDao.getTopicQuestionCountsForSubject(
              pickedSubject,
            );
      final withQuestions =
          topics.where((t) => t.questionCount > 0).toList();
      final pickedTopic = withQuestions.isNotEmpty
          ? withQuestions.first.topic
          : null;

      if (!mounted) return;
      setState(() {
        _subject = pickedSubject.isEmpty ? null : pickedSubject;
        _topics = withQuestions;
        _topic = pickedTopic;
        _catalogLoading = false;
      });
      if (pickedSubject.isNotEmpty && pickedTopic != null) {
        await _loadSubTopics(pickedSubject, pickedTopic);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = e.toString();
        _catalogLoading = false;
      });
    }
  }

  Future<void> _loadSubTopics(String subject, String topic) async {
    final db = ref.read(userDatabaseProvider);
    final subs = await db.questionsDao.getDistinctSubTopicsForSubjectTopic(
      subject,
      topic,
    );
    if (!mounted) return;
    setState(() => _subTopics = subs);
  }

  Future<void> _onSubjectChanged(String? subject) async {
    if (subject == null) return;
    setState(() {
      _subject = subject;
      _topic = null;
      _topics = const [];
      _subTopics = const [];
      _subTopic.text = '';
    });
    final db = ref.read(userDatabaseProvider);
    final topics = await db.questionsDao.getTopicQuestionCountsForSubject(
      subject,
    );
    final withQuestions = topics.where((t) => t.questionCount > 0).toList();
    if (!mounted) return;
    final first = withQuestions.isNotEmpty ? withQuestions.first.topic : null;
    setState(() {
      _topics = withQuestions;
      _topic = first;
    });
    if (first != null) await _loadSubTopics(subject, first);
  }

  Future<void> _onTopicChanged(String? topic) async {
    if (topic == null || _subject == null) return;
    setState(() {
      _topic = topic;
      _subTopic.text = '';
    });
    await _loadSubTopics(_subject!, topic);
  }

  Future<void> _start() async {
    if (_loading) return;
    final uuid = _questionUuid.text.trim();
    if (uuid.isEmpty && (_subject == null || _topic == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a subject and topic, or enter a question UUID.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      if (mounted) Navigator.of(context).pop();
      await launchPushSpotTest(
        context: widget.parentContext,
        ref: widget.ref,
        subject: _subject ?? '',
        topic: _topic ?? '',
        subTopic: _subTopic.text.trim().isEmpty ? null : _subTopic.text,
        questionUuid: uuid.isEmpty ? null : uuid,
      );
    } catch (e) {
      if (!widget.parentContext.mounted) return;
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(content: Text('Spot test failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Spot test params', style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Topics use catalog names (e.g. Economy · Agriculture), not slugs.',
            style: AppTextStyles.caption().copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_catalogLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_catalogError != null)
            Text(_catalogError!, style: AppTextStyles.bodySm())
          else ...[
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                for (final s in SubjectConstants.ordered)
                  DropdownMenuItem(value: s.slug, child: Text(s.displayName)),
              ],
              onChanged: _onSubjectChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _topic,
              decoration: InputDecoration(
                labelText: 'Topic',
                helperText: _topics.isEmpty
                    ? 'No questions for this subject'
                    : null,
              ),
              items: [
                for (final t in _topics)
                  DropdownMenuItem(
                    value: t.topic,
                    child: Text('${t.topic} (${t.questionCount})'),
                  ),
              ],
              onChanged: _topics.isEmpty ? null : _onTopicChanged,
            ),
            if (_subTopics.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _subTopic.text.isEmpty ? null : _subTopic.text,
                decoration: const InputDecoration(
                  labelText: 'Subtopic (optional)',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Any subtopic'),
                  ),
                  for (final s in _subTopics)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) => setState(() => _subTopic.text = v ?? ''),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _questionUuid,
              decoration: const InputDecoration(
                labelText: 'Question UUID (optional, overrides topic pick)',
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _loading || _catalogLoading ? null : _start,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start 1-question test'),
          ),
        ],
      ),
    );
  }
}
