import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../data/test_series_access_service.dart';
import '../data/test_series_purchase_service.dart';
import '../domain/test_series_models.dart';
import '../providers/test_series_providers.dart';

/// Store listing (price) for a series' one-time pass.
final seriesProductProvider = FutureProvider.autoDispose
    .family<StoreProduct?, String>((ref, productId) async {
      final service = ref.watch(testSeriesPurchaseServiceProvider);
      if (!service.isSupported) return null;
      await service.sync(accountUid: FirebaseAuth.instance.currentUser?.uid);
      return service.loadProduct(productId);
    });

/// Opens the paywall. Resolves to `true` when the series was unlocked.
Future<bool> showSeriesPaywall({
  required BuildContext context,
  required SeriesBundle bundle,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SeriesPaywallSheet(bundle: bundle),
  );
  return result ?? false;
}

class SeriesPaywallSheet extends HookConsumerWidget {
  const SeriesPaywallSheet({super.key, required this.bundle});

  final SeriesBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final service = ref.watch(testSeriesPurchaseServiceProvider);
    final productAsync = ref.watch(seriesProductProvider(bundle.info.productId));
    final busy = useState(false);
    final canSell = ref.watch(testSeriesCanSellProvider).asData?.value ?? false;
    final access = ref.watch(testSeriesAccessServiceProvider);
    final offer = ref.watch(testSeriesOpenOfferProvider).asData?.value;
    final isFreeOffer = offer != null && offer.seriesId == bundle.info.id;

    final showCodeField = useState(false);
    final codeCtrl = useTextEditingController();
    final codeError = useState<String?>(null);
    // Set when Restore finds nothing, so the user sees why and what to do next.
    final restoreNote = useState<String?>(null);

    bool unlocks(Set<String> owned) =>
        owned.contains(bundle.info.entitlementId) ||
        owned.contains(bundle.info.id);

    final tests = bundle.tests;
    final paid = tests.where((t) => !t.isFree).length;
    final free = tests.length - paid;
    final mocks = bundle.ofKind(SeriesTestKind.fullLength).length;
    final ca = bundle.ofKind(SeriesTestKind.currentAffairs).length;
    final staticCount = bundle.ofKind(SeriesTestKind.staticTest).length;

    void toast(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> buy() async {
      if (busy.value) return;
      busy.value = true;
      try {
        final signedIn = await ensureAccountSignedIn(
          context: context,
          ref: ref,
          reason: 'Sign in with Google so your purchase is saved to your account.',
        );
        if (!signedIn || !context.mounted) return;

        await service.sync(accountUid: FirebaseAuth.instance.currentUser?.uid);
        final product =
            productAsync.asData?.value ??
            await service.loadProduct(bundle.info.productId);
        if (product == null) {
          toast('This pass is not available right now. Please try again later.');
          return;
        }
        final outcome = await service.buy(product);
        if (!context.mounted) return;
        switch (outcome.kind) {
          case PurchaseOutcomeKind.purchased:
            // Store success ≠ entitlement. Unlock only when RC grants
            // [bundle.info.entitlementId] (e.g. prelims_2027).
            var owned = outcome.ownedIds ?? const <String>{};
            if (!unlocks(owned)) {
              owned = await ref.read(ownedSeriesIdsProvider.notifier).restore();
            } else {
              await ref.read(ownedSeriesIdsProvider.notifier).refresh();
              owned = await ref.read(ownedSeriesIdsProvider.future);
            }
            if (!context.mounted) return;
            if (unlocks(owned)) {
              toast('Unlocked! Every test in this series is now yours.');
              Navigator.of(context).pop(true);
            } else {
              toast(
                'Payment went through, but access was not granted yet. '
                'Tap Restore purchase, or check that RevenueCat entitlement '
                '"${bundle.info.entitlementId}" is attached to product '
                '"${bundle.info.productId}".',
              );
            }
          case PurchaseOutcomeKind.cancelled:
            break;
          case PurchaseOutcomeKind.pending:
            toast(outcome.message ?? 'Your payment is pending.');
          case PurchaseOutcomeKind.unavailable:
            toast('Purchases are not available on this device.');
          case PurchaseOutcomeKind.failed:
            toast(outcome.message ?? 'The purchase could not be completed.');
        }
      } finally {
        busy.value = false;
      }
    }

    /// Redeems [code] for the signed-in account (a promo code the user typed,
    /// or the hidden code behind a free-for-everyone offer).
    Future<void> redeem(String code, {required String signInReason}) async {
      if (busy.value) return;
      busy.value = true;
      codeError.value = null;
      restoreNote.value = null;
      try {
        final signedIn = await ensureAccountSignedIn(
          context: context,
          ref: ref,
          reason: signInReason,
        );
        if (!signedIn || !context.mounted) return;

        final outcome = await access.redeem(code);
        if (!context.mounted) return;
        if (!outcome.granted) {
          final message = outcome.message ?? 'That code could not be applied.';
          if (showCodeField.value) {
            codeError.value = message;
          } else {
            toast(message);
          }
          return;
        }

        final notifier = ref.read(ownedSeriesIdsProvider.notifier);
        await notifier.refresh();
        var owned = await ref.read(ownedSeriesIdsProvider.future);
        if (!unlocks(owned)) owned = await notifier.restore();
        if (!context.mounted) return;
        if (unlocks(owned)) {
          toast(
            outcome.kind == RedeemKind.alreadyOwned
                ? 'You already have access to this series.'
                : 'Unlocked! Every test in this series is now yours.',
          );
          Navigator.of(context).pop(true);
        } else {
          toast(
            'Your access was added but has not loaded yet. '
            'Tap Restore purchase in a moment.',
          );
        }
      } on Object {
        toast('Something went wrong. Please try again.');
      } finally {
        busy.value = false;
      }
    }

    Future<void> applyTypedCode() async {
      final code = codeCtrl.text.trim();
      if (code.isEmpty) {
        codeError.value = 'Enter your code first.';
        return;
      }
      await redeem(
        code,
        signInReason: 'Sign in with Google so your access is saved to your account.',
      );
    }

    Future<void> restore() async {
      if (busy.value) return;
      busy.value = true;
      restoreNote.value = null;
      try {
        final signedIn = await ensureAccountSignedIn(
          context: context,
          ref: ref,
          reason: 'Sign in with the Google account you used before.',
        );
        if (!signedIn || !context.mounted) return;
        await service.sync(accountUid: FirebaseAuth.instance.currentUser?.uid);
        final owned = await ref.read(ownedSeriesIdsProvider.notifier).restore();
        if (!context.mounted) return;
        if (unlocks(owned)) {
          toast('Access restored.');
          Navigator.of(context).pop(true);
        } else {
          restoreNote.value = isFreeOffer
              ? 'Nothing was found for this account. You can claim your free access below.'
              : canSell
              ? 'Nothing was found for this account. You can unlock the series below.'
              : 'Nothing was found for this account.';
        }
      } on Object {
        toast('Could not restore. Please check your connection and try again.');
      } finally {
        busy.value = false;
      }
    }

    final price = productAsync.asData?.value?.priceString;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.warning,
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(bundle.info.title, style: AppTextStyles.h2()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'One payment. No subscription. Yours forever, including every '
              'test added later.',
              style: AppTextStyles.bodyMd().copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Bullet('$staticCount subject tests, 50 questions each, with 10% PYQs'),
            _Bullet('$ca current-affairs tests, added on the 1st of every month'),
            _Bullet('$mocks full-length mocks that mirror the real paper (100 Q, 2 hrs)'),
            const _Bullet('Hindi and English on every question and explanation'),
            const _Bullet('Dashboard: accuracy by subject, danger-zone and risk topics'),
            if (free > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$free tests are free to try first, including all PYQ tests.',
                style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (restoreNote.value != null) ...[
              _Notice(restoreNote.value!, color: scheme.onSurface),
              const SizedBox(height: AppSpacing.md),
            ],
            if (isFreeOffer) ...[
              _Notice(
                'Free for you for a limited time. Claim it once and it stays '
                'yours, on every device you sign in on.',
                color: scheme.onSurface,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: busy.value
                    ? null
                    : () => unawaited(
                        redeem(
                          offer.code,
                          signInReason:
                              'Sign in with Google so your free access is saved to your account.',
                        ),
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: busy.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Claim free access'),
              ),
            ] else if (!service.isSupported)
              _Notice(
                'Purchases are not available on this device or build yet.',
                color: scheme.onSurfaceVariant,
              )
            else if (!canSell)
              _Notice(
                'This series is not on sale right now.',
                color: scheme.onSurfaceVariant,
              )
            else
              FilledButton(
                onPressed: busy.value ? null : () => unawaited(buy()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: busy.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        price == null ? 'Unlock all tests' : 'Unlock all tests · $price',
                      ),
              ),
            const SizedBox(height: AppSpacing.sm),
            if (showCodeField.value)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        enabled: !busy.value,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => codeError.value = null,
                        onSubmitted: (_) => unawaited(applyTypedCode()),
                        decoration: InputDecoration(
                          labelText: 'Discount code',
                          errorText: codeError.value,
                          errorMaxLines: 2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: FilledButton.tonal(
                        onPressed: busy.value
                            ? null
                            : () => unawaited(applyTypedCode()),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              )
            else
              TextButton(
                onPressed: busy.value ? null : () => showCodeField.value = true,
                child: const Text('Have a code?'),
              ),
            TextButton(
              onPressed: busy.value ? null : () => unawaited(restore()),
              child: const Text('Restore purchase'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTextStyles.bodyMd())),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(text, style: AppTextStyles.bodySm().copyWith(color: color)),
    );
  }
}
