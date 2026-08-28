import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/fomo_pulse/data/fomo_pulse_incoming_share.dart';
import 'package:upsc_wars/features/fomo_pulse/data/fomo_pulse_share.dart';
import 'package:upsc_wars/features/fomo_pulse/fomo_pulse_constants.dart';

void main() {
  const id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  test('share URI uses /ca-shot and not fomo', () {
    final uri = fomoPulseShareUri(id);
    expect(uri.toString(), 'https://upscwars.in/ca-shot/$id');
    expect(uri.path, isNot(contains('fomo')));
  });

  test('parses current https and custom-scheme links', () {
    expect(
      parseFomoPulseIdFromUri(Uri.parse('https://upscwars.in/ca-shot/$id')),
      id,
    );
    expect(parseFomoPulseIdFromUri(Uri.parse('upscwars://ca-shot/$id')), id);
  });

  test('still parses legacy fomo-pulse links', () {
    expect(
      parseFomoPulseIdFromUri(Uri.parse('https://upscwars.in/fomo-pulse/$id')),
      id,
    );
    expect(parseFomoPulseIdFromUri(Uri.parse('upscwars://fomo-pulse/$id')), id);
  });

  test('in-app detail path uses /ca-shot', () {
    expect(FomoPulseConstants.detailLocation(id), '/ca-shot/$id');
    expect(
      FomoPulseConstants.detailLocation(id, source: 'share'),
      '/ca-shot/$id?src=share',
    );
  });
}
