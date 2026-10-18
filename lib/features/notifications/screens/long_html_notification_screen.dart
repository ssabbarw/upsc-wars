import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../long_html_document.dart';
import '../long_html_notification_constants.dart';
import '../../../l10n/l10n.dart';

/// Full-screen announcement loaded from Firestore
/// `Long_Html_Message` / `message` field `message` (HTML).
///
/// Mobile uses a WebView so a full HTML page (CSS, viewport, tables) renders
/// as authored. Web falls back to [HtmlWidget] with the document chrome stripped.
class LongHtmlNotificationScreen extends StatelessWidget {
  const LongHtmlNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.notifScreenTitle, style: AppTextStyles.h3()),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection(LongHtmlNotificationConstants.collection)
            .doc(LongHtmlNotificationConstants.documentId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                context.l10n.notifLoadFailed(snapshot.error.toString()),
                style: AppTextStyles.bodyMd().copyWith(color: scheme.error),
              ),
            );
          }
          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                context.l10n.notifNoAnnouncement,
                style: AppTextStyles.bodyMd(),
              ),
            );
          }
          final data = doc.data();
          final raw = data?[LongHtmlNotificationConstants.fieldMessage];
          final html = raw is String ? raw.trim() : '';
          if (html.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                context.l10n.notifEmptyAnnouncement,
                style: AppTextStyles.bodyMd(),
              ),
            );
          }
          if (kIsWeb) {
            return _HtmlWidgetView(html: html, scheme: scheme);
          }
          return _HtmlWebView(html: html, background: scheme.surface);
        },
      ),
    );
  }
}

class _HtmlWebView extends StatefulWidget {
  const _HtmlWebView({required this.html, required this.background});

  final String html;
  final Color background;

  @override
  State<_HtmlWebView> createState() => _HtmlWebViewState();
}

class _HtmlWebViewState extends State<_HtmlWebView> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    final page = LongHtmlDocument.forWebView(
      widget.html,
      backgroundCss: _cssHex(widget.background),
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(widget.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (_isDocumentLoad(request.url)) {
              return NavigationDecision.navigate;
            }
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https')) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(page);
  }

  static bool _isDocumentLoad(String url) {
    return url == 'about:blank' ||
        url.startsWith('about:srcdoc') ||
        url.startsWith('data:');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _HtmlWidgetView extends StatelessWidget {
  const _HtmlWidgetView({required this.html, required this.scheme});

  final String html;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: HtmlWidget(
        LongHtmlDocument.forHtmlWidget(html),
        textStyle: AppTextStyles.bodyMd().copyWith(color: scheme.onSurface),
        customStylesBuilder: (element) {
          if (element.localName == 'title' || element.localName == 'head') {
            return {'display': 'none'};
          }
          return null;
        },
        onTapUrl: (url) async {
          if (url.isEmpty) return false;
          final uri = Uri.tryParse(url);
          if (uri == null) return false;
          return launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

String _cssHex(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
}
