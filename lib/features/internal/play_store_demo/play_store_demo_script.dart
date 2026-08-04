/// Timed beats for the debug-only Play Store promo demo.
enum PlayStoreDemoBeat {
  ready,
  thesis,
  confidence,
  dangerZoneIntro,
  explanationBody,
  explanationStatements,
  explanationElimination,
  explanationTrap,
  dangerZoneMap,
  gamesHub,
  gameMemoryPairs,
  gameFactOrBluff,
  warLive,
  warAir,
  endCard,
}

class PlayStoreDemoStep {
  const PlayStoreDemoStep({
    required this.beat,
    required this.duration,
    required this.caption,
  });

  final PlayStoreDemoBeat beat;
  final Duration duration;

  /// Short on-screen overlay line (keep under ~6 words).
  final String caption;
}

/// Learning-first cut: Danger Zone → explanations → games → short War closer.
const playStoreDemoScript = <PlayStoreDemoStep>[
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.ready,
    duration: Duration(milliseconds: 2200),
    caption: 'Start recording',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.thesis,
    duration: Duration(milliseconds: 3500),
    caption: 'The UPSC reality',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.confidence,
    duration: Duration(milliseconds: 3200),
    caption: 'Rate your confidence',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.dangerZoneIntro,
    duration: Duration(milliseconds: 3800),
    caption: 'Meet Danger Zone',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationBody,
    duration: Duration(milliseconds: 3200),
    caption: 'Detailed explanations',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationStatements,
    duration: Duration(milliseconds: 2800),
    caption: 'Statement analysis',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationElimination,
    duration: Duration(milliseconds: 2800),
    caption: 'Elimination techniques',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationTrap,
    duration: Duration(milliseconds: 2800),
    caption: 'UPSC traps',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.dangerZoneMap,
    duration: Duration(milliseconds: 3000),
    caption: 'Revise your Danger Zone',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gamesHub,
    duration: Duration(milliseconds: 3500),
    caption: 'Revision games',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gameMemoryPairs,
    duration: Duration(milliseconds: 3000),
    caption: 'Memory Pairs',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gameFactOrBluff,
    duration: Duration(milliseconds: 3000),
    caption: 'Fact or Bluff',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.warLive,
    duration: Duration(milliseconds: 2500),
    caption: 'Nightly All-India War',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.warAir,
    duration: Duration(milliseconds: 3500),
    caption: 'Your All-India Rank',
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.endCard,
    duration: Duration(milliseconds: 5000),
    caption: 'UPSC Wars',
  ),
];
