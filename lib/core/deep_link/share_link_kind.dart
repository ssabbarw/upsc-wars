/// Path segment under `/share/{kind}/…` (spec: battle | test | question).
enum ShareLinkKind {
  battle('battle'),
  test('test'),
  question('question');

  const ShareLinkKind(this.pathSegment);

  final String pathSegment;

  static ShareLinkKind? parse(String raw) {
    final s = raw.trim().toLowerCase();
    for (final k in ShareLinkKind.values) {
      if (k.pathSegment == s) return k;
    }
    return null;
  }
}
