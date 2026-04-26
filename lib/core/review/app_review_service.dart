import 'dart:io';

import 'package:in_app_review/in_app_review.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../providers/prefs_provider.dart';

final appReviewServiceProvider = Provider<AppReviewService>((ref) {
  return AppReviewService(ref);
});

final class AppReviewService {
  AppReviewService(this._ref);

  final Ref _ref;

  /// Fire-and-forget: opens the store listing (explicit user intent).
  Future<void> openStoreListing() async {
    final url = Platform.isIOS ? AppConstants.appStoreUrl : AppConstants.playStoreUrl;
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// One-time-only: tries the native in-app review flow; if unavailable, falls
  /// back to opening the store listing. Once invoked successfully (shown or
  /// attempted), it is never asked again.
  Future<void> maybeRequestReviewOnce() async {
    final prefs = await _ref.read(prefsServiceProvider.future);
    if (prefs.appReviewPromptShown) return;

    prefs.appReviewPromptShown = true;
    _ref.invalidate(prefsServiceProvider);

    final review = InAppReview.instance;
    try {
      final available = await review.isAvailable();
      if (available) {
        await review.requestReview();
        return;
      }
    } catch (_) {
      // Non-blocking; fall back to store listing.
    }
    await openStoreListing();
  }
}

