import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/l10n/app_localizations.dart';
import 'package:upsc_wars/features/community/domain/entities/community_user.dart';
import 'package:upsc_wars/features/community/providers/user_block_providers.dart';
import 'package:upsc_wars/features/community/widgets/community_user_profile_sheet.dart';
import 'package:upsc_wars/shared/widgets/pop_to_shell_home_scope.dart';

void main() {
  testWidgets('Invite from community sheet opens battle config, not Home', (
    tester,
  ) async {
    final rootKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/community',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return Scaffold(
              body: navigationShell,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (i) => navigationShell.goBranch(i),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people),
                    label: 'Community',
                  ),
                ],
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Text('HOME_TAB'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/community',
                  builder: (context, state) {
                    return PopToShellHomeScope(
                      child: Scaffold(
                        body: Consumer(
                          builder: (context, ref, _) {
                            return TextButton(
                              onPressed: () {
                                showCommunityUserProfileSheet(
                                  context,
                                  ref,
                                  const CommunityUser(
                                    email: 'peer@example.com',
                                    name: 'Peer',
                                    photoUrl: '',
                                    lastOnlineTime: 1,
                                    acceptingBattleInvites: true,
                                    isInBattleTill: null,
                                    appVersion: null,
                                    telegram: null,
                                    instagram: null,
                                    optionalContact: null,
                                    status: 'hey',
                                    openChallengeTimestamp: null,
                                    openChallengeSubject: null,
                                  ),
                                  currentUserEmail: 'me@example.com',
                                );
                              },
                              child: const Text('Open user'),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/battle/config',
          builder: (context, state) => const Text('BATTLE_CONFIG'),
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: '/chat/:chatId',
          builder: (context, state) => const Text('CHAT'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blockedUserEmailsProvider.overrideWith(_EmptyBlockedUserEmails.new),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open user'));
    await tester.pumpAndSettle();
    expect(find.text('Invite'), findsOneWidget);

    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();

    expect(find.text('BATTLE_CONFIG'), findsOneWidget);
    expect(find.text('HOME_TAB'), findsNothing);
  });
}

class _EmptyBlockedUserEmails extends BlockedUserEmailsNotifier {
  @override
  Future<Set<String>> build() async => const <String>{};
}
