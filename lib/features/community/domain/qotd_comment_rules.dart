/// Validation for optional QOTD poster comments.
class QotdCommentRules {
  QotdCommentRules._();

  /// When non-empty, comment must be at least this long (empty is allowed).
  static const int minLengthWhenNonEmpty = 50;

  static const int maxLength = 600;

  /// Collapses whitespace and strips line breaks to spaces (single line for storage).
  static String normalize(String raw) {
    return raw
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }

  /// `null` = valid. Otherwise error message for [TextFormField.validator].
  static String? validateField(String? value) {
    final t = normalize(value ?? '');
    if (t.isEmpty) return null;
    if (t.length < minLengthWhenNonEmpty) {
      return 'Write at least $minLengthWhenNonEmpty characters, or leave this blank.';
    }
    if (t.length > maxLength) {
      return 'Please keep it under $maxLength characters.';
    }
    return null;
  }
}
