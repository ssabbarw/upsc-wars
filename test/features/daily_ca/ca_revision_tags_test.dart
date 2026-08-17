import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/ca_revision_tags.dart';

void main() {
  group('CaRevisionTags', () {
    test('sanitizeTags drops unknowns, duplicates, and caps at 3', () {
      expect(
        CaRevisionTags.sanitizeTags([
          'Government schemes',
          'Government schemes',
          'World map',
          'Sports',
          'Indian map',
          'Reports & indices',
        ]),
        [
          'Government schemes',
          'World map',
          'Indian map',
        ],
      );
    });

    test('primaryTag is the first non-empty tag', () {
      expect(CaRevisionTags.primaryTag(const []), isNull);
      expect(
        CaRevisionTags.primaryTag(const ['World map', 'Defence & security']),
        'World map',
      );
    });
  });
}
