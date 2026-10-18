import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../providers/prefs_provider.dart';

/// Handles "rate/review" actions and enforces one-time prompting policy.
final appReviewServiceProvider = Provider<AppReviewService>((ref) {
  return AppReviewService(ref);
});

final class AppReviewService {
  AppReviewService(this._ref);

  final Ref _ref;

  static const _iosAppStoreId = '1550273627';

  Future<void> requestReviewOnce() async {
    final p = await _ref.read(prefsServiceProvider.future);
    if (p.appReviewPromptShown) return;

    // Mark it immediately to satisfy "only once ever" even if the platform
    // dialog fails to show (some devices/OS versions silently no-op).
    p.appReviewPromptShown = true;
    _ref.invalidate(prefsServiceProvider);

    final inApp = InAppReview.instance;
    try {
      final available = await inApp.isAvailable();
      if (available) {
        await inApp.requestReview();
        return;
      }
    } catch (_) {
      // fall through to store listing
    }

    await openStoreListing();
  }

  Future<void> openStoreListing() async {
    // Prefer in_app_review store listing when possible.
    final inApp = InAppReview.instance;
    try {
      await inApp.openStoreListing(
        appStoreId: _iosAppStoreId,
        microsoftStoreId: null,
      );
      return;
    } catch (_) {
      // fall back to external URL
    }

    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? AppConstants.appStoreUrl
        : AppConstants.playStoreUrl;
    final uri = Uri.parse(url);
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }
}
