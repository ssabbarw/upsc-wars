import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// English is the template; Hindi must define every key with the same
/// `{placeholders}`, and brand names must stay in English.
void main() {
  Map<String, dynamic> load(String name) =>
      jsonDecode(File('lib/l10n/$name.arb').readAsStringSync())
          as Map<String, dynamic>;

  final en = load('app_en');
  final hi = load('app_hi');
  final keys = en.keys.where((k) => !k.startsWith('@')).toList();

  Set<String> placeholders(String message) {
    // Top-level `{name}` args; ICU plural/select blocks only contribute their
    // selector, which is declared in the template metadata anyway.
    return RegExp(
      r'\{(\w+)(?:,|\})',
    ).allMatches(message).map((m) => m.group(1)!).toSet();
  }

  test('hindi has every english key', () {
    final missing = keys.where((k) => !hi.containsKey(k)).toList();
    expect(missing, isEmpty);
  });

  test('hindi has no orphan keys', () {
    final extra = hi.keys
        .where((k) => !k.startsWith('@') && !en.containsKey(k))
        .toList();
    expect(extra, isEmpty);
  });

  test('hindi only uses placeholders declared in english', () {
    final bad = <String>[];
    for (final k in keys) {
      final a = placeholders(en[k] as String);
      final b = placeholders(hi[k] as String);
      // Hindi may drop a placeholder (no plural form needed), never add one.
      if (b.difference(a).isNotEmpty) {
        bad.add('$k: en=$a hi=$b');
      }
    }
    expect(bad, isEmpty);
  });

  test('english declares exactly the placeholders it uses', () {
    final bad = <String>[];
    for (final k in keys) {
      final used = placeholders(en[k] as String);
      final meta = en['@$k'];
      final declared = meta is Map && meta['placeholders'] is Map
          ? (meta['placeholders'] as Map).keys.cast<String>().toSet()
          : <String>{};
      if (used.difference(declared).isNotEmpty ||
          declared.difference(used).isNotEmpty) {
        bad.add('$k: used=$used declared=$declared');
      }
    }
    expect(bad, isEmpty);
  });

  test('brand names are never translated', () {
    const brands = [
      'CA Shots',
      'Traps',
      'Prelims',
      'Test Series',
      'Danger Zone',
      'Daily Drill',
      'Week Review',
      'Open Challenge',
      'Revision Queue',
      'Confidence',
      'Weak Areas',
      'Mistake Review',
      'All-India Rank',
    ];
    final bad = <String>[];
    for (final k in keys) {
      final e = en[k] as String;
      final h = hi[k] as String;
      for (final b in brands) {
        if (e.toLowerCase().contains(b.toLowerCase()) &&
            !h.toLowerCase().contains(b.toLowerCase())) {
          bad.add('$k: "$b" missing in Hindi');
        }
      }
    }
    expect(bad, isEmpty);
  });
}
