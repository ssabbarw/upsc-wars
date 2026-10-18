import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'revenuecat_config.dart';

enum PurchaseOutcomeKind { purchased, cancelled, pending, unavailable, failed }

class PurchaseOutcome {
  const PurchaseOutcome(this.kind, {this.message, this.ownedIds});

  final PurchaseOutcomeKind kind;
  final String? message;

  /// Entitlement ids active after a successful purchase/restore attempt.
  final Set<String>? ownedIds;

  bool get isPurchased => kind == PurchaseOutcomeKind.purchased;
}

/// Thin wrapper around RevenueCat for the one-time "series pass" products.
///
/// A series is unlocked by an entitlement whose id equals the series id
/// (for example `prelims_2027`). The pass is a non-consumable, so the
/// entitlement never expires.
class TestSeriesPurchaseService {
  TestSeriesPurchaseService();

  static const _logName = 'TestSeriesPurchase';

  bool _configured = false;
  String? _loggedInUid;
  final _ownedController = StreamController<Set<String>>.broadcast();

  /// Android-only for now (see plan); also requires the SDK key.
  bool get isSupported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      RevenueCatConfig.isConfigured;

  /// Emits the owned series ids whenever RevenueCat reports a change.
  Stream<Set<String>> get ownedChanges => _ownedController.stream;

  void _log(String m) => developer.log(m, name: _logName);

  Set<String> _owned(CustomerInfo info) =>
      info.entitlements.active.keys.toSet();

  void _logCustomerInfo(String label, CustomerInfo info) {
    final active = info.entitlements.active.keys.toList()..sort();
    final all = info.entitlements.all.keys.toList()..sort();
    final products = info.allPurchasedProductIdentifiers.toList()..sort();
    _log(
      '$label active=$active allEntitlements=$all '
      'purchasedProducts=$products',
    );
  }

  /// Configures the SDK once and keeps the RevenueCat user in sync with
  /// [accountUid] (null = signed out / anonymous).
  Future<void> sync({required String? accountUid}) async {
    if (!isSupported) return;
    try {
      if (!_configured) {
        await Purchases.setLogLevel(
          kDebugMode ? LogLevel.debug : LogLevel.warn,
        );
        final config = PurchasesConfiguration(RevenueCatConfig.androidApiKey)
          ..appUserID = accountUid;
        await Purchases.configure(config);
        _configured = true;
        _loggedInUid = accountUid;
        Purchases.addCustomerInfoUpdateListener((info) {
          if (!_ownedController.isClosed) _ownedController.add(_owned(info));
        });
        return;
      }
      if (accountUid != null && accountUid != _loggedInUid) {
        await Purchases.logIn(accountUid);
        _loggedInUid = accountUid;
      } else if (accountUid == null && _loggedInUid != null) {
        await Purchases.logOut();
        _loggedInUid = null;
      }
    } on Object catch (e, st) {
      developer.log(
        'RevenueCat sync failed: $e',
        name: _logName,
        stackTrace: st,
      );
    }
  }

  /// Series ids the current RevenueCat user owns. Empty if unsupported/offline.
  Future<Set<String>> ownedSeriesIds() async {
    if (!isSupported || !_configured) return const {};
    try {
      return _owned(await Purchases.getCustomerInfo());
    } on Object catch (e) {
      _log('getCustomerInfo failed: $e');
      rethrow;
    }
  }

  /// Store listing for the one-time product (price comes from Google Play).
  Future<StoreProduct?> loadProduct(String productId) async {
    if (!isSupported || !_configured) return null;
    final products = await Purchases.getProducts([
      productId,
    ], productCategory: ProductCategory.nonSubscription);
    for (final p in products) {
      if (p.identifier == productId || p.identifier.startsWith('$productId:')) {
        return p;
      }
    }
    return products.isEmpty ? null : products.first;
  }

  Future<PurchaseOutcome> buy(StoreProduct product) async {
    if (!isSupported || !_configured) {
      return const PurchaseOutcome(PurchaseOutcomeKind.unavailable);
    }
    try {
      _log('buying product=${product.identifier}');
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      );
      _logCustomerInfo('after purchase', result.customerInfo);
      final owned = _owned(result.customerInfo);
      _ownedController.add(owned);
      return PurchaseOutcome(PurchaseOutcomeKind.purchased, ownedIds: owned);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      switch (code) {
        case PurchasesErrorCode.purchaseCancelledError:
          return const PurchaseOutcome(PurchaseOutcomeKind.cancelled);
        case PurchasesErrorCode.paymentPendingError:
          return const PurchaseOutcome(
            PurchaseOutcomeKind.pending,
            message:
                'Your payment is pending. The series unlocks once it completes.',
          );
        case PurchasesErrorCode.productAlreadyPurchasedError:
          // Already owned: refresh entitlements so the UI unlocks.
          try {
            final info = await Purchases.restorePurchases();
            _logCustomerInfo('after already-purchased restore', info);
            final owned = _owned(info);
            _ownedController.add(owned);
            return PurchaseOutcome(
              PurchaseOutcomeKind.purchased,
              ownedIds: owned,
            );
          } on Object catch (_) {
            return const PurchaseOutcome(PurchaseOutcomeKind.purchased);
          }
        default:
          _log('purchase failed: $code ${e.message}');
          return PurchaseOutcome(
            PurchaseOutcomeKind.failed,
            message: e.message ?? 'The purchase could not be completed.',
          );
      }
    } on Object catch (e) {
      _log('purchase failed: $e');
      return PurchaseOutcome(PurchaseOutcomeKind.failed, message: e.toString());
    }
  }

  /// Restores previous purchases from the store account. Returns owned ids.
  Future<Set<String>> restore() async {
    if (!isSupported || !_configured) return const {};
    final info = await Purchases.restorePurchases();
    _logCustomerInfo('after restore', info);
    final owned = _owned(info);
    _ownedController.add(owned);
    return owned;
  }

  void dispose() {
    _ownedController.close();
  }
}
