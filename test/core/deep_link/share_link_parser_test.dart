import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/deep_link/share_link_kind.dart';
import 'package:upsc_wars/core/deep_link/share_link_parser.dart';

void main() {
  const id1 = '11111111-1111-1111-1111-111111111111';
  const id2 = '22222222-2222-2222-2222-222222222222';
  const share = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  test('parses custom scheme', () {
    final u = Uri.parse(
      'upscwars://share/test/$share?ids=$id1,$id2&subject=Ancient%20History&topic=Education',
    );
    final p = parseShareLinkUri(u)!;
    expect(p.kind, ShareLinkKind.test);
    expect(p.shareId, share);
    expect(p.questionIds, [id1, id2]);
    expect(p.subject, 'Ancient History');
    expect(p.topic, 'Education');
  });

  test('parses https universal link', () {
    final u = Uri.parse('https://upscwars.in/share/battle/$share?ids=$id1');
    final p = parseShareLinkUri(u)!;
    expect(p.kind, ShareLinkKind.battle);
    expect(p.questionIds, [id1]);
  });

  test('question kind requires single id', () {
    final bad = Uri.parse(
      'https://upscwars.in/share/question/$share?ids=$id1,$id2',
    );
    expect(parseShareLinkUri(bad), isNull);

    final good = Uri.parse(
      'https://upscwars.in/share/question/$share?ids=$id1',
    );
    expect(parseShareLinkUri(good)!.questionIds, [id1]);
  });

  test('rejects bad uuid in ids', () {
    final u = Uri.parse('upscwars://share/test/$share?ids=not-a-uuid');
    expect(parseShareLinkUri(u), isNull);
  });

  test('rejects unrelated urls', () {
    expect(
      parseShareLinkUri(Uri.parse('https://example.com/share/test/x')),
      isNull,
    );
    expect(parseShareLinkUri(Uri.parse('https://upscwars.in/other')), isNull);
  });

  test('parses firestore-backed link without ids query', () {
    final u = Uri.parse('https://upscwars.in/share/test/$share');
    final p = parseShareLinkUri(u)!;
    expect(p.questionIds, isEmpty);
    expect(p.shareId, share);
  });

  test('rejects non-uuid share id', () {
    expect(
      parseShareLinkUri(Uri.parse('https://upscwars.in/share/test/not-a-uuid')),
      isNull,
    );
  });
}
