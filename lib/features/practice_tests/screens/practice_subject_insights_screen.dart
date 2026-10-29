import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../providers/practice_catalog_provider.dart';
import '../widgets/practice_insights_view.dart';

/// Overall performance plus confident-mistake traps and topics.
class PracticeSubjectInsightsScreen extends ConsumerWidget {
  const PracticeSubjectInsightsScreen({
    super.key,
    required this.subject,
    this.topic,
  });

  final String subject;
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final catalog = ref.watch(practiceCatalogProvider);
    final displayName = topic == null
        ? (SubjectConstants.bySlug(subject)?.displayName ?? subject)
        : (catalog.asData?.value.topicDisplayNames[topic] ?? topic!);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.l10n.practiceInsightsTitle(displayName)),
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: AppColors.transparent,
      ),
      body: PracticeSubjectInsightsView(subject: subject, topic: topic),
    );
  }
}
