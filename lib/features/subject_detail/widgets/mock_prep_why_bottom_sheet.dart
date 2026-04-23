import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Explains "Revise before mock" vs "Safe areas" mock-prep cards.
void showMockPrepWhyBottomSheet(
  BuildContext context, {
  required bool isRevise,
  required double? globalMistakeRatePercent,
  required double? globalReliableRatePercent,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    isDismissible: true,
    builder: (ctx) {
      final screenH = MediaQuery.sizeOf(ctx).height;
      final sheetHeight = (screenH * 0.72).clamp(420.0, 620.0);
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: _MockPrepWhySheet(
          sheetHeight: sheetHeight,
          isRevise: isRevise,
          globalMistakeRatePercent: globalMistakeRatePercent,
          globalReliableRatePercent: globalReliableRatePercent,
        ),
      );
    },
  );
}

String _formatPct(double? p) {
  if (p == null) return '';
  if (p >= 10 || p == p.roundToDouble()) return p.round().toString();
  return p.toStringAsFixed(1);
}

class _MockPrepWhySheet extends StatelessWidget {
  const _MockPrepWhySheet({
    required this.sheetHeight,
    required this.isRevise,
    required this.globalMistakeRatePercent,
    required this.globalReliableRatePercent,
  });

  final double sheetHeight;
  final bool isRevise;
  final double? globalMistakeRatePercent;
  final double? globalReliableRatePercent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isRevise
        ? (isDark ? AppColors.warningTextDark : AppColors.warningText)
        : (isDark ? AppColors.correctTextDark : AppColors.correctText);
    final softBg = isRevise
        ? (isDark
              ? AppColors.warningBgDark.withValues(alpha: 0.4)
              : AppColors.warningBg.withValues(alpha: 0.85))
        : (isDark
              ? AppColors.correctBgDark.withValues(alpha: 0.32)
              : AppColors.correctBg.withValues(alpha: 0.65));
    final emoji = isRevise ? '⚠️' : '✨';
    final hEmoji = isRevise ? '🔎' : '📊';
    final doEmoji = isRevise ? '📚' : '🎯';

    return SizedBox(
      height: sheetHeight,
      child: Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl + 4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRevise) ...[
                      _TitleBlock(
                        title: 'Revise Before Your Next Mock',
                        body: '',
                        accent: accent,
                        softBg: softBg,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'These are topics where your Sure + Incorrect and '
                        'Educated Guess + Incorrect are higher than your usual average.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurface,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeader(
                        icon: hEmoji,
                        label: 'How we identify these topics',
                        accent: accent,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      _SectionHeader(
                        icon: doEmoji,
                        label: 'What to do',
                        accent: accent,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Practice these topics first before your next mock to reduce '
                        'costly mistakes and improve your score.',
                        style: _bodyStyle(scheme),
                      ),
                    ] else ...[
                      _TitleBlock(
                        title: 'Safe Areas for Higher Attempts',
                        body:
                            'You are more likely to score well in these topics '
                            'because your confidence and elimination are stronger here.',
                        accent: accent,
                        softBg: softBg,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'These are topics where your Sure + Correct and Educated '
                        'Guess + Correct are better than your usual average.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurface,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeader(
                        icon: hEmoji,
                        label: 'How we identify these topics',
                        accent: accent,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (globalReliableRatePercent != null)
                        Text(
                          'Across all subjects, about '
                          '${_formatPct(globalReliableRatePercent)}% of your very sure '
                          'or somewhat sure, scored answers are correct — we use that '
                          'as your usual baseline for “reliable” attempts.',
                          style: _bodyStyle(scheme),
                        )
                      else
                        Text(
                          'We need more confident, scored practice before we can show '
                          'this percentage. Keep using confidence levels on your tests.',
                          style: _bodyStyle(scheme),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'If a topic performs better than this, you can trust your '
                        'judgment more there in mocks and exams.',
                        style: _bodyStyle(scheme),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'That is why these topics are placed here.',
                        style: _bodyStyle(scheme, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionHeader(
                        icon: doEmoji,
                        label: 'What to do',
                        accent: accent,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Be more confident while attempting questions from these '
                        'topics in mocks and exams.',
                        style: _bodyStyle(scheme),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _bodyStyle(ColorScheme scheme, {FontWeight? weight}) {
    return AppTextStyles.bodySm().copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.5,
      fontWeight: weight,
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.body,
    required this.accent,
    required this.softBg,
  });

  final String title;
  final String body;
  final Color accent;
  final Color softBg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.label().copyWith(
              color: scheme.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final String icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.label().copyWith(color: scheme.onSurface),
          ),
        ),
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
