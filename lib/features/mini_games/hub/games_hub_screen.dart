import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../shared/widgets/pop_to_shell_home_scope.dart';
import '../connect_the_dots/connect_the_dots_controller.dart';
import '../duel/duel_controller.dart';
import '../fact_or_bluff/fact_or_bluff_controller.dart';
import '../odd_one_out/odd_one_out_controller.dart';
import '../push/push_revision_game_fcm.dart';
import '../shared/mini_game_models.dart';
import '../shared/revision_game_analytics.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import '../timeline_sorter/timeline_sorter_controller.dart';
import '../../../l10n/l10n.dart';

class _GameEntry {
  const _GameEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.badgeColor,
    required this.sessionSize,
    this.usesConfigPicker = true,
    this.highlighted = false,
  });

  /// Stable id matching [RevisionGameNames] / FCM `game` payload.
  final String id;
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
    id: RevisionGameNames.memoryPairs,
    title: 'Memory Pairs',
    description: 'Match terms to answers — train recall.',
    route: '/memory-pairs',
    icon: Icons.grid_view_rounded,
    badgeColor: RgColors.info,
    sessionSize: 0,
    usesConfigPicker: false,
  ),
  _GameEntry(
    id: RevisionGameNames.timelineSorter,
    title: 'Timeline Sorter',
    description: 'Put events in the right order.',
    route: '/games/timeline-sorter',
    icon: Icons.timeline_rounded,
    badgeColor: RgColors.warning,
    sessionSize: timelineSessionSize,
  ),
  _GameEntry(
    id: RevisionGameNames.oddOneOut,
    title: 'Odd One Out',
    description: 'Pick the odd one out.',
    route: '/games/odd-one-out',
    icon: Icons.rule_rounded,
    badgeColor: RgColors.wrong,
    sessionSize: oddOneOutSessionSize,
  ),
  _GameEntry(
    id: RevisionGameNames.factOrBluff,
    title: 'Fact or Bluff',
    description: 'Ten seconds. Trust your gut.',
    route: '/games/fact-or-bluff',
    icon: Icons.bolt_rounded,
    badgeColor: RgColors.teal,
    sessionSize: factOrBluffSessionSize,
  ),
  _GameEntry(
    id: RevisionGameNames.connectTheDots,
    title: 'Connect the Dots',
    description: 'Find the hidden link.',
    route: '/games/connect-the-dots',
    icon: Icons.hub_rounded,
    badgeColor: RgColors.tealDeep,
    sessionSize: connectTheDotsSessionSize,
  ),
  _GameEntry(
    id: RevisionGameNames.duel,
    title: '1v1 Duel',
    description: 'One phone, two players, fastest wins.',
    route: '/games/duel',
    icon: Icons.military_tech_rounded,
    badgeColor: RgColors.teal,
    sessionSize: duelMatchLength,
    highlighted: true,
  ),
];

String _gameDescription(BuildContext context, _GameEntry game) {
  final l10n = context.l10n;
  return switch (game.id) {
    RevisionGameNames.memoryPairs => l10n.gmDescMemory,
    RevisionGameNames.timelineSorter => l10n.gmDescTimeline,
    RevisionGameNames.oddOneOut => l10n.gmOddStep2,
    RevisionGameNames.factOrBluff => l10n.gmDescFob,
    RevisionGameNames.connectTheDots => l10n.gmDescCtd,
    RevisionGameNames.duel => l10n.gmDescDuel,
    _ => game.description,
  };
}

_GameEntry? _gameEntryById(String? rawId) {
  final id = PushRevisionGameFcm.normalizeGameId(rawId ?? '');
  if (id == null) return null;
  for (final game in _games) {
    if (game.id == id) return game;
  }
  return null;
}

class _GameLaunchConfig {
  const _GameLaunchConfig({
    required this.subjects,
    required this.difficulty,
    required this.lang,
  });

  /// Selected subject slugs; empty = all subjects.
  final Set<String> subjects;

  /// Selected difficulty name ('easy'|'medium'|'hard'); empty = mixed.
  final String difficulty;

  /// Content language: `en` or `hi`.
  final String lang;
}

Future<void> _openGame(
  BuildContext context,
  WidgetRef ref,
  _GameEntry game,
) async {
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
      initialLang: watchAppLanguage(ref),
    ),
  );
  if (config == null || !context.mounted) return;
  await persistAppLanguage(ref, config.lang);
  if (!context.mounted) return;
  final params = <String>[
    if (config.subjects.isNotEmpty)
      'subjects=${Uri.encodeComponent(config.subjects.join(','))}',
    if (config.difficulty.isNotEmpty) 'difficulty=${config.difficulty}',
    'lang=${config.lang}',
  ];
  context.push('${game.route}?${params.join('&')}');
}

class _SubjectPickerSheet extends StatefulWidget {
  const _SubjectPickerSheet({
    required this.gameTitle,
    required this.sessionSize,
    required this.initialLang,
  });

  final String gameTitle;
  final int sessionSize;
  final String initialLang;

  @override
  State<_SubjectPickerSheet> createState() => _SubjectPickerSheetState();
}

class _SubjectPickerSheetState extends State<_SubjectPickerSheet> {
  final Set<String> _selected = {};
  String _difficulty = 'medium';
  late String _lang = normalizeMiniGameLang(widget.initialLang);

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
          RgMonoLabel(context.l10n.gmConfig),
          const SizedBox(height: 4),
          Text(widget.gameTitle, style: RgText.display(size: 20)),
          const SizedBox(height: 4),
          Text(
            context.l10n.gmSetup,
            style: RgText.body(size: 13, color: RgColors.muted),
          ),
          const SizedBox(height: 12),
          RgMonoLabel(context.l10n.gmLanguage),
          const SizedBox(height: 6),
          RgLangToggle(
            language: _lang,
            onChanged: (v) => setState(() => _lang = v),
          ),
          const SizedBox(height: 12),
          RgMonoLabel(context.l10n.gmSubjects),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _subjectChip(
                    label: context.l10n.gmAll,
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
            label: context.l10n.gmStartN(widget.sessionSize),
            verticalPadding: 13,
            onPressed: () => Navigator.of(context).pop(
              _GameLaunchConfig(
                subjects: _selected,
                difficulty: _difficulty,
                lang: _lang,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GamesHubScreen extends HookConsumerWidget {
  const GamesHubScreen({
    super.key,
    this.asShellTab = false,
    this.openConfigGame,
    this.openConfigNonce,
  });

  /// When true, hide back and wrap with [PopToShellHomeScope] (bottom-nav tab).
  final bool asShellTab;

  /// When set (e.g. from FCM `/games?config=timeline_sorter`), auto-opens that
  /// game's config bottom sheet after the hub mounts.
  final String? openConfigGame;

  /// Changes on each push so the same [openConfigGame] can re-trigger.
  final String? openConfigNonce;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useGameScreenOpenedAnalytics(ref, RevisionGameNames.gamesHub);
    final lang = watchAppLanguage(ref);
    final openedKey = useRef<String?>(null);

    useEffect(() {
      final game = _gameEntryById(openConfigGame);
      if (game == null) return null;
      final key = '${game.id}|${openConfigNonce ?? ''}';
      if (openedKey.value == key) return null;
      openedKey.value = key;
      var cancelled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (cancelled || !context.mounted) return;
        await _openGame(context, ref, game);
      });
      return () => cancelled = true;
    }, [openConfigGame, openConfigNonce]);

    final hub = RgGameScaffold(
      title: 'Revision Games',
      centerTitle: true,
      showBack: !asShellTab,
      trailing: RgLangToggle(
        language: lang,
        onChanged: (v) => persistAppLanguage(ref, v),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: _games.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _GameCard(
          game: _games[index],
          onTap: () => _openGame(context, ref, _games[index]),
        ),
      ),
    );
    if (!asShellTab) return hub;
    return PopToShellHomeScope(child: hub);
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});

  final _GameEntry game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = game.highlighted;
    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: onTap,
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
                      _gameDescription(context, game),
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
