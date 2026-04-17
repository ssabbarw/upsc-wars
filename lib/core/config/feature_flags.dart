abstract final class FeatureFlags {
  /// Enables the migrated Community tab rollout.
  static const communityTab = bool.fromEnvironment(
    'ENABLE_COMMUNITY_TAB',
    defaultValue: true,
  );
}
