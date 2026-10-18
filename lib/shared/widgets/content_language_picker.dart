import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/providers/app_language_helpers.dart';
import '../../core/providers/prefs_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/l10n.dart';

/// Sample bilingual MCQ used only for the language-choice preview.
class ContentLanguagePreviewSample {
  const ContentLanguagePreviewSample({
    required this.en,
    required this.hi,
    required this.optionsEn,
    required this.optionsHi,
  });

  final String en;
  final String hi;
  final List<String> optionsEn;
  final List<String> optionsHi;

  static const standard = ContentLanguagePreviewSample(
    en:
        'Which of the following is/are correct regarding the '
        'Fundamental Rights in the Indian Constitution?\n\n'
        '1. They are absolute and cannot be restricted.\n'
        '2. They are enforceable by the courts.',
    hi:
        'भारतीय संविधान में मौलिक अधिकारों के संबंध में '
        'निम्नलिखित में से कौन सा/से सही है/हैं?\n\n'
        '1. ये निरपेक्ष हैं और इन पर कोई प्रतिबंध नहीं लगाया जा सकता।\n'
        '2. ये न्यायालयों द्वारा प्रवर्तनीय हैं।',
    optionsEn: [
      '1 only',
      '2 only',
      'Both 1 and 2',
      'Neither 1 nor 2',
    ],
    optionsHi: [
      'केवल 1',
      'केवल 2',
      '1 और 2 दोनों',
      'न तो 1 और न ही 2',
    ],
  );
}

/// Compact two-option content language picker with a live preview.
///
/// - **English** — app chrome and question content in English
/// - **Hindi** — app chrome stays English; questions/explanations in Hindi
class ContentLanguagePicker extends StatelessWidget {
  const ContentLanguagePicker({
    super.key,
    required this.language,
    required this.onChanged,
    this.sample = ContentLanguagePreviewSample.standard,
  });

  /// `'en'` or `'hi'`.
  final String language;
  final ValueChanged<String> onChanged;
  final ContentLanguagePreviewSample sample;

  bool get _isHindi => language == 'hi';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _OptionChip(
                selected: !_isHindi,
                title: 'English',
                subtitle: 'App & questions in English',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged('en');
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _OptionChip(
                selected: _isHindi,
                title: 'हिन्दी',
                subtitle: 'ऐप और सवाल हिन्दी में',
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged('hi');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _isHindi
              ? context.l10n.languagePickerHintHi
              : context.l10n.languagePickerHintEn,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PreviewCard(isHindi: _isHindi, sample: sample),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = selected
        ? scheme.primary
        : scheme.outlineVariant.withValues(alpha: 0.7);
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.1)
        : scheme.surface;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      color: scheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    title,
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.isHindi, required this.sample});

  final bool isHindi;
  final ContentLanguagePreviewSample sample;

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final question = isHindi ? sample.hi : sample.en;
    final options = isHindi ? sample.optionsHi : sample.optionsEn;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Column(
          key: ValueKey<bool>(isHindi),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Badge(
                  label: isHindi ? 'App · हि' : 'App · EN',
                  bg: AppColors.infoBg,
                  fg: AppColors.info,
                ),
                const SizedBox(width: 6),
                _Badge(
                  label: isHindi ? 'Questions · हि' : 'Questions · EN',
                  bg: isHindi ? AppColors.warningBg : AppColors.correctBg,
                  fg: isHindi ? AppColors.warning : AppColors.correct,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.languagePickerPracticeTest,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              question,
              style: AppTextStyles.bodySm().copyWith(
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              _PreviewOption(
                label: _labels[i],
                text: options[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewOption extends StatelessWidget {
  const _PreviewOption({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Text(
            '$label.',
            style: AppTextStyles.labelSm().copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm().copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption().copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Post-onboarding / Settings sheet to pick content language.
Future<void> showContentLanguageChoiceSheet({
  required BuildContext context,
  required WidgetRef ref,
  bool barrierDismissible = true,
  String? confirmLabel,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final bottom = MediaQuery.paddingOf(context).bottom;
  final prefs = await ref.read(prefsServiceProvider.future);
  final initial = normalizeAppLanguage(prefs.language);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: barrierDismissible,
    enableDrag: barrierDismissible,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _ContentLanguageChoiceSheet(
        initialLanguage: initial,
        scheme: scheme,
        bottomInset: bottom,
        confirmLabel: confirmLabel,
        onPersist: (lang) => persistAppLanguage(ref, lang),
      );
    },
  );
}

class _ContentLanguageChoiceSheet extends StatefulWidget {
  const _ContentLanguageChoiceSheet({
    required this.initialLanguage,
    required this.scheme,
    required this.bottomInset,
    required this.confirmLabel,
    required this.onPersist,
  });

  final String initialLanguage;
  final ColorScheme scheme;
  final double bottomInset;
  final String? confirmLabel;
  final Future<void> Function(String lang) onPersist;

  @override
  State<_ContentLanguageChoiceSheet> createState() =>
      _ContentLanguageChoiceSheetState();
}

class _ContentLanguageChoiceSheetState
    extends State<_ContentLanguageChoiceSheet> {
  late String _language = widget.initialLanguage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, widget.bottomInset + 12),
      child: Material(
        color: widget.scheme.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.languagePickerTitle,
                    style: AppTextStyles.h3().copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.languagePickerSubtitle,
                    style: AppTextStyles.caption().copyWith(
                      color: widget.scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ContentLanguagePicker(
                    language: _language,
                    onChanged: (lang) async {
                      setState(() => _language = lang);
                      await widget.onPersist(lang);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.confirmLabel ?? context.l10n.commonDone),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
