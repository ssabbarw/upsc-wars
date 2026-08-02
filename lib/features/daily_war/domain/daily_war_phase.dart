/// Lifecycle phase of tonight's Daily War for UI (derived from server-corrected IST).
enum DailyWarPhase {
  /// Sunday — no paper; show rest / tomorrow tease.
  restDay,

  /// Before announce hour (rare overnight edge) — show tomorrow tease lightly.
  preAnnounce,

  /// 6 AM – lobby open: topic announcement + prepare CTA.
  morning,

  /// After afternoon threshold until lobby — countdown emphasis.
  countdown,

  /// Lobby open until 9:00 PM.
  lobby,

  /// 9:00 – late-join cutoff: can still enter.
  liveJoinable,

  /// After late-join until live window ends: in progress, no new joins.
  liveLocked,

  /// After live window, ranks may still be calculating.
  resultsPending,

  /// Ranks published (or enough time passed that UI shows results).
  resultsReady,
}

/// Personal relationship to a past (or today's) War in History.
enum DailyWarAttemptKind {
  /// Official live participation with AIR.
  live,

  /// Catch-up practice after the live window — no AIR.
  unranked,

  /// No attempt yet.
  none,
}
