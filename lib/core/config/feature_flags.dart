abstract final class FeatureFlags {
  /// Enables the Community shell route and tab. Remote Config boolean
  /// `community_tab_enabled` can hide the tab when this is `true`.
  static const communityTab = bool.fromEnvironment(
    'ENABLE_COMMUNITY_TAB',
    defaultValue: true,
  );

  /// Internal question editor (search, edit, publish corrections).
  static const questionEditor = bool.fromEnvironment(
    'ENABLE_QUESTION_EDITOR',
    defaultValue: false,
  );
}
