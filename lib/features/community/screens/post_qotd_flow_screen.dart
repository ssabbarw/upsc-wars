import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart' show prefsServiceProvider;
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../../../shared/widgets/en_hi_language_toggle.dart';
import '../../../shared/widgets/question_table_view.dart';
import '../../../shared/widgets/selectable_copy_search_text.dart';
import '../../../shared/widgets/test_config_sheet_widgets.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../history/screens/session_review_screen.dart';
import '../data/qotd_repository.dart';
import '../widgets/qotd_before_you_proceed_panel.dart';
import '../widgets/qotd_option_letters_row.dart';
import '../widgets/share_qotd_sheet.dart';
import '../../../l10n/l10n.dart';

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
          AppToast.showText(context, context.l10n.qotdNoQuestions);
          return;
        }
        final repo = await ref.read(testEngineRepositoryProvider.future);
        final q = await repo.loadStandaloneQuestionByUuid(uuid);
        if (!context.mounted) return;
        if (q == null) {
          AppToast.showText(context, context.l10n.qotdLoadFailed);
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
        AppToast.showText(context, context.l10n.qotdPickFirst);
        return;
      }
      step.value = 1;
      await drawQuestion();
    }

    Future<void> openPostSheet() async {
      final q = question.value;
      if (q == null || picked.value == null) return;

      final posted = await showShareQotdSheet(
        context: context,
        ref: ref,
        questionUuid: q.uuid,
        correctOption: q.correctOption,
      );
      if (!context.mounted) return;
      if (posted) context.pop();
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
              child: EnHiLanguageToggle(
                language: uiLang,
                onChanged: (v) => qotdLangOverride.value = v,
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
                    context.l10n.qotdSubjectsFailed(e.toString()),
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
                              context.l10n.ocPickSubject,
                              style: AppTextStyles.h1().copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              context.l10n.qotdIntro,
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              context.l10n.commonSubject,
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
                            context.l10n.qotdContinue,
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
                          context.l10n.qotdNoneLoaded,
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
    final stemStyle = context.readingFont(
      AppTextStyles.question().copyWith(color: scheme.onSurface),
    );
    final optionStyle = AppTextStyles.question().copyWith(
      color: scheme.onSurface,
    );

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
                        label: Text(
                          drawing
                              ? context.l10n.commonLoading
                              : context.l10n.qotdShuffle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (!hasTable) ...[
                  if (stem.isNotEmpty)
                    SelectableCopySearchText(stem, style: stemStyle),
                  if (stem.isNotEmpty) const SizedBox(height: AppSpacing.md),
                  SelectableCopySearchText(optionsBody, style: optionStyle),
                ] else ...[
                  if (stem.isNotEmpty)
                    SelectableCopySearchText(stem, style: stemStyle),
                  Builder(
                    builder: (_) {
                      final td = isHi
                          ? question.tableDataHi
                          : question.tableData;
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
                  SelectableCopySearchText(optionsBody, style: optionStyle),
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
                    label: Text(context.l10n.qotdReadExpl),
                  ),
                if (hasExplanation) const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => onPost(),
                  icon: const Icon(Icons.send_outlined),
                  label: Text(context.l10n.qotdPostThis),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
