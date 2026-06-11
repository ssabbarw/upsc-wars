import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/auth/super_user.dart';
import 'package:upsc_wars/core/constants/super_user_emails.dart';

void main() {
  test('SuperUserEmails.contains is case-insensitive', () {
    if (SuperUserEmails.emails.isEmpty) {
      expect(SuperUserEmails.contains('any@example.com'), isFalse);
      return;
    }
    final sample = SuperUserEmails.emails.first;
    expect(SuperUserEmails.contains(sample.toUpperCase()), isTrue);
  });

  test('SuperUser.isSignedIn requires non-anonymous listed email', () {
    final listed = SuperUserEmails.emails.isEmpty
        ? 'editor@example.com'
        : SuperUserEmails.emails.first;

    expect(
      SuperUser.isSignedIn(_FakeUser(email: listed, isAnonymous: false)),
      SuperUserEmails.emails.isNotEmpty,
    );
    expect(
      SuperUser.isSignedIn(_FakeUser(email: listed, isAnonymous: true)),
      isFalse,
    );
    expect(
      SuperUser.isSignedIn(
        _FakeUser(email: 'other@example.com', isAnonymous: false),
      ),
      isFalse,
    );
  });
}

class _FakeUser implements User {
  _FakeUser({required this.email, required this.isAnonymous});

  @override
  final String? email;
  @override
  final bool isAnonymous;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
