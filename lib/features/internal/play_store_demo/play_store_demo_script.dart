import 'package:flutter/material.dart';

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

/// Learning-first cut: Danger Zone → explanations → games → short War closer.
const playStoreDemoScript = <PlayStoreDemoStep>[
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.ready,
    duration: Duration(milliseconds: 2200),
    caption: 'Hit record',
    subCaption: 'Demo starts next',
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
    caption: 'How sure\nare you?',
    subCaption: 'Answer before the reveal',
    anchor: DemoCaptionAnchor.topRight,
    accent: Color(0xFF1D9E75),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.dangerZoneIntro,
    duration: Duration(milliseconds: 4200),
    caption: 'Tracks syllabus\nsections you miss',
    subCaption: 'Danger Zone = topics you get wrong',
    anchor: DemoCaptionAnchor.top,
    accent: Color(0xFFE24B4A),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationBody,
    duration: Duration(milliseconds: 3200),
    caption: 'Not just\nthe answer',
    subCaption: 'Full explanation, every time',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFF1A7A5E),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationStatements,
    duration: Duration(milliseconds: 2800),
    caption: 'Break every\nstatement',
    subCaption: 'True / false with reasons',
    anchor: DemoCaptionAnchor.topRight,
    accent: Color(0xFF185FA5),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationElimination,
    duration: Duration(milliseconds: 2800),
    caption: 'Eliminate\nlike a pro',
    subCaption: 'Step-by-step option killing',
    anchor: DemoCaptionAnchor.bottomLeft,
    accent: Color(0xFFBA7517),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.explanationTrap,
    duration: Duration(milliseconds: 2800),
    caption: 'Spot the\nUPSC trap',
    subCaption: 'Before it costs you marks',
    anchor: DemoCaptionAnchor.topLeft,
    accent: Color(0xFFE24B4A),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.dangerZoneMap,
    duration: Duration(milliseconds: 3400),
    caption: 'Syllabus sections\nthat hurt you',
    subCaption:
        'UPSC Wars tracks where you go wrong — revise those topics first.',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFFE24B4A),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gamesHub,
    duration: Duration(milliseconds: 3500),
    caption: 'Revise\nwithout the grind',
    subCaption: '6 short games. Real Prelims feel.',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFF1A7A5E),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gameMemoryPairs,
    duration: Duration(milliseconds: 3000),
    caption: 'Flip.\nMatch.\nRemember.',
    anchor: DemoCaptionAnchor.topRight,
    accent: Color(0xFF185FA5),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.gameFactOrBluff,
    duration: Duration(milliseconds: 3000),
    caption: '10 seconds.\nTrust your gut.',
    anchor: DemoCaptionAnchor.top,
    accent: Color(0xFF1A7A5E),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.warLive,
    duration: Duration(milliseconds: 2500),
    caption: 'Tonight.\nAll India.',
    subCaption: 'Same paper. Same clock.',
    anchor: DemoCaptionAnchor.top,
    accent: Color(0xFFFF3B5C),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.warAir,
    duration: Duration(milliseconds: 3500),
    caption: 'See your\nAll-India Rank',
    subCaption: 'Know where you stand',
    anchor: DemoCaptionAnchor.bottom,
    accent: Color(0xFF1D9E75),
  ),
  PlayStoreDemoStep(
    beat: PlayStoreDemoBeat.endCard,
    duration: Duration(milliseconds: 5000),
    caption: 'UPSC Wars',
    anchor: DemoCaptionAnchor.none,
  ),
];
