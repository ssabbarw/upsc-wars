/// Temporary debugging toggles for Prelims surfaces (notification).
/// Set [surfacesEveryMinute] back to `false` before shipping.
class PrelimsDebugFlags {
  PrelimsDebugFlags._();

  /// When `true`: Workmanager runs ~every minute (Android may clamp to ≥15m),
  /// and the app refreshes surfaces every minute while running. Notification
  /// body can include `HH:mm` so you can see ticks.
  static const bool surfacesEveryMinute = false;
}
