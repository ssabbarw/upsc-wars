import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Questions in one numbered practice test.
const practiceTestSize = 25;

/// Subject tests kept for one prelims season. Later questions wait for the
/// next season's reshuffle.
const maxSubjectPracticeTests = 25;

/// Topic tests kept for one prelims season.
const maxTopicPracticeTests = 10;

/// `2027/subject:Polity/03`
String practiceTestId(int season, String scope, int number) {
  final n = number.toString().padLeft(2, '0');
  return '$season/$scope/$n';
}

/// Sort [uuids] by `sha1("$season|$scope|$uuid")` and cut into groups of [size].
///
/// The hash is the same on every device and Dart version. [String.hashCode]
/// and a seeded [Random] are not, so they must not be used here.
///
/// A question added to [uuids] can land in the middle and shift later tests.
/// The bank is not growing mid-season; new questions, if any, should be
/// appended by a later rule rather than mixed into this sort.
List<List<String>> splitIntoTests({
  required int season,
  required String scope,
  required List<String> uuids,
  int size = practiceTestSize,
  int? maxTests,
}) {
  if (uuids.isEmpty || size <= 0) return const [];

  int keyOf(String id) {
    final digest = sha1.convert(utf8.encode('$season|$scope|$id')).bytes;
    return (digest[0] << 24) | (digest[1] << 16) | (digest[2] << 8) | digest[3];
  }

  final sorted = [...uuids]
    ..sort((a, b) {
      final byKey = keyOf(a).compareTo(keyOf(b));
      return byKey != 0 ? byKey : a.compareTo(b);
    });

  final tests = <List<String>>[];
  for (var i = 0; i < sorted.length; i += size) {
    final end = i + size < sorted.length ? i + size : sorted.length;
    tests.add(List<String>.unmodifiable(sorted.sublist(i, end)));
    if (maxTests != null && tests.length >= maxTests) break;
  }
  return tests;
}
