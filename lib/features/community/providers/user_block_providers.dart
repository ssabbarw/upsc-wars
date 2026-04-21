import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../home/providers/auth_providers.dart';
import 'community_providers.dart';

String? _currentUserEmail(Ref ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final email = user?.email?.trim().toLowerCase();
  if (email == null || email.isEmpty) return null;
  return email;
}

/// Lowercased emails the current user has blocked.
final blockedUserEmailsProvider = StreamProvider<Set<String>>((ref) {
  final email = _currentUserEmail(ref);
  if (email == null) {
    return Stream.value(const <String>{});
  }
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchBlockedEmails(email);
});

/// True if [otherEmail] is blocked by the signed-in user.
final isPeerBlockedProvider =
    Provider.family<bool, String>((ref, otherEmail) {
  final normalized = otherEmail.toLowerCase().trim();
  final blocked = ref.watch(blockedUserEmailsProvider).value;
  if (blocked == null) return false;
  return blocked.contains(normalized);
});
