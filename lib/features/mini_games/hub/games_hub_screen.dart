import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../connect_the_dots/connect_the_dots_controller.dart';
import '../duel/duel_controller.dart';
import '../fact_or_bluff/fact_or_bluff_controller.dart';
import '../odd_one_out/odd_one_out_controller.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import '../timeline_sorter/timeline_sorter_controller.dart';

class _GameEntry {
  const _GameEntry({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.badgeColor,
    required this.sessionSize,
    this.usesConfigPicker = true,
    this.highlighted = false,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;

  /// Accent color for the game's icon tile (matches Revision Games v2).
  final Color badgeColor;

  /// Questions/sets drawn per session — shown on the config sheet's CTA.
  final int sessionSize;

  /// When false, open [route] directly (e.g. Memory Pairs has its own catalog).
  final bool usesConfigPicker;

  /// Renders as the dark, featured card (the 1v1 Duel in the design).
  final bool highlighted;
}

const _games = [
  _GameEntry(
    title: 'Memory Pairs',
    description: 'Match terms to answers — train recall.',
    route: '/memory-pairs',
    icon: Icons.grid_view_rounded,
    badgeColor: RgColors.info,
    sessionSize: 0,
    usesConfigPicker: false,
  ),
  _GameEntry(
    title: 'Timeline Sorter',
    description: 'Put events in the right order.',
    route: '/games/timeline-sorter',
    icon: Icons.timeline_rounded,
    badgeColor: RgColors.warning,
    sessionSize: timelineSessionSize,
  ),
  _GameEntry(
    title: 'Odd One Out',
    description: "Four items. One doesn't belong.",
    route: '/games/odd-one-out',
    icon: Icons.rule_rounded,
    badgeColor: RgColors.wrong,
    sessionSize: oddOneOutSessionSize,
  ),
  _GameEntry(
    title: 'Fact or Bluff',
    description: 'Ten seconds. Trust your gut.',
    route: '/games/fact-or-bluff',
    icon: Icons.bolt_rounded,
    badgeColor: RgColors.teal,
    sessionSize: factOrBluffSessionSize,
  ),
  _GameEntry(
    title: 'Connect the Dots',
    description: 'Find the hidden link.',
    route: '/games/connect-the-dots',
    icon: Icons.hub_rounded,
    badgeColor: RgColors.tealDeep,
    sessionSize: connectTheDotsSessionSize,
  ),
  _GameEntry(
    title: '1v1 Duel',
    description: 'One phone, two players, fastest wins.',
    route: '/games/duel',
    icon: Icons.military_tech_rounded,
    badgeColor: RgColors.teal,
    sessionSize: duelMatchLength,
    highlighted: true,
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
    backgroundColor: RgColors.pageBg,
    barrierColor: RgColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(RgRadius.xl)),
    ),
    builder: (context) => _SubjectPickerSheet(
      gameTitle: game.title,
      sessionSize: game.sessionSize,
    ),
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
  const _SubjectPickerSheet({
    required this.gameTitle,
    required this.sessionSize,
  });

  final String gameTitle;
  final int sessionSize;

  @override
  State<_SubjectPickerSheet> createState() => _SubjectPickerSheetState();
}

class _SubjectPickerSheetState extends State<_SubjectPickerSheet> {
  final Set<String> _selected = {};
  String _difficulty = '';

  Widget _subjectChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RgRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? RgColors.teal : RgColors.card,
            borderRadius: BorderRadius.circular(RgRadius.pill),
            border: Border.all(
              color: selected ? RgColors.teal : RgColors.border14,
            ),
          ),
          child: Text(
            selected ? '$label ✓' : label,
            style: RgText.body(
              size: 11,
              weight: FontWeight.w600,
              color: selected ? RgColors.onDark : RgColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _difficultySegment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: RgColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RgRadius.sm),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? RgColors.ink : RgColors.card,
              borderRadius: BorderRadius.circular(RgRadius.sm),
              border: Border.all(
                color: selected ? RgColors.ink : RgColors.border14,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: RgText.mono(
                size: 11,
                color: selected ? RgColors.onDark : RgColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: 18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: RgColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          RgMonoLabel('${widget.gameTitle} · Config'),
          const SizedBox(height: 4),
          Text('Set up your session', style: RgText.display(size: 16)),
          const SizedBox(height: 12),
          const RgMonoLabel('Subjects'),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _subjectChip(
                    label: 'All',
                    selected: _selected.isEmpty,
                    onTap: () => setState(_selected.clear),
                  ),
                  for (final subject in SubjectConstants.ordered)
                    _subjectChip(
                      label: subject.displayName,
                      selected: _selected.contains(subject.slug),
                      onTap: () => setState(() {
                        if (!_selected.remove(subject.slug)) {
                          _selected.add(subject.slug);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const RgMonoLabel('Difficulty'),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (value, label) in const [
                ('', 'MIXED'),
                ('easy', 'EASY'),
                ('medium', 'MED'),
                ('hard', 'HARD'),
              ]) ...[
                if (value != '') const SizedBox(width: 6),
                _difficultySegment(
                  label: label,
                  selected: _difficulty == value,
                  onTap: () => setState(() => _difficulty = value),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          RgPillButton(
            label: 'Start · ${widget.sessionSize} questions',
            verticalPadding: 13,
            onPressed: () => Navigator.of(context).pop(
              _GameLaunchConfig(subjects: _selected, difficulty: _difficulty),
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
    return RgGameScaffold(
      title: 'Revision Games',
      centerTitle: true,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: _games.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _GameCard(game: _games[index]),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final _GameEntry game;

  @override
  Widget build(BuildContext context) {
    final dark = game.highlighted;
    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: () => _openGame(context, game),
        borderRadius: BorderRadius.circular(RgRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? RgColors.ink : RgColors.card,
            borderRadius: BorderRadius.circular(RgRadius.lg),
            border: dark ? null : Border.all(color: RgColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: game.badgeColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(game.icon, size: 20, color: RgColors.onDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: RgText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: dark ? RgColors.onDark : RgColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.description,
                      style: RgText.body(
                        size: 11,
                        color: dark
                            ? RgColors.onDark.withValues(alpha: 0.6)
                            : RgColors.mutedSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
