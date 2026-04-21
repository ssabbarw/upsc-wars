import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/constants/app_constants.dart';

/// User closed the OAuth sheet or cancelled the Instagram prompt.
class InstagramLinkCancelled implements Exception {
  const InstagramLinkCancelled();
}

/// Non-auth failure (config, OAuth error param, missing code, etc.).
class InstagramLinkFailed implements Exception {
  InstagramLinkFailed(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Instagram API with Instagram Login — OAuth in browser, then
/// [completeInstagramLink] / [unlinkInstagram] callables on the server.
abstract final class InstagramLinkService {
  InstagramLinkService._();

  /// Must match the Instagram product configuration in Meta Developer Console.
  static const String _scope = 'instagram_business_basic';

  static Future<String> connectInstagramAccount() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Instagram linking requires the mobile app.',
      );
    }

    final appId = AppConstants.instagramOAuthAppId.trim();
    if (appId.isEmpty) {
      throw InstagramLinkFailed(
        'Instagram is not configured in this build.',
      );
    }

    final redirect = AppConstants.instagramOAuthRedirectUri.trim();
    final authUri = Uri.https('www.instagram.com', '/oauth/authorize', {
      'client_id': appId,
      'redirect_uri': redirect,
      'scope': _scope,
      'response_type': 'code',
    });

    final String resultUrl;
    try {
      resultUrl = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: 'upscwars',
      );
    } on PlatformException catch (e) {
      final code = e.code.toUpperCase();
      if (code == 'CANCELED' || code.contains('CANCEL')) {
        throw const InstagramLinkCancelled();
      }
      throw InstagramLinkFailed(e.message ?? e.code);
    }

    final parsed = Uri.parse(resultUrl);
    final oauthError = parsed.queryParameters['error'];
    final oauthDesc = parsed.queryParameters['error_description'];
    if (oauthError != null) {
      final msg = oauthDesc?.replaceAll('+', ' ') ?? oauthError;
      throw InstagramLinkFailed(msg);
    }

    var code = parsed.queryParameters['code']?.trim() ?? '';
    if (code.isEmpty && parsed.fragment.isNotEmpty) {
      final frag = Uri.splitQueryString(parsed.fragment);
      code = frag['code']?.trim() ?? '';
    }
    if (code.isEmpty) {
      throw InstagramLinkFailed(
        'Instagram did not return an authorization code.',
      );
    }

    final callable = FirebaseFunctions.instance.httpsCallable(
      'completeInstagramLink',
    );
    final result = await callable.call<Map<String, dynamic>>({'code': code});
    final data = result.data;
    final username = data['username'] as String?;
    if (username == null || username.isEmpty) {
      throw InstagramLinkFailed(
        'Linked, but username was missing. Try again.',
      );
    }
    return username;
  }

  static Future<void> unlinkInstagramAccount() async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'unlinkInstagram',
    );
    await callable.call();
  }
}
