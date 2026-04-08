String formatMmSsFromSecs(int secs) {
  final m = (secs ~/ 60).toString();
  final s = (secs % 60).toString().padLeft(2, '0');
  return '${m}m ${s}s';
}

String formatHhMmSsFromSecs(int secs) {
  final mm = (secs ~/ 60).toString().padLeft(2, '0');
  final ss = (secs % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}
