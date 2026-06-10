import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Android-style notification tray preview (title + body).
class PushNotificationPreviewCard extends StatelessWidget {
  const PushNotificationPreviewCard({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final displayTitle = title.trim().isEmpty ? 'Notification title' : title;
    final displayBody = body.trim().isEmpty
        ? 'Notification body will appear here.'
        : body;

    return Material(
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(22),
      color: const Color(0xFF26211C),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, Color.lerp(primary, Colors.black, 0.22)!],
                ),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appDisplayName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayBody,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
