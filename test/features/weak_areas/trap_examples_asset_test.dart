import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/weak_areas/domain/trap_example.dart';

List<Map<String, dynamic>> _load(String path) {
  final raw = File(path).readAsStringSync();
  return (json.decode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
}

void main() {
  final examples = {
    for (final item in _load('assets/data/trap_examples.json'))
      item['trap_type'] as String: TrapExample.fromJson(item),
  };
  final catalogTraps = _load(
    'assets/data/trap_descriptions.json',
  ).map((item) => item['trap_type'] as String).toSet();

  test('every trap in the catalog has an example question', () {
    expect(examples.keys.toSet(), catalogTraps);
  });

  test('every example is written in both English and Hindi', () {
    for (final entry in examples.entries) {
      expect(entry.value.hi, isNotNull, reason: entry.key);
      expect(
        entry.value.forLanguage('hi').stem,
        isNot(entry.value.en.stem),
        reason: entry.key,
      );
    }
  });

  test('each language has four filled options and a valid answer key', () {
    for (final entry in examples.entries) {
      final example = entry.value;
      for (final language in const ['en', 'hi']) {
        final content = example.forLanguage(language);
        final reason = '${entry.key} ($language)';
        expect(content.stem, isNotEmpty, reason: reason);
        expect(content.options.keys.toList(), [
          'a',
          'b',
          'c',
          'd',
        ], reason: reason);
        expect(
          content.options.values.every((o) => o.isNotEmpty),
          isTrue,
          reason: reason,
        );
        expect(
          content.options.containsKey(example.correctOption),
          isTrue,
          reason: reason,
        );
        expect(content.why, isNotEmpty, reason: reason);
      }
    }
  });

  test('no example repeats an option, which would give away the answer', () {
    for (final entry in examples.entries) {
      for (final language in const ['en', 'hi']) {
        final texts = entry.value
            .forLanguage(language)
            .options
            .values
            .map((o) => o.toLowerCase());
        expect(texts.toSet(), hasLength(4), reason: '${entry.key} ($language)');
      }
    }
  });
}
