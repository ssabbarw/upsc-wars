import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

void main() {
  test('AuthRouterIdentity ignores uid / token-only changes', () {
    const a = AuthRouterIdentity(authReady: true, isSuperUser: false);
    const b = AuthRouterIdentity(authReady: true, isSuperUser: false);
    const superUser = AuthRouterIdentity(authReady: true, isSuperUser: true);
    const notReady = AuthRouterIdentity(authReady: false, isSuperUser: false);

    expect(a, equals(b));
    // Anonymous → Google (uid change) must not recreate GoRouter.
    expect(a, equals(b));
    expect(a, isNot(equals(superUser)));
    expect(a, isNot(equals(notReady)));
  });
}
