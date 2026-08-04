import 'package:flutter/material.dart';

/// Timed beats for the debug-only Play Store promo demo.
enum PlayStoreDemoBeat {
  ready,
  thesis,
  confidence,
  explanationBody,
  explanationElimination,
  explanationTrap,
  dangerZoneMap,
  dangerZoneStrong,
  gamesHub,
  gameTimelineSorter,
  gameFactOrBluff,
  endCard,
}

/// Where the catchy overlay sits — chosen so it doesn't cover the hero UI.
enum DemoCaptionAnchor {
  /// No floating caption (ready / end card already carry the message).
  none,

  /// Top of screen, full width.
  top,

  /// Upper band, left-aligned (leaves right/mid free).
  topLeft,

  /// Upper band, right-aligned.
  topRight,

  /// Vertical center — for sparse / card-centered scenes.
  center,

  /// Lower band above home indicator.
  bottom,

  /// Lower-left (e.g. above a right-side CTA).
  bottomLeft,
}

class PlayStoreDemoStep {
  const PlayStoreDemoStep({
    required this.beat,
    required this.duration,
    required this.caption,
    this.subCaption,
    this.anchor = DemoCaptionAnchor.top,
    this.accent = const Color(0xFFFF3B5C),
  });

  final PlayStoreDemoBeat beat;
  final Duration duration;

  /// Big hook line.
  final String caption;

  /// Optional second line under the hook.
  final String? subCaption;

  final DemoCaptionAnchor anchor;

  /// Accent bar / highlight color for this beat.
  final Color accent;
}

/// Learning-first cut: Danger Zone → explanations → games → end.
const playStoreDemoScript = <PlayStoreDemoStep>[
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.ready,
    duration: Duration(milliseconds: 1600),
    caption: 'Recording starts…',
    subCaption: 'Auto-playing — no taps needed',
    anchor: DemoCaptionAnchor.none,
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.thesis,
    duration: Duration(milliseconds: 3500),
    caption: 'Confident…\nand still wrong?',
    subCaption: 'That’s the real Prelims killer',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFFE24B4A),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.confidence,
    duration: Duration(milliseconds: 3200),
    caption: 'Rate confidence\ninline',
    subCaption: 'Sure · Educated guess · Pure guess',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFF1D9E75),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationElimination,
    duration: Duration(milliseconds: 3600),
    caption: 'First GG…\nbut of Bengal',
    subCaption: 'Watch out zooms in on the trap',
    anchor: DemoCaptionAnchor.top,
    accent: Color(0xFFBA7517),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationTrap,
    duration: Duration(milliseconds: 3200),
    caption: 'Entity-Swap &\nGeographic Swap',
    subCaption: 'Wrong person. Wrong place. Same trap family.',
    anchor: DemoCaptionAnchor.top,
    accent: Color(0xFFE24B4A),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.dangerZoneMap,
    duration: Duration(milliseconds: 3200),
    caption: 'Danger Zone',
    subCaption: 'Confidently wrong — revise these',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFFE24B4A),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.dangerZoneStrong,
    duration: Duration(milliseconds: 3000),
    caption: 'Strong topics',
    subCaption: 'Educated guesses land — take more risk',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFF1D9E75),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gamesHub,
    duration: Duration(milliseconds: 3500),
    caption: 'Six short games.\nReal Prelims speed.',
    subCaption: 'Revise without the grind',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFF1A7A5E),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gameTimelineSorter,
    duration: Duration(milliseconds: 2200),
    caption: 'Timeline Sorter',
    subCaption: 'Drag history into order',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFFBA7517),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gameFactOrBluff,
    duration: Duration(milliseconds: 3000),
    caption: '10 seconds.\nTrust your gut.',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFF1A7A5E),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.endCard,
    duration: Duration(milliseconds: 5000),
    caption: 'UPSC Wars',
    anchor: DemoCaptionAnchor.none,
  ),
];
