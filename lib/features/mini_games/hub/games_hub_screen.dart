import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class _GameEntry {
  const _GameEntry({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    this.usesConfigPicker = true,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;

  /// When false, open [route] directly (e.g. Memory Pairs has its own catalog).
  final bool usesConfigPicker;
}

const _games = [
  _GameEntry(
    title: 'Memory Pairs',
    description: 'Match terms to answers — train recall.',
    route: '/memory-pairs',
    icon: Icons.grid_view_rounded,
    usesConfigPicker: false,
  ),
  _GameEntry(
    title: 'Timeline Sorter',
    description: 'Put events in the right order.',
    route: '/games/timeline-sorter',
    icon: Icons.timeline_rounded,
  ),
  _GameEntry(
    title: 'Odd One Out',
    description: "Four items. One doesn't belong.",
    route: '/games/odd-one-out',
    icon: Icons.filter_alt_outlined,
  ),
  _GameEntry(
    title: 'Fact or Bluff',
    description: 'Five seconds. Trust your gut.',
    route: '/games/fact-or-bluff',
    icon: Icons.bolt_outlined,
  ),
  _GameEntry(
    title: 'Connect the Dots',
    description: 'Find the hidden link.',
    route: '/games/connect-the-dots',
    icon: Icons.hub_outlined,
  ),
  _GameEntry(
    title: '1v1 Duel',
    description: 'One phone, two players, fastest correct answer wins.',
    route: '/games/duel',
    icon: Icons.sports_esports_outlined,
  ),
];

class _GameLaunchConfig {
  const _GameLaunchConfig({required this.subjects, required this.difficulty});

  /// Selected subject slugs; empty = all subjects.
  final Set<String> subjects;

  /// Selected difficulty name ('easy'|'medium'|'hard'); empty = mixed.
  final String difficulty;
}

Future<void> _openGame(BuildContext context, _GameEntry game) async {
  if (!game.usesConfigPicker) {
    context.push(game.route);
    return;
  }
  final config = await showModalBottomSheet<_GameLaunchConfig>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _SubjectPickerSheet(gameTitle: game.title),
  );
  if (config == null || !context.mounted) return;
  final params = <String>[
    if (config.subjects.isNotEmpty)
      'subjects=${Uri.encodeComponent(config.subjects.join(','))}',
    if (config.difficulty.isNotEmpty) 'difficulty=${config.difficulty}',
  ];
  context.push(
    params.isEmpty ? game.route : '${game.route}?${params.join('&')}',
  );
}

class _SubjectPickerSheet extends StatefulWidget {
  const _SubjectPickerSheet({required this.gameTitle});

  final String gameTitle;

  @override
  State<_SubjectPickerSheet> createState() => _SubjectPickerSheetState();
}

class _SubjectPickerSheetState extends State<_SubjectPickerSheet> {
  final Set<String> _selected = {};
  String _difficulty = '';

  /// Fixed-size chip: no checkmark and constant border width, so selecting
  /// never changes the chip's size (and the sheet never resizes).
  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color border,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryDark,
      side: BorderSide(
        color: selected ? AppColors.primaryDark : border,
        width: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final allSelected = _selected.isEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.gameTitle,
            style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            'Pick subjects to play, or mix them all.',
            style: AppTextStyles.caption()
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _chip(
                label: 'All subjects',
                selected: allSelected,
                onTap: () => setState(_selected.clear),
                border: border,
              ),
              for (final subject in SubjectConstants.ordered)
                _chip(
                  label: subject.displayName,
                  selected: _selected.contains(subject.slug),
                  onTap: () => setState(() {
                    if (!_selected.remove(subject.slug)) {
                      _selected.add(subject.slug);
                    }
                  }),
                  border: border,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'DIFFICULTY',
            style: AppTextStyles.caption()
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (value, label) in const [
                ('', 'Mixed'),
                ('easy', 'Easy'),
                ('medium', 'Medium'),
                ('hard', 'Hard'),
              ])
                _chip(
                  label: label,
                  selected: _difficulty == value,
                  onTap: () => setState(() => _difficulty = value),
                  border: border,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _GameLaunchConfig(
                  subjects: _selected,
                  difficulty: _difficulty,
                ),
              ),
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }
}

class GamesHubScreen extends HookConsumerWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Games', style: AppTextStyles.h2()),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: _games.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.cardListGap),
                itemBuilder: (context, index) {
                  final game = _games[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openGame(context, game),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Ink(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryDeep.withValues(alpha: 0.18)
                              : AppColors.primaryLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                game.icon,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.title,
                                    style: AppTextStyles.label().copyWith(
                                      color: scheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    game.description,
                                    style: AppTextStyles.caption().copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
