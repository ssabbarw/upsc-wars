/// How accuracy should be presented (color rules from project rules / Phase 2 spec).
enum AccuracyDisplayTier {
  /// No attempts — show em dash.
  dash,

  /// 1–9 attempts — muted (onSurfaceVariant).
  mutedLowAttempts,

  /// 10+ attempts and ≥ 70%.
  high,

  /// 10+ attempts and 55–69%.
  medium,

  /// 10+ attempts and below 55%.
  low,
}
