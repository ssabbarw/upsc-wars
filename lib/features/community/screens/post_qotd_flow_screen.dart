import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart'
    show prefsServiceProvider;
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/question_table_view.dart';
import '../../../shared/widgets/selectable_copy_search_text.dart';
import '../../../shared/widgets/test_config_sheet_widgets.dart';
import '../../history/screens/session_review_screen.dart';
import '../../home/providers/auth_providers.dart';
import '../data/open_challenge_repository.dart' show profileFromFirebaseUser;
import '../data/qotd_local_post_limit.dart';
import '../data/qotd_repository.dart';
import '../domain/entities/community_user.dart';
import '../providers/community_providers.dart';
import '../providers/qotd_providers.dart';
import '../widgets/qotd_before_you_proceed_panel.dart';
import '../widgets/qotd_option_letters_row.dart';
import '../widgets/qotd_post_comment_sheet.dart';

const _kQotdSubjectTileW = 108.0;
const _kQotdSubjectTileH = 48.0;

String _qotdNormLang(String? code) =>
    (code ?? 'en').toLowerCase().trim() == 'hi' ? 'hi' : 'en';

/// Pick subject → shuffle until happy → attempt → read explanation → post with optional comment.
class PostQotdFlowScreen extends HookConsumerWidget {
  const PostQotdFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = useState(0);
    final subjectKey = useState<String?>(null);
    final question = useState<TestQuestion?>(null);
    final picked = useState<String?>(null);
    final drawing = useState(false);
    final prefs = ref.watch(prefsServiceProvider).value;
    final qotdLangOverride = useState<String?>(null);
    final uiLang = _qotdNormLang(
      qotdLangOverride.value ?? prefs?.language ?? 'en',
    );

    final subjectsAsync = ref.watch(subjectTestListProvider);

    Future<void> drawQuestion() async {
      final key = subjectKey.value;
      if (key == null) return;
      drawing.value = true;
      try {
        final uuid = await pickRandomQuestionUuidForQotd(
          db: ref.read(userDatabaseProvider),
          subject: key,
        );
        if (!context.mounted) return;
        if (uuid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No questions found for this subject.'),
            ),
          );
          return;
        }
        final repo = await ref.read(testEngineRepositoryProvider.future);
        final q = await repo.loadStandaloneQuestionByUuid(uuid);
        if (!context.mounted) return;
        if (q == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load that question.')),
          );
          return;
        }
        question.value = q;
        picked.value = null;
      } finally {
        if (context.mounted) drawing.value = false;
      }
    }

    Future<void> startWithSubject() async {
      if (subjectKey.value == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pick a subject first.')));
        return;
      }
      step.value = 1;
      await drawQuestion();
    }

    Future<void> openPostSheet() async {
      final q = question.value;
      if (q == null || picked.value == null) return;

      final posted = await showQotdPostCommentSheet(
        context,
        onPost: (comment) async {
          final user = ref.read(authStateChangesProvider).asData?.value;
          final email = user?.email?.toLowerCase().trim();
          if (email == null || email.isEmpty) {
            throw Exception('You must be signed in.');
          }
          CommunityUser? extraUser;
          try {
            extraUser = await ref
                .read(communityRepositoryProvider)
                .fetchCommunityUserByEmail(email);
          } catch (_) {}

          final profile = profileFromFirebaseUser(
            emailLower: email,
            displayName: extraUser?.name ?? user?.displayName ?? 'UPSC Warrior',
            photoUrl: extraUser?.photoUrl ?? user?.photoURL,
            telegram: extraUser?.telegram,
            instagram: extraUser?.instagram,
            status: extraUser?.status,
          );

          final prefs = await ref.read(prefsServiceProvider.future);
          final maxPerWindow = await ref.read(qotdMaxPostsPerDayProvider.future);
          QotdLocalPostLimit.assertCanPost(prefs, maxPerWindow);
          await ref.read(qotdRepositoryProvider).createPost(
                questionUuid: q.uuid,
                comment: comment,
                correctOption: q.correctOption,
                author: profile,
              );
          QotdLocalPostLimit.recordPost(prefs);
          ref.invalidate(qotdFeedNotifierProvider);
        },
      );
      if (!context.mounted) return;
      if (posted) {
        unawaited(
          logActivationMilestoneOnce(
            ref,
            ActivationMilestones.firstQotdPosted,
          ),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Posted to QOTD')));
        context.pop();
      }
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.surfaceSecondaryDark
          : AppColors.surfaceSecondaryLight,
      appBar: AppBar(
        title: Text('Post QOTD', style: AppTextStyles.h3()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: ToggleButtons(
                isSelected: [uiLang == 'en', uiLang == 'hi'],
                onPressed: (i) =>
                    qotdLangOverride.value = i == 0 ? 'en' : 'hi',
                constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('EN'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('HI'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: step.value == 0
          ? subjectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Could not load subjects: $e',
                    style: AppTextStyles.bodyMd(),
                  ),
                ),
              ),
              data: (subjects) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: isDark
                          ? AppColors.surfacePrimaryDark
                          : AppColors.surfacePrimaryLight,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Pick your subject',
                              style: AppTextStyles.h1().copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'One random question from your bank · shuffle, attempt, '
                              'then post to Community QOTD.',
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Subject',
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    for (final s in subjects)
                                      SizedBox(
                                        width: _kQotdSubjectTileW,
                                        height: _kQotdSubjectTileH,
                                        child: SubjectPickChipTile(
                                          label: s.displayName,
                                          selected:
                                              subjectKey.value == s.subject,
                                          onTap: () =>
                                              subjectKey.value = s.subject,
                                          scheme: scheme,
                                          isDark: isDark,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            QotdBeforeYouProceedPanel(scheme: scheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Material(
                    elevation: 8,
                    shadowColor: AppColors.gray900.withValues(alpha: 0.08),
                    color: isDark
                        ? AppColors.surfacePrimaryDark
                        : AppColors.surfacePrimaryLight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: SafeArea(
                        top: false,
                        child: FilledButton(
                          onPressed: subjectKey.value == null || drawing.value
                              ? null
                              : () => startWithSubject(),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: Text(
                            'Continue to question',
                            style: AppTextStyles.label().copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: question.value == null && drawing.value
                    ? const Center(child: CircularProgressIndicator())
                    : question.value == null
                        ? Center(
                            child: Text(
                              'No question loaded.',
                              style: AppTextStyles.bodyMd(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _PracticeStep(
                                  scheme: scheme,
                                  question: question.value!,
                                  uiLanguage: uiLang,
                                  picked: picked.value,
                                  drawing: drawing.value,
                                  onShuffle: () async {
                                    await drawQuestion();
                                  },
                                  onPick: (k) => picked.value = k,
                                  onPost: openPostSheet,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
    );
  }
}

class _PracticeStep extends StatelessWidget {
  const _PracticeStep({
    required this.scheme,
    required this.question,
    required this.uiLanguage,
    required this.picked,
    required this.drawing,
    required this.onShuffle,
    required this.onPick,
    required this.onPost,
  });

  final ColorScheme scheme;
  final TestQuestion question;
  final String uiLanguage;
  final String? picked;
  final bool drawing;
  final Future<void> Function() onShuffle;
  final ValueChanged<String> onPick;
  final Future<void> Function() onPost;

  @override
  Widget build(BuildContext context) {
    final isHi = uiLanguage == 'hi';
    final stem = (isHi ? question.displayTextHi : question.displayText).trim();
    final oa = (isHi ? question.optionAHi : question.optionA).trim();
    final ob = (isHi ? question.optionBHi : question.optionB).trim();
    final oc = (isHi ? question.optionCHi : question.optionC).trim();
    final od = (isHi ? question.optionDHi : question.optionD).trim();
    final hasTable = question.hasTable;
    final optionsBody = '(A) $oa\n(B) $ob\n(C) $oc\n(D) $od';
    final nonTableBlock = () {
      final buf = StringBuffer();
      if (stem.isNotEmpty) buf.writeln(stem);
      buf.writeln();
      buf.writeln('(A) $oa');
      buf.writeln('(B) $ob');
      buf.writeln('(C) $oc');
      buf.writeln('(D) $od');
      return buf.toString().trim();
    }();

    final finalExplanation = isHi
        ? question.finalExplanationHi
        : question.finalExplanation;
    final statementAnalysis = isHi
        ? question.statementAnalysisHi
        : question.statementAnalysis;
    final eliminationLogic = isHi
        ? question.eliminationLogicHi
        : question.eliminationLogic;
    final strongDistractor = isHi
        ? question.strongDistractorHi
        : question.strongDistractor;
    final upscTrapExplanation = isHi
        ? question.upscTrapExplanationHi
        : question.upscTrapExplanation;

    final hasExplanation =
        (finalExplanation ?? '').trim().isNotEmpty ||
        statementAnalysis.isNotEmpty ||
        eliminationLogic.isNotEmpty ||
        (strongDistractor ?? '').trim().isNotEmpty ||
        (upscTrapExplanation ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: drawing ? null : () => onShuffle(),
                        icon: drawing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shuffle),
                        label: Text(drawing ? 'Loading…' : 'Shuffle question'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (!hasTable)
                  SelectableCopySearchText(
                    nonTableBlock,
                    style: AppTextStyles.question().copyWith(
                      color: scheme.onSurface,
                    ),
                  )
                else ...[
                  if (stem.isNotEmpty)
                    SelectableCopySearchText(
                      stem,
                      style: AppTextStyles.question().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  Builder(
                    builder: (_) {
                      final td =
                          isHi ? question.tableDataHi : question.tableData;
                      final tdf =
                          td ?? question.tableDataHi ?? question.tableData;
                      if (tdf == null) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (stem.isNotEmpty)
                            const SizedBox(height: AppSpacing.sm),
                          QuestionTableView(table: tdf),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SelectableCopySearchText(
                    optionsBody,
                    style: AppTextStyles.question().copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QotdOptionLettersRow(
                correctOption: question.correctOption,
                picked: picked,
                busy: drawing,
                onPick: onPick,
              ),
              if (picked != null) ...[
                const SizedBox(height: AppSpacing.md),
                if (hasExplanation)
                  OutlinedButton.icon(
                    onPressed: () {
                      final pick = picked!.toLowerCase().trim();
                      final ok =
                          pick == question.correctOption.toLowerCase().trim();
                      final forReview = question.copyWith(
                        selectedOption: pick,
                        status: ok ? 'correct' : 'wrong',
                      );
                      context.push(
                        '/community/qotd/explanation',
                        extra: SingleQuestionReviewArgs(
                          question: forReview,
                          initialUiLanguage: uiLanguage,
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Read explanation'),
                  ),
                if (hasExplanation) const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => onPost(),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Post this question'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
