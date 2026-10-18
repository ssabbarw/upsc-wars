import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/providers/catalog_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../history/widgets/explanation_card.dart';
import '../../providers/series_sample_question_provider.dart';
import 'series_tone.dart';

/// Opens the sample question. Resolves to `true` when the reader tapped the
/// unlock button at the bottom.
Future<bool> showSeriesSampleQuestionSheet(BuildContext context) async {
  final unlock = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, controller) => _SampleQuestionBody(controller: controller),
    ),
  );
  return unlock ?? false;
}

class _SampleQuestionBody extends HookConsumerWidget {
  const _SampleQuestionBody({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(seriesSampleQuestionProvider);
    final isHindi = ref.watch(appLanguageProvider).asData?.value == 'hi';
    final selected = useState<String?>(null);
    final revealed = useState(false);

    final sample = async.asData?.value;
    if (sample == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final content = sample.contentFor(hindi: isHindi);
    final correct = sample.correctOption;
    final pickedRight = selected.value == correct;

    void pick(String key) {
      if (revealed.value) return;
      selected.value = key;
      revealed.value = true;
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Row(
          children: [
            TonePill(
              label: sample.isCurrentAffairs
                  ? "Yesterday's current affairs"
                  : 'Sample question',
              tone: sample.isCurrentAffairs ? SeriesTone.blue : SeriesTone.purple,
              icon: sample.isCurrentAffairs
                  ? Icons.newspaper_rounded
                  : Icons.menu_book_rounded,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                sample.subjectLabel,
                style: AppTextStyles.labelSm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'This is how every question in the series is explained.',
          style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(content.stem, style: AppTextStyles.question()),
        const SizedBox(height: AppSpacing.lg),
        for (final key in const ['a', 'b', 'c', 'd'])
          _OptionTile(
            letter: key.toUpperCase(),
            text: content.options[key] ?? '',
            state: !revealed.value
                ? _OptionState.idle
                : key == correct
                ? _OptionState.correct
                : key == selected.value
                ? _OptionState.wrong
                : _OptionState.dimmed,
            onTap: () => pick(key),
          ),
        if (!revealed.value) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tap an option to see the answer and explanation.',
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => revealed.value = true,
                child: const Text('Just show the answer'),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          _ResultBanner(
            attempted: selected.value != null,
            right: pickedRight,
            correctLetter: correct.toUpperCase(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: ExplanationCard(
              translation: content.translation,
              showStatements: content.hasStatements,
              trackViews: false,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Every question in the series comes with this level of detail: '
            'English and हिन्दी.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: const Text('Unlock all tests'),
          ),
        ],
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = seriesToneColors(SeriesTone.green, isDark: isDark);
    final red = seriesToneColors(SeriesTone.red, isDark: isDark);

    final Color border;
    final Color fill;
    final Color badgeFill;
    final Color badgeText;
    switch (state) {
      case _OptionState.correct:
        border = green.accent;
        fill = green.bg;
        badgeFill = green.accent;
        badgeText = AppColors.onPrimary;
      case _OptionState.wrong:
        border = red.accent;
        fill = red.bg;
        badgeFill = red.accent;
        badgeText = AppColors.onPrimary;
      case _OptionState.idle:
      case _OptionState.dimmed:
        border = isDark ? AppColors.borderDark : AppColors.borderLight;
        fill = scheme.surface;
        badgeFill = scheme.surfaceContainerHighest;
        badgeText = scheme.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardListGap),
      child: Opacity(
        opacity: state == _OptionState.dimmed ? 0.55 : 1,
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: state == _OptionState.idle ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: border,
                  width: state == _OptionState.correct ||
                          state == _OptionState.wrong
                      ? 1.4
                      : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeFill,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      letter,
                      style: AppTextStyles.labelSm().copyWith(
                        color: badgeText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(text, style: AppTextStyles.option())),
                  if (state == _OptionState.correct)
                    Icon(Icons.check_circle_rounded, color: green.accent),
                  if (state == _OptionState.wrong)
                    Icon(Icons.cancel_rounded, color: red.accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.attempted,
    required this.right,
    required this.correctLetter,
  });

  final bool attempted;
  final bool right;
  final String correctLetter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = right ? SeriesTone.green : SeriesTone.red;
    final c = seriesToneColors(attempted ? tone : SeriesTone.green, isDark: isDark);
    final label = !attempted
        ? 'Correct answer: $correctLetter'
        : right
        ? 'Correct! Answer: $correctLetter'
        : 'Not quite. The answer is $correctLetter';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            right || !attempted
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color: c.accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label().copyWith(
                color: c.fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
