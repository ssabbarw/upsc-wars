import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/tappable_circular_avatar.dart';
import '../../community/services/community_bucket_presence_service.dart';
import '../services/profile_photo_service.dart';

class CompleteProfileScreen extends HookConsumerWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    final nameController = useTextEditingController(
      text: (user?.displayName ?? '').trim(),
    );
    final saving = useState(false);
    final uploadingPhoto = useState(false);
    final photoService = useMemoized(ProfilePhotoService.new);

    Future<void> onChangePhoto() async {
      if (uploadingPhoto.value || saving.value) return;
      uploadingPhoto.value = true;
      try {
        final (ok, err) = await photoService.pickCropUploadAndUpdateProfile();
        if (!context.mounted) return;
        if (ok) {
          AppToast.showText(context, 'Photo updated');
          unawaited(CommunityBucketPresenceService.syncForCurrentUser(ref));
        } else if (err != null) {
          AppToast.showText(context, err);
        }
      } finally {
        uploadingPhoto.value = false;
      }
    }

    Future<void> onSave() async {
      if (saving.value) return;
      final u = auth.currentUser;
      if (u == null) {
        if (context.mounted) context.go('/profile');
        return;
      }

      final name = nameController.text.trim();
      if (name.length < 2) {
        AppToast.showText(context, 'Please enter your name');
        return;
      }

      saving.value = true;
      try {
        await u.updateProfile(displayName: name);
        await u.reload();
        unawaited(CommunityBucketPresenceService.syncForCurrentUser(ref));
        if (!context.mounted) return;
        AppToast.showText(context, 'Profile updated');
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.showText(context, 'Could not update profile: $e');
        }
      } finally {
        saving.value = false;
      }
    }

    final scheme = Theme.of(context).colorScheme;
    final effectiveUser = user;
    final displayName =
        (effectiveUser?.displayName ?? '').trim().isNotEmpty
            ? effectiveUser!.displayName!.trim()
            : 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  'This helps others recognize you in Community and chat.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 18),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            TappableCircularAvatar(
                              imageUrl: effectiveUser?.photoURL,
                              displayName: displayName,
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
                                    onTap: uploadingPhoto.value ? null : onChangePhoto,
                                    customBorder: const CircleBorder(),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: uploadingPhoto.value
                                          ? SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => unawaited(onSave()),
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. Sachin',
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: saving.value ? null : onSave,
                            child: Text(saving.value ? 'Saving…' : 'Save'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'You can change your photo anytime from Profile.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Privacy note: Apple may not share your real email/name on future sign-ins. '
                  'We store this name only to show it inside ${AppConstants.appDisplayName}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

