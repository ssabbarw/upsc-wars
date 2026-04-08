import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/app/upsc_wars_app.dart';

void main() {
  testWidgets('App boots with provider scope', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UpscWarsApp()));
    await tester.pump();
    expect(find.byType(UpscWarsApp), findsOneWidget);
  });
}
