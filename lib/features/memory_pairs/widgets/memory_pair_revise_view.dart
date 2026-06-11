import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/memory_pair_models.dart';
import 'memory_pair_flash_deck.dart';
import 'memory_pair_shared_widgets.dart';

class MemoryPairReviseView extends HookWidget {
  const MemoryPairReviseView({
    super.key,
    required this.set,
    required this.difficulty,
    required this.lang,
    required this.onPlay,
  });

  final MemoryPairSetDefinition set;
  final MemoryPairDifficulty difficulty;
  final String lang;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pairs = set.pairs.take(difficulty.pairCount).toList();
    final mode = useState(_ReviseMode.cards);
    final revealedRows = useState(<int>{});

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.nameForLang(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      '${pairs.length} pairs',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _ViewModeToggle(
                mode: mode.value,
                isDark: isDark,
                onChanged: (m) => mode.value = m,
              ),
            ],
          ),
        ),
        Expanded(
          child: mode.value == _ReviseMode.cards
              ? MemoryPairFlashDeck(
                  pairs: pairs,
                  lang: lang,
                  accentColor: set.accentColor,
                  onPlay: onPlay,
                )
              : _FlashList(
                  pairs: pairs,
                  lang: lang,
                  revealed: revealedRows.value,
                  onToggle: (i) {
                    final next = Set<int>.from(revealedRows.value);
                    if (next.contains(i)) {
                      next.remove(i);
                    } else {
                      next.add(i);
                    }
                    revealedRows.value = next;
                  },
                ),
        ),
        if (mode.value == _ReviseMode.list)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play now'),
              ),
            ),
          ),
      ],
    );
  }
}

enum _ReviseMode { cards, list }

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.mode,
    required this.isDark,
    required this.onChanged,
  });

  final _ReviseMode mode;
  final bool isDark;
  final ValueChanged<_ReviseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            icon: Icons.style_outlined,
            label: 'Cards',
            selected: mode == _ReviseMode.cards,
            onTap: () => onChanged(_ReviseMode.cards),
            scheme: scheme,
          ),
          _ToggleChip(
            icon: Icons.view_list_rounded,
            label: 'List',
            selected: mode == _ReviseMode.list,
            onTap: () => onChanged(_ReviseMode.list),
            scheme: scheme,
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlashList extends StatelessWidget {
  const _FlashList({
    required this.pairs,
    required this.lang,
    required this.revealed,
    required this.onToggle,
  });

  final List<MemoryPair> pairs;
  final String lang;
  final Set<int> revealed;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      itemCount: pairs.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Text(
            'Tap a row to reveal its answer',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );
        }
        final idx = i - 1;
        final pair = pairs[idx];
        final show = revealed.contains(idx);
        return MemoryPairSurfaceCard(
          onTap: () => onToggle(idx),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pair.termForLang(lang),
                  style: AppTextStyles.labelSm().copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  show ? pair.answerForLang(lang) : '••••••',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSm().copyWith(
                    color: show
                        ? scheme.onSurfaceVariant
                        : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
