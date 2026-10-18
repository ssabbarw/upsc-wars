import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/reading_font_scale.dart';
import '../shared/game_intro_view.dart';
import '../shared/mini_game_models.dart';
import '../shared/revision_game_analytics.dart';
import '../shared/revision_games_theme.dart';
import '../shared/revision_games_widgets.dart';
import 'connect_the_dots_controller.dart';
import '../../../l10n/l10n.dart';

class ConnectTheDotsScreen extends HookConsumerWidget {
  const ConnectTheDotsScreen({
    super.key,
    this.subjectsCsv = '',
    this.difficultiesCsv = '',
    this.initialLang = '',
  });

  /// Comma-separated subject slugs to filter content by; empty = all.
  final String subjectsCsv;

  /// Comma-separated difficulty names to filter content by; empty = all.
  final String difficultiesCsv;

  /// Optional `lang` query param (`en` / `hi`); falls back to saved app language.
  final String initialLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langState = useState(
      normalizeMiniGameLang(
        initialLang.isNotEmpty ? initialLang : watchAppLanguage(ref),
      ),
    );
    final lang = langState.value;
    void onLangChanged(String v) {
      langState.value = v;
      persistAppLanguage(ref, v);
    }

    final provider = connectTheDotsControllerProvider((
      subjects: subjectsCsv,
      difficulties: difficultiesCsv,
    ));
    final async = ref.watch(provider);
    final howToReady = useGameHowToSheet(
      context: context,
      ref: ref,
      config: GameHowToConfig(
        prefKey: GameHowToPrefs.connectTheDots,
        icon: Icons.hub_rounded,
        accent: GameAccent.connectTheDots.accent,
        badgeBg: GameAccent.connectTheDots.badgeBg,
        title: 'Connect the Dots',
        steps: [
          context.l10n.gmCtdStep1,
          context.l10n.gmCtdStep2,
          context.l10n.gmCtdStep3,
        ],
      ),
    );

    final snapshot = async.asData?.value;
    final item = snapshot?.current;
    final revealed = snapshot?.revealed ?? false;
    final complete = snapshot?.sessionComplete ?? false;
    final session = snapshot?.session ?? const [];
    useGameScreenOpenedAnalytics(ref, RevisionGameNames.connectTheDots);
    useGameSessionAnalytics(
      ref: ref,
      gameName: RevisionGameNames.connectTheDots,
      readyToStart: howToReady && session.isNotEmpty,
      sessionComplete: complete,
      correctCount: snapshot?.correctCount ?? 0,
      totalRounds: session.length,
      sessionKey: session.isEmpty ? null : session.map((e) => e.id).join(','),
    );

    return RgGameScaffold(
      title: 'Connect the Dots',
      trailing: item == null || complete
          ? null
          : RgLangToggle(
              language: lang,
              onChanged: onLangChanged,
              minHeight: 28,
            ),
      footer: revealed && !complete
          ? RgPillButton(
              label: context.l10n.gmNext,
              verticalPadding: 11,
              onPressed: () => ref.read(provider.notifier).next(),
            )
          : null,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: RgColors.teal),
        ),
        error: (e, _) => Center(
          child: Text('$e', style: RgText.body(color: RgColors.muted)),
        ),
        data: (state) {
          if (complete) {
            return RgSessionCompleteView(
              correct: state.correctCount,
              total: state.session.length,
              onPlayAgain: () => ref.read(provider.notifier).playAgain(),
            );
          }
          if (item == null) {
            return Center(
              child: Text(
                state.error ?? context.l10n.gmNoContent,
                style: RgText.body(color: RgColors.muted),
              ),
            );
          }
          final picked = state.selectedIndex;
          final pickedWrong =
              revealed && picked != null && picked != item.answerIndex;

          final dots = item.dotsForLang(lang);
          final options = item.optionsForLang(lang);

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: [
              RgMonoLabel(
                context.l10n.gmSubjNOfTotal(
                  item.subject,
                  state.index + 1,
                  state.session.length,
                ),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < dots.length; i++) ...[
                if (i > 0) _Connector(revealed: revealed),
                _ClueCard(text: dots[i], revealed: revealed),
              ],
              const SizedBox(height: 12),
              RgMonoLabel(context.l10n.gmCtdHidden),
              const SizedBox(height: 8),
              if (!revealed)
                for (var i = 0; i < options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _OptionPill(
                      label: options[i],
                      onTap: () => ref.read(provider.notifier).select(i),
                    ),
                  )
              else ...[
                if (pickedWrong)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _OptionPill(
                      label: options[picked],
                      onTap: null,
                      fill: RgColors.wrongBg,
                      borderColor: RgColors.wrong,
                      foreground: RgColors.wrongText,
                      icon: Icons.cancel_rounded,
                    ),
                  ),
                _OptionPill(
                  label: options[item.answerIndex],
                  onTap: null,
                  fill: RgColors.correctBg,
                  borderColor: RgColors.teal,
                  foreground: RgColors.tealDeep,
                  borderWidth: 2,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(height: 10),
                RgExplanationChip(text: item.explanationForLang(lang)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ClueCard extends StatelessWidget {
  const _ClueCard({required this.text, required this.revealed});

  final String text;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: revealed ? RgColors.correctBg : RgColors.card,
        borderRadius: BorderRadius.circular(RgRadius.md),
        border: Border.all(
          color: revealed ? RgColors.correctBorder : RgColors.border,
        ),
      ),
      child: Text(
        text,
        style: context.readingFont(
          RgText.body(size: 12, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Short vertical tick that threads the clue cards together.
class _Connector extends StatelessWidget {
  const _Connector({required this.revealed});

  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 20),
        width: 1.5,
        height: 10,
        color: revealed ? RgColors.teal : RgColors.border12,
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.onTap,
    this.fill = RgColors.card,
    this.borderColor = RgColors.border12,
    this.foreground = RgColors.ink,
    this.borderWidth = 1.5,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final Color fill;
  final Color borderColor;
  final Color foreground;
  final double borderWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RgColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RgRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(RgRadius.pill),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: RgText.body(
                    size: 12.5,
                    weight: icon == null ? FontWeight.w600 : FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
