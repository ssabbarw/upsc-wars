import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/daily_ca_share_constants.dart';
import 'package:upsc_wars/features/daily_ca/data/daily_ca_incoming_share.dart';
import 'package:upsc_wars/features/daily_ca/data/daily_ca_share.dart';

void main() {
  const date = '2026-10-17';

  test('share URI defaults to /daily-ca/today', () {
    expect(
      dailyCaShareUri().toString(),
      'https://upscwars.in/daily-ca/today',
    );
  });

  test('share URI can pin a date', () {
    expect(
      dailyCaShareUri(date).toString(),
      'https://upscwars.in/daily-ca/$date',
    );
  });

  test('parses https and custom-scheme links', () {
    expect(
      parseDailyCaDateSegmentFromUri(
        Uri.parse('https://upscwars.in/daily-ca/today'),
      ),
      'today',
    );
    expect(
      parseDailyCaDateSegmentFromUri(
        Uri.parse('https://upscwars.in/daily-ca/$date'),
      ),
      date,
    );
    expect(
      parseDailyCaDateSegmentFromUri(Uri.parse('upscwars://daily-ca/today')),
      'today',
    );
    expect(
      parseDailyCaDateSegmentFromUri(Uri.parse('upscwars://daily-ca/$date')),
      date,
    );
  });

  test('ignores leaderboard nested paths on https', () {
    expect(
      parseDailyCaDateSegmentFromUri(
        Uri.parse('https://upscwars.in/daily-ca/$date/leaderboard'),
      ),
      isNull,
    );
  });

  test('in-app date location includes share query', () {
    expect(
      DailyCaShareConstants.dateLocation(
        'today',
        source: DailyCaShareConstants.entryShare,
        start: true,
      ),
      '/daily-ca/today?src=share&start=1',
    );
    expect(
      DailyCaShareConstants.dateLocation(date),
      '/daily-ca/$date',
    );
  });
}
