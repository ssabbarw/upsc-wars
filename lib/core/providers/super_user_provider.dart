import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/super_user.dart';
import '../../features/home/providers/auth_providers.dart';

/// `true` when a listed super-user email is signed in (non-anonymous).
final isSuperUserProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  return SuperUser.isSignedIn(user);
});
