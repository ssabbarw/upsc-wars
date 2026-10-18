import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/providers/super_user_provider.dart';
import 'package:upsc_wars/features/community/domain/community_bot.dart';
import 'package:upsc_wars/features/community/providers/community_providers.dart';
import 'package:upsc_wars/features/community/widgets/admin_bot_label.dart';

void main() {
  const botEmail = 'priya.k42@community.upscwars.in';
  const botUid = 'bot_priya_k42';
  const index = TrafficBotIndex(emails: {botEmail}, uids: {botUid});

  Widget wrap({
    required bool isSuperUser,
    required TrafficBotIndex bots,
    String? email,
    String? uid,
  }) {
    return ProviderScope(
      overrides: [
        isSuperUserProvider.overrideWithValue(isSuperUser),
        trafficBotIndexProvider.overrideWith((ref) => Stream.value(bots)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AdminBotLabel(email: email, uid: uid),
        ),
      ),
    );
  }

  testWidgets('hidden for regular users', (tester) async {
    await tester.pumpWidget(
      wrap(isSuperUser: false, bots: index, email: botEmail),
    );
    await tester.pump();
    expect(find.byTooltip('Bot'), findsNothing);
    expect(find.text('Bot'), findsNothing);
  });

  testWidgets('hidden for super users when the person is not a bot', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        isSuperUser: true,
        bots: index,
        email: 'human@example.com',
        uid: 'human-1',
      ),
    );
    await tester.pump();
    expect(find.byTooltip('Bot'), findsNothing);
    expect(find.text('Bot'), findsNothing);
  });

  testWidgets('super user sees a tooltip mark, not a Bot chip', (tester) async {
    await tester.pumpWidget(
      wrap(isSuperUser: true, bots: index, email: botEmail, uid: botUid),
    );
    await tester.pump();
    expect(find.text('Bot'), findsNothing);
    expect(find.byTooltip('Bot'), findsOneWidget);
  });
}
