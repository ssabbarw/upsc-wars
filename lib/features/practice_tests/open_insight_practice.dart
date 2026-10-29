import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/subject_constants.dart';
import '../../core/domain/entities/session_config.dart';
import '../../core/layout/system_insets.dart';
import '../../core/providers/catalog_providers.dart';
import '../../core/providers/user_database_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/l10n.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/test_config_bottom_sheet.dart';
import '../history/screens/question_list_review_screen.dart';
import 'domain/insight_improve.dart';
import 'domain/subject_trap_stat.dart';
import 'providers/practice_catalog_provider.dart';
import 'providers/practice_subject_insights_provider.dart';

enum InsightDrillKind { topic, trap }

enum InsightDrillIntent { revise, improve }

class InsightDrillTarget {
  const InsightDrillTarget.topic({
    required this.subject,
    required this.topicKey,
    required this.title,
    required this.sureLens,
  }) : trap = null,
       kind = InsightDrillKind.topic;

  const InsightDrillTarget.trap({
    required this.subject,
    required this.trap,
    required this.title,
  }) : topicKey = null,
       sureLens = true,
       kind = InsightDrillKind.trap;

  final InsightDrillKind kind;
  final String subject;
  final String title;
  final String? topicKey;
  final SubjectTrapStat? trap;
  final bool sureLens;
}

Future<void> showInsightDrillSheet(
  BuildContext context, {
  required InsightDrillTarget target,
  required InsightDrillIntent intent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        sheetBottomPadding(ctx, base: AppSpacing.lg),
      ),
      child: _InsightDrillSheet(target: target, intent: intent),
    ),
  );
}

class _InsightDrillSheet extends ConsumerStatefulWidget {
  const _InsightDrillSheet({required this.target, required this.intent});

  final InsightDrillTarget target;
  final InsightDrillIntent intent;

  @override
  ConsumerState<_InsightDrillSheet> createState() => _InsightDrillSheetState();
}

class _InsightDrillSheetState extends ConsumerState<_InsightDrillSheet> {
  late InsightDrillIntent _intent = widget.intent;
  InsightDrillPool? _pool;
  Object? _error;
  var _loading = true;
  var _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await ref.read(practiceCatalogProvider.future);
      final db = ref.read(userDatabaseProvider);
      final target = widget.target;
      final pool = target.kind == InsightDrillKind.topic
          ? await loadTopicDrillPool(
              db,
              subject: target.subject,
              topic: target.topicKey!,
              sureLens: target.sureLens,
              seasonStart: catalog.season.start,
            )
          : await loadTrapDrillPool(
              db,
              subject: target.subject,
              trapType: target.trap!.trapType,
              seasonStart: catalog.season.start,
            );
      if (!mounted) return;
      setState(() {
        _pool = pool;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<String> get _uuids {
    final pool = _pool;
    if (pool == null) return const [];
    return _intent == InsightDrillIntent.revise
        ? pool.reviseUuids
        : pool.improveUuids;
  }

  Future<void> _start(List<String> uuids) async {
    if (uuids.isEmpty || _starting) return;
    setState(() => _starting = true);
    try {
      if (_intent == InsightDrillIntent.revise) {
        await _startRevision(uuids);
      } else {
        await _startImprove(uuids);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showText(context, context.l10n.dzStartFailed(e.toString()));
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _startRevision(List<String> uuids) async {
    final create = await ref.read(createSessionUseCaseProvider.future);
    final load = await ref.read(loadSessionUseCaseProvider.future);
    final repo = await ref.read(testEngineRepositoryProvider.future);
    final lang = await ref.read(appLanguageProvider.future);
    final target = widget.target;
    String? id;
    try {
      id = await create.execute(
        SessionConfig(
          subject: target.subject,
          topic: target.topicKey,
          mode: 'learning',
          questionCount: uuids.length,
          isTimed: false,
          timeLimitSecs: null,
          language: lang,
          specificQuestionUuids: uuids,
          analyticsFeatureKey: target.kind == InsightDrillKind.trap
              ? 'practice_trap_revise'
              : 'practice_topic_revise',
          dangerReviseHistoryConfidence: target.sureLens
              ? 'very_sure'
              : 'somewhat_sure',
        ),
      );
      final active = await load.execute(id);
      await repo.discardSession(id);
      id = null;
      if (!mounted) return;
      final router = GoRouter.of(context);
      final l10n = context.l10n;
      Navigator.pop(context);
      await router.push(
        '/question-review',
        extra: QuestionListReviewArgs(
          questions: active.questions,
          title: l10n.commonRevise,
          progressRight: target.title,
        ),
      );
    } finally {
      if (id != null) {
        try {
          await repo.discardSession(id);
        } catch (_) {}
      }
    }
  }

  Future<void> _startImprove(List<String> uuids) => _openImproveConfig(uuids);

  Future<void> _openImproveConfig(List<String> uuids) async {
    if (uuids.isEmpty || !mounted) return;
    final target = widget.target;
    final l10n = context.l10n;
    final overlayContext = Navigator.of(context).context;
    final subjectName =
        SubjectConstants.bySlug(target.subject)?.displayName ?? target.subject;
    final short = uuids.length < kInsightImproveSize;
    Navigator.pop(context);
    await Future<void>.delayed(Duration.zero);
    if (!overlayContext.mounted) return;
    await showTestConfigBottomSheet(
      context: overlayContext,
      useRootNavigator: true,
      args: TestConfigSheetArgs(
        subject: target.subject,
        topic: target.topicKey,
        subjectDisplayName: subjectName,
        topicDisplayName: target.kind == InsightDrillKind.topic
            ? target.title
            : null,
        fixedQuestionSetLabel: short
            ? l10n.practiceDrillImproveShort(uuids.length, kInsightImproveSize)
            : (target.kind == InsightDrillKind.trap
                  ? target.title
                  : l10n.practiceImproveScore),
        availableQuestionCount: uuids.length,
        topicCountWhenSubjectOnly: target.topicKey == null ? 1 : 0,
        lockedQuestionCount: uuids.length,
        specificQuestionUuids: uuids,
        analyticsFeatureKey: target.kind == InsightDrillKind.trap
            ? kPracticeTrapImproveKey
            : kPracticeTopicImproveKey,
        onSessionCreated: (id) {
          GoRouter.of(overlayContext).push('/test/$id');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pool = _pool;
    final reviseN = pool?.reviseUuids.length ?? 0;
    final improveN = pool?.improveUuids.length ?? 0;
    final n = _uuids.length;
    final shortImprove =
        _intent == InsightDrillIntent.improve &&
        improveN > 0 &&
        improveN < kInsightImproveSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _intent == InsightDrillIntent.revise
              ? l10n.practiceReviseIncorrects
              : l10n.practiceImproveScore,
          style: AppTextStyles.h3().copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.target.title,
          style: AppTextStyles.label().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          TextButton(onPressed: _load, child: Text(l10n.commonRetry))
        else ...[
          Text(
            _body(l10n, n: n, shortImprove: shortImprove),
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (n > 0)
            FilledButton(
              onPressed: _starting ? null : () => _start(_uuids),
              child: _starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _intent == InsightDrillIntent.revise
                          ? l10n.practiceStartRevision
                          : l10n.commonContinue,
                    ),
            ),
          if (_intent == InsightDrillIntent.improve &&
              shortImprove &&
              reviseN > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: _starting
                  ? null
                  : () => setState(() => _intent = InsightDrillIntent.revise),
              child: Text(l10n.practiceReviseExistingInstead),
            ),
          ],
          if (_intent == InsightDrillIntent.improve &&
              improveN == 0 &&
              reviseN > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _starting
                  ? null
                  : () => setState(() => _intent = InsightDrillIntent.revise),
              child: Text(l10n.practiceReviseExistingInstead),
            ),
          ],
          if (_intent == InsightDrillIntent.revise &&
              reviseN == 0 &&
              improveN > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _starting
                  ? null
                  : () => setState(() => _intent = InsightDrillIntent.improve),
              child: Text(l10n.practiceImproveInstead),
            ),
          ],
        ],
      ],
    );
  }

  String _body(
    AppLocalizations l10n, {
    required int n,
    required bool shortImprove,
  }) {
    final target = widget.target;
    if (_intent == InsightDrillIntent.revise) {
      if (n == 0) return l10n.practiceDrillReviseEmpty;
      if (target.kind == InsightDrillKind.trap) {
        return l10n.practiceDrillReviseTrap(n);
      }
      return target.sureLens
          ? l10n.practiceDrillReviseTopicSure(n)
          : l10n.practiceDrillReviseTopicGuess(n);
    }
    if (n == 0) return l10n.practiceDrillImproveEmpty;
    final lead = target.kind == InsightDrillKind.trap
        ? l10n.practiceDrillImproveTrap
        : l10n.practiceDrillImproveTopic;
    if (shortImprove) {
      return '$lead\n\n${l10n.practiceDrillImproveShort(n, kInsightImproveSize)}';
    }
    return lead;
  }
}
