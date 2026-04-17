import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../../shared/widgets/google_login_bottom_sheet.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final authActions = ref.watch(authActionsProvider);
    final isBusy = authActions.isLoading;

    return Scaffold(
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return Center(
                child: FilledButton(
                  onPressed: isBusy
                      ? null
                      : () => showGoogleLoginBottomSheet(
                          context: context,
                          isLoading: isBusy,
                          onGoogleTap: () {
                            Navigator.of(context).pop();
                            ref
                                .read(authActionsProvider.notifier)
                                .signInWithGoogle();
                          },
                        ),
                  child: const Text('Sign in'),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? const Icon(Icons.person, size: 36)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? 'Signed in user',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email ?? 'No email',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: isBusy
                        ? null
                        : () async {
                            final shouldLogout = await _confirmLogout(context);
                            if (!shouldLogout) return;
                            ref.read(authActionsProvider.notifier).signOut();
                          },
                    icon: const Icon(Icons.logout),
                    label: Text(isBusy ? 'Logging out...' : 'Logout'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}
