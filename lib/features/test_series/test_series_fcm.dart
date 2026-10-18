/// FCM data contract for the "test series is free for you" push.
abstract final class TestSeriesFcm {
  /// Must match `FCM_KIND` in `functions/test_series/promos.js`.
  static const kind = 'test_series_free';
}
