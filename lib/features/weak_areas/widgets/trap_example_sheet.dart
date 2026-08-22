import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../domain/trap_example.dart';
import '../providers/trap_example_provider.dart';
import 'trap_pattern_visual.dart';

Future<void> showTrapExampleSheet({
  required BuildContext context,
  required String trapType,
  required String displayName,
  required String blurb,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DismissOnScrimTap(
      child: TrapExampleSheet(
        trapType: trapType,
        displayName: displayName,
        blurb: blurb,
      ),
    ),
  );
}

class TrapExampleSheet extends HookConsumerWidget {
  const TrapExampleSheet({
    super.key,
    required this.trapType,
    required this.displayName,
    required this.blurb,
    this.exampleOverride,
    this.languageOverride,
  });

  final String trapType;
  final String displayName;
  final String blurb;
  final TrapExample? exampleOverride;
  final String? languageOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final exampleAsync = exampleOverride != null
        ? AsyncValue<TrapExample?>.data(exampleOverride)
        : ref.watch(trapExampleProvider(trapType));
    final language = languageOverride ?? watchAppLanguage(ref);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        sheetBottomPadding(context, base: AppSpacing.sm),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.86,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'EXAMPLE',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.wrong,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      TrapPatternIconWell(trapType: trapType),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(displayName, style: AppTextStyles.h2()),
                      ),
                    ],
                  ),
                  if (blurb.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      blurb,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  exampleAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => Text(
                      'Could not load an example.',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    data: (example) {
                      if (example == null) {
                        return Text(
                          'No example written for this trap yet.',
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return _TrapExampleMcq(
                        example: example,
                        language: language,
                      );
                    },
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

class _TrapExampleMcq extends HookWidget {
  const _TrapExampleMcq({required this.example, required this.language});

  final TrapExample example;
  final String language;

  @override
  Widget build(BuildContext context) {
    final picked = useState<String?>(null);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = example.forLanguage(language);
    final correct = example.correctOption;
    final pick = picked.value;
    final revealed = pick != null;
    final gotIt = pick == correct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          content.stem,
          style: AppTextStyles.question().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final entry in content.options.entries) ...[
          _TrapExampleOption(
            optionKey: entry.key,
            text: entry.value,
            revealed: revealed,
            isCorrect: entry.key == correct,
            isPick: pick == entry.key,
            onTap: revealed ? null : () => picked.value = entry.key,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (revealed) ...[
          Text(
            gotIt ? 'You spotted it.' : "That's the trap.",
            style: AppTextStyles.labelSm().copyWith(
              color: gotIt
                  ? (isDark
                        ? AppColors.correctTextDark
                        : AppColors.correctText)
                  : (isDark ? AppColors.wrongTextDark : AppColors.wrongText),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content.why,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _TrapExampleOption extends StatelessWidget {
  const _TrapExampleOption({
    required this.optionKey,
    required this.text,
    required this.revealed,
    required this.isCorrect,
    required this.isPick,
    required this.onTap,
  });

  final String optionKey;
  final String text;
  final bool revealed;
  final bool isCorrect;
  final bool isPick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = scheme.surface;
    Color border = isDark ? AppColors.borderDark : AppColors.borderLight;
    Color fg = scheme.onSurface;
    var borderW = 0.5;

    if (revealed && isCorrect) {
      bg = isDark ? AppColors.correctBgDark : AppColors.correctBg;
      border = AppColors.correct;
      fg = isDark ? AppColors.correctTextDark : AppColors.correctText;
      borderW = 2;
    } else if (revealed && isPick && !isCorrect) {
      bg = isDark ? AppColors.wrongBgDark : AppColors.wrongBg;
      border = AppColors.wrong;
      fg = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
      borderW = 2;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border, width: borderW),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${optionKey.toUpperCase()}. ',
                style: AppTextStyles.label().copyWith(color: fg),
              ),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.option().copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
