import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/super_user.dart';
import '../../../core/domain/repositories/auth_repository.dart';
import '../data/repositories/firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Uses [AuthRepository.userChanges] so UI rebuilds when [User.photoURL] or
/// other profile fields update (not only sign-in / sign-out).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.userChanges();
});

/// Stable auth identity for [appRouterProvider].
///
/// Token refreshes (`getIdToken(true)`) also emit [userChanges], but must not
/// recreate [GoRouter] (that resets navigation to `/`).
@immutable
class AuthRouterIdentity {
  const AuthRouterIdentity({
    required this.authReady,
    required this.uid,
    required this.isSuperUser,
  });

  final bool authReady;
  final String? uid;
  final bool isSuperUser;

  @override
  bool operator ==(Object other) {
    return other is AuthRouterIdentity &&
        other.authReady == authReady &&
        other.uid == uid &&
        other.isSuperUser == isSuperUser;
  }

  @override
  int get hashCode => Object.hash(authReady, uid, isSuperUser);
}

final authRouterIdentityProvider = Provider<AuthRouterIdentity>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  final authReady = authAsync.hasValue;
  final user = authAsync.asData?.value;
  return AuthRouterIdentity(
    authReady: authReady,
    uid: user?.uid,
    isSuperUser: authReady && SuperUser.isSignedIn(user),
  );
});

class AuthActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithGoogle();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('AuthActionsNotifier.signInWithGoogle error: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = AsyncError(authErrorMessage(error), stackTrace);
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithApple();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('AuthActionsNotifier.signInWithApple error: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = AsyncError(authErrorMessage(error), stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      debugPrint('AuthActionsNotifier.signOut error: $error');
      debugPrintStack(stackTrace: stackTrace);
      state = AsyncError(authErrorMessage(error), stackTrace);
    }
  }
}

final authActionsProvider = AsyncNotifierProvider<AuthActionsNotifier, void>(
  AuthActionsNotifier.new,
);

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'sign_in_cancelled':
        return 'Sign-in was cancelled. Please try again.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked with another sign-in method.';
      case 'invalid-credential':
        return 'Invalid sign-in credential. Please try again.';
      case 'missing_google_id_token':
        return 'Could not retrieve Google token. Please retry.';
      case 'missing_apple_identity_token':
        return 'Could not retrieve Apple token. Please retry.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
  return 'Something went wrong during authentication. Please try again.';
}
