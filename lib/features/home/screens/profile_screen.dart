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
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 34,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your Profile',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to sync your progress and keep your preparation data safe across devices.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
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
                                icon: const Icon(Icons.login_rounded),
                                label: Text(
                                  isBusy ? 'Signing in...' : 'Continue with Google',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundImage: user.photoURL != null
                                  ? NetworkImage(user.photoURL!)
                                  : null,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              child: user.photoURL == null
                                  ? Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user.displayName ?? 'Signed in user',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? 'No email',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.verified_user_outlined,
                                label: 'Authentication',
                                value: 'Google account connected',
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                icon: Icons.shield_outlined,
                                label: 'Privacy',
                                value: 'Your account data remains secure',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isBusy
                              ? null
                              : () async {
                                  final shouldLogout =
                                      await _confirmLogout(context);
                                  if (!shouldLogout) return;
                                  ref.read(authActionsProvider.notifier).signOut();
                                },
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(isBusy ? 'Logging out...' : 'Log out'),
                        ),
                      ),
                    ],
                  ),
                ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
