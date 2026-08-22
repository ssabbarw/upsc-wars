import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/presentation/user_display_name.dart';
import '../../community/services/community_bucket_presence_service.dart';
import '../providers/auth_providers.dart';
import '../services/profile_photo_service.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/auth_provider_sign_in_button.dart';
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
            if (!AuthSession.isAccountSignedIn(user)) {
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
                                    AuthProviderSignInButton(
                                      type: AuthProviderButtonType.apple,
                                      onPressed: isBusy
                                          ? null
                                          : () => ref
                                                .read(
                                                  authActionsProvider.notifier,
                                                )
                                                .signInWithApple(),
                                      isLoading: isBusy,
                                      text: isBusy
                                          ? 'Signing in...'
                                          : 'Continue with Apple',
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  AuthProviderSignInButton(
                                    type: AuthProviderButtonType.google,
                                    onPressed: isBusy
                                        ? null
                                        : () => ref
                                              .read(
                                                authActionsProvider.notifier,
                                              )
                                              .signInWithGoogle(),
                                    isLoading: isBusy,
                                    text: isBusy
                                        ? 'Signing in...'
                                        : 'Continue with Google',
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

            return _SignedInProfileBody(user: user!, isBusy: isBusy);
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
        if (context.mounted) uploadingPhoto.value = false;
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
          padding: EdgeInsets.only(bottom: 20),
          child: _ProfileFooter(),
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
      if (!context.mounted) return;
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

      final tele = telegramController.text.trim();
      if (tele.contains('/')) {
        AppToast.showText(context, 'Telegram username should not contain /');
        return;
      }

      final instaRaw = instagramController.text.trim();
      final insta = instaRaw.replaceAll('@', '').trim();
      if (insta.contains('/')) {
        AppToast.showText(context, 'Instagram username should not contain /');
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
          AppToast.showText(context, 'Community profile updated');
        }
      } finally {
        if (context.mounted) saving.value = false;
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
            const SizedBox(height: 14),
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
