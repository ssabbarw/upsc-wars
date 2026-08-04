/// Sticky attribution for why the user entered / returned to the app.
///
/// Set from push taps and deep links before [AppOpenedEvent] /
/// [SessionStartedEvent] consume the value. Defaults to [organic].
abstract final class SessionEntrySource {
  SessionEntrySource._();

  static const organic = 'organic';
  static const push = 'push';
  static const deepLink = 'deep_link';

  static String? _pendingSource;
  static String? _pendingDetail;

  /// Records a non-organic entry reason (overwrites any prior pending value).
  static void capture(String source, {String? detail}) {
    if (source.isEmpty) return;
    _pendingSource = source;
    _pendingDetail = (detail != null && detail.isNotEmpty) ? detail : null;
  }

  /// Returns the pending source (or [organic]) and clears it for the next open.
  static ({String source, String? detail}) consume() {
    final source = _pendingSource ?? organic;
    final detail = _pendingDetail;
    _pendingSource = null;
    _pendingDetail = null;
    return (source: source, detail: detail);
  }

  /// Test / debug helper.
  static void reset() {
    _pendingSource = null;
    _pendingDetail = null;
  }
}
