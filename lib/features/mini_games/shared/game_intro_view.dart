import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import 'revision_games_theme.dart';
import 'revision_games_widgets.dart';
import '../../../l10n/l10n.dart';

/// Pref keys — when true, the how-to bottom sheet is skipped for that game.
abstract final class GameHowToPrefs {
  static const timelineSorter = 'rg_howto_skip_timeline_sorter';
  static const oddOneOut = 'rg_howto_skip_odd_one_out';
  static const factOrBluff = 'rg_howto_skip_fact_or_bluff';
  static const connectTheDots = 'rg_howto_skip_connect_the_dots';
  static const duel = 'rg_howto_skip_duel';
}

class GameHowToConfig {
  const GameHowToConfig({
    required this.prefKey,
    required this.icon,
    required this.accent,
    required this.title,
    required this.steps,
    this.badgeBg,
    this.stepAccent,
    this.stepIcons,
    this.startLabel,
  });

  final String prefKey;
  final IconData icon;
  final Color accent;
  final String title;
  final List<String> steps;
  final Color? badgeBg;
  final Color? stepAccent;
  final List<IconData>? stepIcons;
  final String? startLabel;
}

/// Shows the how-to as a modal bottom sheet over the game, unless the user
/// previously chose context.l10n.gmDontShow. Returns when the sheet is dismissed.
Future<void> showGameHowToIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required GameHowToConfig config,
}) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (prefs.getBool(config.prefKey)) return;
  if (!context.mounted) return;

  final dontShowAgain = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: RgColors.pageBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _GameHowToSheet(config: config),
  );

  if (dontShowAgain == true) {
    await prefs.setBool(config.prefKey, true);
  }
}

/// Hook: game UI is ready after the how-to sheet is shown (or skipped).
///
/// Call once near the top of a [HookConsumerWidget] build. While `false`,
/// still render the game underneath — the sheet sits on top.
bool useGameHowToSheet({
  required BuildContext context,
  required WidgetRef ref,
  required GameHowToConfig config,
}) {
  final ready = useState(false);

  useEffect(() {
    var cancelled = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (cancelled || !context.mounted) return;
      await showGameHowToIfNeeded(context: context, ref: ref, config: config);
      if (!cancelled) ready.value = true;
    });
    return () => cancelled = true;
  }, [config.prefKey]);

  return ready.value;
}

class _GameHowToSheet extends StatefulWidget {
  const _GameHowToSheet({required this.config});

  final GameHowToConfig config;

  @override
  State<_GameHowToSheet> createState() => _GameHowToSheetState();
}

class _GameHowToSheetState extends State<_GameHowToSheet> {
  bool _dontShowAgain = false;

  static const _numerals = [
    Icons.looks_one_rounded,
    Icons.looks_two_rounded,
    Icons.looks_3_rounded,
    Icons.looks_4_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final markerColor = config.stepAccent ?? config.accent;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RgColors.ink.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.gmHowToPlay,
                style: RgText.monoLbl(color: RgColors.mutedSoft),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          config.badgeBg ??
                          config.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(RgRadius.lg),
                    ),
                    child: Icon(config.icon, size: 22, color: config.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.title,
                      style: RgText.display(size: 18, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < config.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        config.stepIcons != null && i < config.stepIcons!.length
                            ? config.stepIcons![i]
                            : _numerals[i.clamp(0, _numerals.length - 1)],
                        size: 18,
                        color: markerColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          config.steps[i],
                          style: RgText.body(size: 12.5, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _dontShowAgain,
                          activeColor: RgColors.teal,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) =>
                              setState(() => _dontShowAgain = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.gmDontShow,
                          style: RgText.body(size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              RgPillButton(
                label: config.startLabel ?? context.l10n.gmStart,
                onPressed: () => Navigator.of(context).pop(_dontShowAgain),
                verticalPadding: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-game visual identity for the Revision Games v2 intros and hub tiles.
class GameAccent {
  const GameAccent({
    required this.accent,
    required this.badgeBg,
    this.stepAccent,
  });

  final Color accent;
  final Color badgeBg;
  final Color? stepAccent;

  static const timelineSorter = GameAccent(
    accent: RgColors.warning,
    badgeBg: RgColors.warningBg,
  );

  static const oddOneOut = GameAccent(
    accent: RgColors.wrong,
    badgeBg: RgColors.wrongBg,
  );

  static const factOrBluff = GameAccent(
    accent: RgColors.teal,
    badgeBg: RgColors.correctBg,
  );

  static const connectTheDots = GameAccent(
    accent: RgColors.tealDeep,
    badgeBg: RgColors.correctBg,
  );

  static const duel = GameAccent(
    accent: RgColors.ink,
    badgeBg: RgColors.neutralFill,
    stepAccent: RgColors.teal,
  );
}
