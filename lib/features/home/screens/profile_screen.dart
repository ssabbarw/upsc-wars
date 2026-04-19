import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/auth_providers.dart';
import '../../../shared/widgets/google_login_bottom_sheet.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.45,
        );
    return Column(
      children: [
        Text(
          'Current app version: ${AppConstants.releaseVersionLabel}',
          textAlign: TextAlign.center,
          style: style,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Made with love ', style: style),
            Icon(
              Icons.favorite,
              size: 15,
              color: scheme.error.withValues(alpha: 0.9),
            ),
            Text(' in Delhi', style: style),
          ],
        ),
      ],
    );
  }
}

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
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
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
                            const TappableCircularAvatar(
                              imageUrl: null,
                              displayName: 'User',
                              size: 64,
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
                            const SizedBox(height: 16),
                            const _ProfileFooter(),
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
                                              .read(
                                                authActionsProvider.notifier,
                                              )
                                              .signInWithGoogle();
                                        },
                                      ),
                                icon: const Icon(Icons.login_rounded),
                                label: Text(
                                  isBusy
                                      ? 'Signing in...'
                                      : 'Continue with Google',
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

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer
                                        .withValues(alpha: 0.85),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  TappableCircularAvatar(
                                    imageUrl: user.photoURL,
                                    displayName:
                                        user.displayName ??
                                        user.email ??
                                        'Signed in user',
                                    size: 84,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    user.displayName ?? 'Signed in user',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email ?? 'No email',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
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
                            _CommunityProfileCard(
                              email: user.email,
                              isBusy: isBusy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _ProfileFooter(),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () async {
                                final shouldLogout = await _confirmLogout(
                                  context,
                                );
                                if (!shouldLogout) return;
                                ref
                                    .read(authActionsProvider.notifier)
                                    .signOut();
                              },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(isBusy ? 'Logging out...' : 'Log out'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _CommunityProfileCard extends HookConsumerWidget {
  const _CommunityProfileCard({required this.email, required this.isBusy});

  final String? email;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusController = useTextEditingController();
    final optionalController = useTextEditingController();
    final instagramController = useTextEditingController();
    final telegramController = useTextEditingController();
    final didLoad = useState(false);
    final saving = useState(false);

    Future<void> loadCommunityProfile() async {
      final userEmail = email;
      if (userEmail == null || userEmail.isEmpty || didLoad.value) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail.toLowerCase())
          .get();
      final data = snap.data();
      if (data != null) {
        statusController.text = (data['my_status'] as String?) ?? '';
        optionalController.text = (data['optional'] as String?) ?? '';
        instagramController.text = (data['insta'] as String?) ?? '';
        telegramController.text = (data['telegram'] as String?) ?? '';
      }
      didLoad.value = true;
    }

    useEffect(() {
      Future(loadCommunityProfile);
      return null;
    }, [email]);

    Future<void> saveCommunityProfile() async {
      final userEmail = email;
      if (userEmail == null || userEmail.isEmpty) return;
      if (saving.value) return;

      final insta = instagramController.text.trim();
      final tele = telegramController.text.trim();
      if (insta.contains('/') || tele.contains('/')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instagram/Telegram should not contain /'),
          ),
        );
        return;
      }

      saving.value = true;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail.toLowerCase())
            .set({
              'my_status': statusController.text.trim(),
              'optional': optionalController.text.trim(),
              'insta': insta,
              'telegram': tele,
              'lastOnlineTime': DateTime.now().millisecondsSinceEpoch,
            }, SetOptions(merge: true));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Community profile updated')),
          );
        }
      } finally {
        saving.value = false;
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Complete these fields so aspirants can connect with you.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: statusController,
              maxLength: 280,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: optionalController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Optional Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: instagramController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Instagram (without @)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: telegramController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Telegram (without @)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isBusy || saving.value ? null : saveCommunityProfile,
                child: Text(saving.value ? 'Updating...' : 'Update'),
              ),
            ),
          ],
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
