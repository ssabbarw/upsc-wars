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
import '../../../l10n/l10n.dart';

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
    final productAsync = ref.watch(
      seriesProductProvider(bundle.info.productId),
    );
    final busy = useState(false);
    final canSell = ref.watch(testSeriesCanSellProvider).asData?.value ?? false;
    final access = ref.watch(testSeriesAccessServiceProvider);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> buy() async {
      if (busy.value) return;
      busy.value = true;
      try {
        final signedIn = await ensureAccountSignedIn(
          context: context,
          ref: ref,
          reason: appL10n.tsSignInPurchase,
        );
        if (!signedIn || !context.mounted) return;

        await service.sync(accountUid: FirebaseAuth.instance.currentUser?.uid);
        final product =
            productAsync.asData?.value ??
            await service.loadProduct(bundle.info.productId);
        if (product == null) {
          toast(appL10n.tsPassUnavailable);
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
              toast(appL10n.tsUnlockedAll);
              Navigator.of(context).pop(true);
            } else {
              toast(
                appL10n.tsPaidNoAccess(
                  bundle.info.entitlementId,
                  bundle.info.productId,
                ),
              );
            }
          case PurchaseOutcomeKind.cancelled:
            break;
          case PurchaseOutcomeKind.pending:
            toast(outcome.message ?? appL10n.tsPaymentPending);
          case PurchaseOutcomeKind.unavailable:
            toast(appL10n.tsPurchasesUnavailable);
          case PurchaseOutcomeKind.failed:
            toast(outcome.message ?? appL10n.tsPurchaseFail);
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
          final message = outcome.message ?? appL10n.tsCodeNotApplied;
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
                ? appL10n.tsAlreadyHaveAccess
                : appL10n.tsUnlockedAll,
          );
          Navigator.of(context).pop(true);
        } else {
          toast(appL10n.tsAccessNotLoaded);
        }
      } on Object {
        toast(appL10n.commonTryAgainError);
      } finally {
        busy.value = false;
      }
    }

    Future<void> applyTypedCode() async {
      final code = codeCtrl.text.trim();
      if (code.isEmpty) {
        codeError.value = appL10n.tsEnterCode;
        return;
      }
      await redeem(code, signInReason: appL10n.tsSignInAccess);
    }

    Future<void> restore() async {
      if (busy.value) return;
      busy.value = true;
      restoreNote.value = null;
      try {
        final signedIn = await ensureAccountSignedIn(
          context: context,
          ref: ref,
          reason: appL10n.tsSignInBefore,
        );
        if (!signedIn || !context.mounted) return;
        await service.sync(accountUid: FirebaseAuth.instance.currentUser?.uid);
        final owned = await ref.read(ownedSeriesIdsProvider.notifier).restore();
        if (!context.mounted) return;
        if (unlocks(owned)) {
          toast(appL10n.tsAccessRestored);
          Navigator.of(context).pop(true);
        } else {
          restoreNote.value = canSell
              ? appL10n.tsNothingFoundUnlock
              : appL10n.tsNothingFound;
        }
      } on Object {
        toast(appL10n.tsRestoreFail);
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
              context.l10n.tsPayOnce,
              style: AppTextStyles.bodyMd().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Bullet(context.l10n.tsPwSubject(staticCount)),
            _Bullet(context.l10n.tsPwCa(ca)),
            _Bullet(context.l10n.tsPwMocks(mocks)),
            _Bullet(context.l10n.tsPwBilingual),
            _Bullet(context.l10n.tsPwDash),
            if (free > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.tsPwFree(free),
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (restoreNote.value != null) ...[
              _Notice(restoreNote.value!, color: scheme.onSurface),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!service.isSupported)
              _Notice(
                context.l10n.tsPwNoPurchases,
                color: scheme.onSurfaceVariant,
              )
            else if (!canSell)
              _Notice(
                context.l10n.tsPwNotOnSale,
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
                        price == null
                            ? context.l10n.tsUnlockAll
                            : context.l10n.tsUnlockAllPrice(price),
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
                          labelText: context.l10n.tsDiscountCode,
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
                        child: Text(context.l10n.tsApply),
                      ),
                    ),
                  ],
                ),
              )
            else
              TextButton(
                onPressed: busy.value ? null : () => showCodeField.value = true,
                child: Text(context.l10n.tsHaveCode),
              ),
            TextButton(
              onPressed: busy.value ? null : () => unawaited(restore()),
              child: Text(context.l10n.tsRestorePurchase),
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
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.primary,
            ),
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
