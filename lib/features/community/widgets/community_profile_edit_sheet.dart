import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../home/providers/auth_providers.dart';

/// Opens a sheet to edit status / optional subject / social handles shown in
/// Community. Call from the Community tab only.
Future<void> showCommunityProfileEditSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final email =
      AuthSession.emailOf(
        ref.read(authStateChangesProvider).asData?.value,
      ) ??
      AuthSession.currentEmail();
  if (email == null || email.isEmpty) {
    AppToast.showText(context, 'Sign in to edit your community profile.');
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CommunityProfileEditSheet(email: email),
  );
}

class _CommunityProfileEditSheet extends HookConsumerWidget {
  const _CommunityProfileEditSheet({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final statusController = useTextEditingController();
    final optionalController = useTextEditingController();
    final instagramController = useTextEditingController();
    final telegramController = useTextEditingController();
    final loading = useState(true);
    final saving = useState(false);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    useEffect(() {
      unawaited(() async {
        try {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(email.toLowerCase())
              .get();
          if (!context.mounted) return;
          final data = snap.data();
          if (data != null) {
            statusController.text = (data['my_status'] as String?) ?? '';
            optionalController.text = (data['optional'] as String?) ?? '';
            instagramController.text = (data['insta'] as String?) ?? '';
            telegramController.text = (data['telegram'] as String?) ?? '';
          }
        } finally {
          if (context.mounted) loading.value = false;
        }
      }());
      return null;
    }, [email]);

    Future<void> save() async {
      if (saving.value) return;

      final tele = telegramController.text.trim();
      if (tele.contains('/')) {
        AppToast.showText(context, context.l10n.profileTelegramSlash);
        return;
      }

      final instaRaw = instagramController.text.trim();
      final insta = instaRaw.replaceAll('@', '').trim();
      if (insta.contains('/')) {
        AppToast.showText(context, context.l10n.profileInstagramSlash);
        return;
      }

      saving.value = true;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(email.toLowerCase())
            .set({
              'my_status': statusController.text.trim(),
              'optional': optionalController.text.trim(),
              'insta': insta,
              'telegram': tele,
              'lastOnlineTime': DateTime.now().millisecondsSinceEpoch,
            }, SetOptions(merge: true));
        if (!context.mounted) return;
        AppToast.showText(context, context.l10n.profileCommunityUpdated);
        Navigator.of(context).pop();
      } finally {
        if (context.mounted) saving.value = false;
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: loading.value
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.profileCommunityTitle,
                    style: AppTextStyles.h3().copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'What other aspirants see when they tap you. Keep it short — '
                    'status is a vibe, not a manifesto.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: optionalController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: context.l10n.profileOptionalSubject,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: instagramController,
                    maxLength: 30,
                    decoration: InputDecoration(
                      labelText: context.l10n.profileInstagramLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: telegramController,
                    maxLength: 30,
                    decoration: InputDecoration(
                      labelText: context.l10n.profileTelegramLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: saving.value ? null : save,
                    child: Text(
                      saving.value
                          ? context.l10n.profileUpdating
                          : context.l10n.profileUpdate,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
