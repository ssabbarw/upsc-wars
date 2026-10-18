import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../../../shared/widgets/question_table_view.dart';
import '../../../shared/widgets/selectable_copy_search_text.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/open_challenge_repository.dart' show profileFromFirebaseUser;
import '../domain/qotd_models.dart';
import '../domain/qotd_reactions.dart';
import '../providers/qotd_providers.dart';
import 'qotd_option_letters_row.dart';
import 'qotd_post_answerers_section.dart';
import '../../history/screens/session_review_screen.dart';
import 'admin_bot_label.dart';
import '../../../l10n/l10n.dart';

String _qotdLiveUntilFormatted(DateTime at) {
  return DateFormat('d MMM, h:mm a').format(at.toLocal());
}

String _qotdPostedFriendlyAgo(DateTime? posted) {
  if (posted == null) return appL10n.commonJustNow;
  final diff = DateTime.now().difference(posted);
  if (diff.inSeconds < 60) return appL10n.commonJustNow;
  if (diff.inMinutes < 60) return appL10n.commonMinAgo(diff.inMinutes);
  if (diff.inHours < 24) return appL10n.commonHrAgo(diff.inHours);
  if (diff.inDays < 7) return appL10n.commonDayAgo(diff.inDays);
  return appL10n.commonWeekAgo((diff.inDays / 7).floor());
}

String _qotdCompactMeta(QotdPost post) {
  final ago = _qotdPostedFriendlyAgo(post.createdAt);
  if (post.createdAt == null) return ago;
  if (post.isExpired) return '$ago · ended';
  final until = post.liveUntil;
  if (until == null) return ago;
  return '$ago · live till ${_qotdLiveUntilFormatted(until)}';
}

class QotdPostCard extends ConsumerStatefulWidget {
  const QotdPostCard({super.key, required this.post, required this.uiLanguage});

  final QotdPost post;
  final String uiLanguage;

  @override
  ConsumerState<QotdPostCard> createState() => _QotdPostCardState();
}

class _QotdPostCardState extends ConsumerState<QotdPostCard> {
  int _correct = 0;
  int _wrong = 0;
  Map<String, int> _reactions = {};
  String? _myPick;
  String? _myReactionId;
  int _reactionRequestId = 0;
  bool _reactionSaving = false;
  bool _tileExpanded = false;

  /// Display language for stem / options / table (EN or HI).
  /// This follows the tab-level `uiLanguage` (no per-card override).
  late String _displayLang;

  static String _normUiLang(String? code) =>
      (code ?? 'en').toLowerCase().trim() == 'hi' ? 'hi' : 'en';

  @override
  void initState() {
    super.initState();
    _displayLang = _normUiLang(widget.uiLanguage);
    _correct = widget.post.correctCount;
    _wrong = widget.post.wrongCount;
    _reactions = Map<String, int>.from(widget.post.reactionCounts);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateMine());
  }

  @override
  void didUpdateWidget(covariant QotdPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _correct = widget.post.correctCount;
      _wrong = widget.post.wrongCount;
      _reactions = Map<String, int>.from(widget.post.reactionCounts);
      _myPick = null;
      _myReactionId = null;
      _tileExpanded = false;
      _displayLang = _normUiLang(widget.uiLanguage);
      _hydrateMine();
    } else if (oldWidget.uiLanguage != widget.uiLanguage) {
      _displayLang = _normUiLang(widget.uiLanguage);
    }
  }

  Future<void> _hydrateMine() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) return;
    final repo = ref.read(qotdRepositoryProvider);
    try {
      final pick = await repo.userAttemptPick(postId: widget.post.id, uid: uid);
      final rid = await repo.reactionIdForUser(
        postId: widget.post.id,
        uid: uid,
      );
      if (!mounted) return;
      setState(() {
        _myPick = pick;
        _myReactionId = rid;
      });
    } catch (_) {}
  }

  Future<void> _onLetter(String letter) async {
    if (_myPick != null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final postId = widget.post.id;
    final pick = letter.toLowerCase().trim();
    final correct = widget.post.correctOption.toLowerCase().trim();
    final isCorrectGuess = pick == correct;

    final rollbackPick = _myPick;
    final rollbackCorrect = _correct;
    final rollbackWrong = _wrong;

    setState(() {
      _myPick = letter;
      _correct = _correct + (isCorrectGuess ? 1 : 0);
      _wrong = _wrong + (isCorrectGuess ? 0 : 1);
    });

    try {
      final repo = ref.read(qotdRepositoryProvider);
      final authUser = FirebaseAuth.instance.currentUser;
      final em = authUser?.email?.toLowerCase().trim();
      final authorSnapshot = (em != null && em.isNotEmpty)
          ? profileFromFirebaseUser(
              emailLower: em,
              displayName: authUser!.displayName ?? 'UPSC Warrior',
              photoUrl: authUser.photoURL,
            )
          : null;
      final r = await repo.submitAttempt(
        postId: postId,
        uid: uid,
        pickedOption: letter,
        correctOption: widget.post.correctOption,
        author: authorSnapshot,
      );
      if (!mounted || widget.post.id != postId) return;
      if (!r.alreadyAttempted) {
        unawaited(
          logActivationMilestoneOnce(
            ref,
            ActivationMilestones.firstQotdAttempt,
          ),
        );
      }
      setState(() {
        _correct = r.correctCount;
        _wrong = r.wrongCount;
      });
    } catch (e) {
      if (!mounted || widget.post.id != postId) return;
      setState(() {
        _myPick = rollbackPick;
        _correct = rollbackCorrect;
        _wrong = rollbackWrong;
      });
      AppToast.showText(context, 'Could not save attempt: $e');
    }
  }

  Future<void> _onReactionTap(String reactionId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _myReactionId != null || _reactionSaving) return;
    final rollbackReactions = Map<String, int>.from(_reactions);
    final id = ++_reactionRequestId;
    final label = _reactionLabel(reactionId);
    final optimistic = Map<String, int>.from(_reactions);
    optimistic[reactionId] = (optimistic[reactionId] ?? 0) + 1;
    setState(() {
      _reactionSaving = true;
      _reactions = optimistic;
      _myReactionId = reactionId;
    });
    AppToast.showText(context, 'You reacted: $label');
    try {
      final repo = ref.read(qotdRepositoryProvider);
      await repo.setUserReaction(
        postId: widget.post.id,
        uid: uid,
        reactionId: reactionId,
      );
      if (!mounted || id != _reactionRequestId) return;
      final next = await repo.reactionCounts(widget.post.id);
      final mine = await repo.reactionIdForUser(
        postId: widget.post.id,
        uid: uid,
      );
      if (!mounted || id != _reactionRequestId) return;
      setState(() {
        _reactions = next;
        _myReactionId = mine;
        _reactionSaving = false;
      });
    } catch (e) {
      if (!mounted || id != _reactionRequestId) return;
      setState(() {
        _reactions = rollbackReactions;
        _myReactionId = null;
        _reactionSaving = false;
      });
      AppToast.showText(context, 'Could not update reaction: $e');
    }
  }

  String _reactionLabel(String id) {
    for (final o in qotdReactionOptions) {
      if (o.id == id) return o.label;
    }
    return id;
  }

  String _stemPreviewLine(TestQuestion q) {
    final isHi = _displayLang == 'hi';
    final stem = (isHi ? q.displayTextHi : q.displayText).trim();
    if (stem.isEmpty) return 'Tap to expand and view the full question.';
    final oneLine = stem.split(RegExp(r'\s+')).join(' ');
    if (oneLine.length <= 96) return oneLine;
    return '${oneLine.substring(0, 96)}…';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qAsync = ref.watch(
      qotdQuestionByUuidProvider(widget.post.questionUuid),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: qAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Could not load question.',
            style: AppTextStyles.bodyMd(),
          ),
        ),
        data: (vm) {
          if (vm == null) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'This question is not available in your offline catalog.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return _expandableCard(context, scheme, vm.question);
        },
      ),
    );
  }

  Widget _reactionChips(ColorScheme scheme) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final opt in qotdReactionOptions)
          Tooltip(
            message: opt.label,
            child: Material(
              color: _myReactionId == opt.id
                  ? scheme.primaryContainer
                  : scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: InkWell(
                onTap: (_myReactionId != null || _reactionSaving)
                    ? null
                    : () => _onReactionTap(opt.id),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${_reactions[opt.id] ?? 0}',
                        style: AppTextStyles.labelSm().copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _catalogMetaLines(ColorScheme scheme, TestQuestion q, bool expanded) {
    final cap = AppTextStyles.caption().copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Text(
      'Subject · ${q.subject}   Topic · ${q.topic}',
      style: cap,
      maxLines: expanded ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );
  }

  Widget _expandableCard(
    BuildContext context,
    ColorScheme scheme,
    TestQuestion q,
  ) {
    final me = FirebaseAuth.instance.currentUser;
    final authorLabel = displayNameForViewer(
      name: widget.post.authorName,
      viewerEmail: me?.email,
      subjectEmail: widget.post.authorEmail,
    );
    final preview = _stemPreviewLine(q);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          setState(() => _tileExpanded = expanded);
        },
        maintainState: true,
        expandedAlignment: Alignment.topCenter,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        tilePadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TappableCircularAvatar(
                  imageUrl: widget.post.authorPhotoUrl,
                  displayName: authorLabel,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              authorLabel,
                              style: AppTextStyles.label(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AdminBotLabel(email: widget.post.authorEmail),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.post.comment.trim().isEmpty
                            ? '—'
                            : widget.post.comment,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.post.createdAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _QotdMetaRow(
                scheme: scheme,
                icon: widget.post.isExpired
                    ? Icons.timer_off_outlined
                    : Icons.schedule_rounded,
                text: _qotdCompactMeta(widget.post),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _catalogMetaLines(scheme, q, _tileExpanded),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'How did it feel?',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _reactionChips(scheme),
            if (_myReactionId != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You reacted: ${_reactionLabel(_myReactionId!)}',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Question',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: _tileExpanded
            ? null
            : Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurface,
                ),
              ),
        children: [_questionBody(context, scheme, q)],
      ),
    );
  }

  Widget _questionBody(
    BuildContext context,
    ColorScheme scheme,
    TestQuestion q,
  ) {
    final isHi = _displayLang == 'hi';
    final stem = (isHi ? q.displayTextHi : q.displayText).toString().trim();
    final oa = (isHi ? q.optionAHi : q.optionA).toString().trim();
    final ob = (isHi ? q.optionBHi : q.optionB).toString().trim();
    final oc = (isHi ? q.optionCHi : q.optionC).toString().trim();
    final od = (isHi ? q.optionDHi : q.optionD).toString().trim();
    final hasTable = q.hasTable;
    final optionsBody = '(A) $oa\n(B) $ob\n(C) $oc\n(D) $od';
    final questionStyle = AppTextStyles.question().copyWith(
      color: scheme.onSurface,
    );
    final stemStyle = context.readingFont(questionStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_myPick == null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Attempt this question to see the explanation.',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (!hasTable) ...[
          if (stem.isNotEmpty) SelectableCopySearchText(stem, style: stemStyle),
          if (stem.isNotEmpty) const SizedBox(height: AppSpacing.md),
          SelectableCopySearchText(optionsBody, style: questionStyle),
        ] else ...[
          if (stem.isNotEmpty) SelectableCopySearchText(stem, style: stemStyle),
          Builder(
            builder: (_) {
              final td = isHi ? q.tableDataHi : q.tableData;
              final tdf = td ?? q.tableDataHi ?? q.tableData;
              if (tdf == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (stem.isNotEmpty) const SizedBox(height: AppSpacing.sm),
                  QuestionTableView(table: tdf),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SelectableCopySearchText(optionsBody, style: questionStyle),
        ],
        if (!hasTable) const SizedBox(height: AppSpacing.md),
        QotdOptionLettersRow(
          correctOption: widget.post.correctOption,
          picked: _myPick,
          onPick: _onLetter,
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: InkWell(
            onTap: () {
              showQotdAnswerersBottomSheet(
                context,
                ref,
                postId: widget.post.id,
                statsLine: '$_correct got it right · $_wrong got it wrong',
              );
            },
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_correct got it right · $_wrong got it wrong',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_myPick != null) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: () {
              final pick = _myPick!.toLowerCase().trim();
              final ok = pick == q.correctOption.toLowerCase().trim();
              final forReview = q.copyWith(
                selectedOption: pick,
                status: ok ? 'correct' : 'wrong',
              );
              context.push(
                '/community/qotd/explanation',
                extra: SingleQuestionReviewArgs(
                  question: forReview,
                  initialUiLanguage: _displayLang,
                ),
              );
            },
            child: const Text('View explanation'),
          ),
        ],
      ],
    );
  }
}

class _QotdMetaRow extends StatelessWidget {
  const _QotdMetaRow({
    required this.icon,
    required this.text,
    required this.scheme,
  });

  final IconData icon;
  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
