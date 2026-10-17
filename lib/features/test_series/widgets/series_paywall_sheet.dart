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
            await ref.read(ownedSeriesIdsProvider.notifier).refresh();
            if (context.mounted) {
              toast('Unlocked! Every test in this series is now yours.');
              Navigator.of(context).pop(true);
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

    Future<void> restore() async {
      if (busy.value) return;
      busy.value = true;
      try {
        final signedIn = await ensureAccountSignedIn(
          context: context,
          ref: ref,
          reason: 'Sign in with the Google account you used to buy.',
        );
        if (!signedIn || !context.mounted) return;
        await service.sync(accountUid: FirebaseAuth.instance.currentUser?.uid);
        final owned = await ref.read(ownedSeriesIdsProvider.notifier).restore();
        if (!context.mounted) return;
        if (owned.contains(bundle.info.entitlementId)) {
          toast('Purchase restored.');
          Navigator.of(context).pop(true);
        } else {
          toast('No purchase found for this account.');
        }
      } on Object {
        toast('Could not restore purchases. Please try again.');
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
            if (!service.isSupported)
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
