import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';

void main() {
  const columns = ['Economic Growth Drivers', 'Mechanism of Impact'];

  test('reads cells from semantic column keys', () {
    final rows = questionTableRowsAsCells(
      [
        {
          'Economic Growth Drivers': 'A. Nominal rupee appreciation',
          'Mechanism of Impact': '2. Inflates the rupee value of GDP',
        },
      ],
      columns,
    );
    expect(rows, [
      [
        'A. Nominal rupee appreciation',
        '2. Inflates the rupee value of GDP',
      ],
    ]);
  });

  test('falls back to col_i and list_i when headers are translated', () {
    final rows = questionTableRowsAsCells(
      [
        {
          'list_i': 'A. Item',
          'list_ii': '1. Match',
          'col_0': 'A. Item',
          'col_1': '1. Match',
        },
      ],
      ['आर्थिक वृद्धि के चालक', 'प्रभाव का तंत्र'],
    );
    expect(rows, [
      ['A. Item', '1. Match'],
    ]);
  });

  test('reads share-map {cells: [...]} rows', () {
    final rows = questionTableRowsAsCells(
      [
        {
          'cells': ['A. Left', '1. Right'],
        },
      ],
      columns,
    );
    expect(rows, [
      ['A. Left', '1. Right'],
    ]);
  });
}
