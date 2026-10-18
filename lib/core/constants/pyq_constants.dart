/// Previous-year questions (PYQ) packs and session tagging.
abstract final class PyqConstants {
  PyqConstants._();

  static const int questionsPerPack = 25;

  static String subjectSlugForYear(String year) => 'upsc_pyq_$year';

  /// Stored on [Sessions.topic] to identify which 25-Q block was attempted.
  static String packTopic(int zeroBasedPackIndex) =>
      'pyq_25:$zeroBasedPackIndex';
}
