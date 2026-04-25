import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../community/services/community_bucket_presence_service.dart';
import '../providers/auth_providers.dart';
import '../services/instagram_link_service.dart';
import '../services/profile_photo_service.dart';
import '../../../shared/widgets/app_toast.dart';
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

Future<bool> _confirmProfileLogout(BuildContext context) async {
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

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

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
                              'Sign in to join the community, participate in battles, and build your profile.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            const _ProfileFooter(),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!kIsWeb &&
                                      defaultTargetPlatform ==
                                          TargetPlatform.iOS) ...[
                                    FutureBuilder<bool>(
                                      future: SignInWithApple.isAvailable(),
                                      builder: (context, snapshot) {
                                        final available =
                                            snapshot.data ?? false;
                                        if (!available) {
                                          return const SizedBox.shrink();
                                        }
                                        final isDark =
                                            Theme.of(context).brightness ==
                                            Brightness.dark;
                                        return SizedBox(
                                          width: double.infinity,
                                          child: SignInWithAppleButton(
                                            onPressed: isBusy
                                                ? null
                                                : () => ref
                                                      .read(
                                                        authActionsProvider
                                                            .notifier,
                                                      )
                                                      .signInWithApple(),
                                            style: isDark
                                                ? SignInWithAppleButtonStyle
                                                      .white
                                                : SignInWithAppleButtonStyle
                                                      .black,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            height: 48,
                                            text: isBusy
                                                ? 'Signing in...'
                                                : 'Continue with Apple',
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  IgnorePointer(
                                    ignoring: isBusy,
                                    child: Opacity(
                                      opacity: isBusy ? 0.6 : 1,
                                      child: SizedBox(
                                        height: 48,
                                        child: SignInButton(
                                          Buttons.google,
                                          onPressed: () => ref
                                              .read(
                                                authActionsProvider.notifier,
                                              )
                                              .signInWithGoogle(),
                                          text: isBusy
                                              ? 'Signing in...'
                                              : 'Continue with Google',
                                          textStyle: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

            return _SignedInProfileBody(user: user, isBusy: isBusy);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _SignedInProfileBody extends HookConsumerWidget {
  const _SignedInProfileBody({required this.user, required this.isBusy});

  final User user;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadingPhoto = useState(false);
    final photoService = useMemoized(ProfilePhotoService.new);

    Future<void> onChangePhoto() async {
      if (uploadingPhoto.value) return;
      uploadingPhoto.value = true;
      try {
        final (ok, err) = await photoService.pickCropUploadAndUpdateProfile();
        if (!context.mounted) return;
        if (ok) {
          AppToast.showText(context, 'Profile photo updated');
          unawaited(CommunityBucketPresenceService.syncForCurrentUser(ref));
        } else if (err != null) {
          AppToast.showText(context, err);
        }
      } finally {
        uploadingPhoto.value = false;
      }
    }

    final scheme = Theme.of(context).colorScheme;
    final profileNameLabel = displayNameForViewer(
      name: user.displayName ?? user.email ?? 'Signed in user',
      viewerEmail: user.email,
      subjectEmail: user.email,
    );

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
                            scheme.primaryContainer,
                            scheme.secondaryContainer.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              TappableCircularAvatar(
                                imageUrl: user.photoURL,
                                displayName: profileNameLabel,
                                size: 84,
                              ),
                              if (!kIsWeb)
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Material(
                                    color: scheme.surface,
                                    elevation: 2,
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: uploadingPhoto.value || isBusy
                                          ? null
                                          : onChangePhoto,
                                      customBorder: const CircleBorder(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: uploadingPhoto.value
                                            ? SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: scheme.primary,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.photo_camera_outlined,
                                                size: 20,
                                                color: scheme.primary,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (kIsWeb) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Profile photo can be changed in the Android or iOS app.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            profileNameLabel,
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
                            const _InfoRow(
                              icon: Icons.verified_user_outlined,
                              label: 'Authentication',
                              value: 'Account connected',
                            ),
                            const SizedBox(height: 10),
                            const _InfoRow(
                              icon: Icons.shield_outlined,
                              label: 'Privacy',
                              value: 'Your account data remains secure',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CommunityProfileCard(email: user.email, isBusy: isBusy),
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
                        final shouldLogout = await _confirmProfileLogout(
                          context,
                        );
                        if (!shouldLogout) return;
                        ref.read(authActionsProvider.notifier).signOut();
                      },
                icon: const Icon(Icons.logout_rounded),
                label: Text(isBusy ? 'Logging out...' : 'Log out'),
              ),
            ),
          ),
        ),
      ],
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
    final telegramController = useTextEditingController();
    final didLoad = useState(false);
    final saving = useState(false);
    final instagramBusy = useState(false);
    final instagramLinked = useState(false);
    final instagramHandle = useState('');
    final scheme = Theme.of(context).colorScheme;

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
        telegramController.text = (data['telegram'] as String?) ?? '';
        final ig = (data['insta'] as String?)?.trim() ?? '';
        instagramHandle.value = ig;
        final linked = data['insta_user_id'] != null;
        instagramLinked.value = linked;
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

      final tele = telegramController.text.trim();
      if (tele.contains('/')) {
        AppToast.showText(context, 'Telegram username should not contain /');
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
              'telegram': tele,
              'lastOnlineTime': DateTime.now().millisecondsSinceEpoch,
            }, SetOptions(merge: true));
        if (context.mounted) {
          AppToast.showText(context, 'Community profile updated');
        }
      } finally {
        saving.value = false;
      }
    }

    Future<void> onConnectInstagram() async {
      if (instagramBusy.value || isBusy) return;
      instagramBusy.value = true;
      try {
        final username = await InstagramLinkService.connectInstagramAccount();
        instagramHandle.value = username;
        instagramLinked.value = true;
        if (context.mounted) {
          AppToast.showText(context, 'Instagram @$username connected');
        }
      } on InstagramLinkCancelled {
        // User closed the browser; no message.
      } on InstagramLinkFailed catch (e) {
        if (context.mounted) {
          AppToast.showText(context, e.message);
        }
      } on FirebaseFunctionsException catch (e) {
        if (context.mounted) {
          AppToast.showText(context, e.message ?? e.code);
        }
      } on UnsupportedError catch (e) {
        if (context.mounted) {
          AppToast.showText(context, e.toString());
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.showText(context, e.toString());
        }
      } finally {
        instagramBusy.value = false;
      }
    }

    Future<void> onDisconnectInstagram() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Disconnect Instagram?'),
          content: const Text(
            'Your profile will no longer show a verified Instagram link.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
      if (ok != true || instagramBusy.value) return;
      instagramBusy.value = true;
      try {
        await InstagramLinkService.unlinkInstagramAccount();
        instagramLinked.value = false;
        instagramHandle.value = '';
        if (context.mounted) {
          AppToast.showText(context, 'Instagram disconnected');
        }
      } on FirebaseFunctionsException catch (e) {
        if (context.mounted) {
          AppToast.showText(context, e.message ?? e.code);
        }
      } finally {
        instagramBusy.value = false;
      }
    }

    final igConfigured = AppConstants.instagramOAuthAppId.trim().isNotEmpty;

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
            const SizedBox(height: 14),
            Text('Instagram', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              kIsWeb
                  ? 'Open the mobile app to connect Instagram.'
                  : 'Uses Meta login. Instagram Professional (Business or Creator) accounts only.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (!igConfigured)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Instagram linking is not enabled in this build (missing INSTAGRAM_APP_ID).',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ),
            if (instagramLinked.value) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      instagramHandle.value.isEmpty
                          ? 'Connected'
                          : '@${instagramHandle.value}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Icon(Icons.verified_rounded, color: scheme.primary, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    'Verified',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: instagramBusy.value || isBusy
                      ? null
                      : onDisconnectInstagram,
                  child: const Text('Disconnect Instagram'),
                ),
              ),
            ] else ...[
              if (instagramHandle.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Previous unverified handle (replaced when you connect): '
                    '@${instagramHandle.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      (!igConfigured || kIsWeb || instagramBusy.value || isBusy)
                      ? null
                      : onConnectInstagram,
                  icon: instagramBusy.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.link_rounded),
                  label: Text(
                    instagramBusy.value ? 'Connecting…' : 'Connect Instagram',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
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
