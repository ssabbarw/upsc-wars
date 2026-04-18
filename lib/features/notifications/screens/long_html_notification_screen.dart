import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../long_html_notification_constants.dart';

/// Full-screen announcement loaded from Firestore
/// `Long_Html_Message` / `message` field `message` (HTML).
class LongHtmlNotificationScreen extends StatelessWidget {
  const LongHtmlNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification', style: AppTextStyles.h3()),
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
                'Could not load message.\n${snapshot.error}',
                style: AppTextStyles.bodyMd().copyWith(color: scheme.error),
              ),
            );
          }
          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No announcement is available right now.',
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
                'This announcement is empty.',
                style: AppTextStyles.bodyMd(),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: HtmlWidget(
              html,
              textStyle: AppTextStyles.bodyMd().copyWith(
                color: scheme.onSurface,
              ),
              onTapUrl: (url) async {
                if (url.isEmpty) return false;
                final uri = Uri.tryParse(url);
                if (uri == null) return false;
                return launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          );
        },
      ),
    );
  }
}
