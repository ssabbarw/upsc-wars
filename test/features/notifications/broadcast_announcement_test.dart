import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/services/broadcast_announcement_cloud_service.dart';
import 'package:upsc_wars/features/notifications/broadcast_announcement_defaults.dart';

void main() {
  test('update defaults stay within FCM title/body limits', () {
    expect(BroadcastAnnouncementDefaults.title.length, lessThanOrEqualTo(120));
    expect(BroadcastAnnouncementDefaults.body.length, lessThanOrEqualTo(180));
  });

  test('toCallableMap can send without writing HTML', () {
    const request = BroadcastAnnouncementRequest(
      title: 'Please update Upsc Wars',
      body: 'A new version is live.',
      openLongHtml: true,
      saveHtml: false,
      target: BroadcastAnnouncementTarget.broadcast,
    );
    expect(request.toCallableMap(), {
      'title': 'Please update Upsc Wars',
      'body': 'A new version is live.',
      'html': '',
      'openLongHtml': true,
      'saveHtml': false,
      'kind': 'announcement',
      'target': 'broadcast',
    });
  });

  test('saveHtml is true only when HTML is present', () {
    const empty = BroadcastAnnouncementRequest(
      title: 'Hi',
      body: 'Body',
      html: '   ',
      openLongHtml: true,
      saveHtml: true,
      target: BroadcastAnnouncementTarget.self,
    );
    expect(empty.toCallableMap()['saveHtml'], isFalse);
    expect(empty.toCallableMap()['openLongHtml'], isTrue);

    const withHtml = BroadcastAnnouncementRequest(
      title: 'Hi',
      body: 'Body',
      html: '<p>page</p>',
      saveHtml: true,
      openLongHtml: true,
      target: BroadcastAnnouncementTarget.self,
    );
    expect(withHtml.toCallableMap()['saveHtml'], isTrue);
  });
}
