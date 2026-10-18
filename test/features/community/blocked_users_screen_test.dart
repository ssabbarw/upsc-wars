import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/core/providers/super_user_provider.dart';
import 'package:upsc_wars/l10n/app_localizations.dart';
import 'package:upsc_wars/features/community/domain/entities/community_user.dart';
import 'package:upsc_wars/features/community/providers/user_block_providers.dart';
import 'package:upsc_wars/features/community/screens/blocked_users_screen.dart';
import 'package:upsc_wars/shared/widgets/app_toast.dart';

void main() {
  testWidgets('empty blocked list shows empty copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isSuperUserProvider.overrideWithValue(false),
          blockedUserEmailsProvider.overrideWith(_EmptyBlockedUserEmails.new),
          blockedUserProfilesProvider.overrideWith((ref) async => const {}),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BlockedUsersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No one blocked'), findsOneWidget);
    expect(find.text('Unblock'), findsNothing);
  });

  testWidgets('blocked list can unblock a user', (tester) async {
    final blocked = _FakeBlockedUserEmails({
      'peer@example.com',
      'other@example.com',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isSuperUserProvider.overrideWithValue(false),
          blockedUserEmailsProvider.overrideWith(() => blocked),
          blockedUserProfilesProvider.overrideWith(
            (ref) async => {
              'peer@example.com': _user(
                email: 'peer@example.com',
                name: 'Peer',
              ),
              'other@example.com': _user(
                email: 'other@example.com',
                name: 'Other',
              ),
            },
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BlockedUsersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peer'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Unblock'), findsNWidgets(2));

    // Sorted alphabetically: Other first.
    await tester.tap(find.text('Unblock').first);
    await tester.pump();

    expect(find.text('Peer'), findsOneWidget);
    expect(find.text('Unblock'), findsOneWidget);
    AppToast.dismiss();
  });
}

CommunityUser _user({required String email, required String name}) {
  return CommunityUser(
    email: email,
    name: name,
    photoUrl: '',
    lastOnlineTime: 1,
    acceptingBattleInvites: true,
    isInBattleTill: null,
    appVersion: null,
    telegram: null,
    instagram: null,
    optionalContact: null,
    status: null,
    openChallengeTimestamp: null,
    openChallengeSubject: null,
  );
}

class _EmptyBlockedUserEmails extends BlockedUserEmailsNotifier {
  @override
  Future<Set<String>> build() async => const <String>{};
}

class _FakeBlockedUserEmails extends BlockedUserEmailsNotifier {
  _FakeBlockedUserEmails(this._emails);

  Set<String> _emails;

  @override
  Future<Set<String>> build() async => _emails;

  @override
  Future<void> setBlocked({
    required String otherEmail,
    required bool blocked,
  }) async {
    final next = {..._emails};
    if (blocked) {
      next.add(otherEmail.toLowerCase().trim());
    } else {
      next.remove(otherEmail.toLowerCase().trim());
    }
    _emails = next;
    state = AsyncData(next);
  }
}
