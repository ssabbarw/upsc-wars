import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/home/providers/auth_providers.dart';

void main() {
  test('AuthRouterIdentity ignores token-only changes', () {
    const a = AuthRouterIdentity(
      authReady: true,
      uid: 'uid-1',
      isSuperUser: false,
    );
    const b = AuthRouterIdentity(
      authReady: true,
      uid: 'uid-1',
      isSuperUser: false,
    );
    const signedOut = AuthRouterIdentity(
      authReady: true,
      uid: null,
      isSuperUser: false,
    );

    expect(a, equals(b));
    expect(a, isNot(equals(signedOut)));
  });
}
