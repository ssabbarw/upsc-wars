import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/create_get_started_session_use_case.dart';

Future<void> showGetStartedSubjectSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _GetStartedSubjectSheet(),
  );
}

/// Temporary onboarding invitation — hidden after first diagnosis (State B).
class GetStartedCard extends HookConsumerWidget {
  const GetStartedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loading = useState(false);
    final loggedShown = useRef(false);

    useEffect(() {
      if (loggedShown.value) return null;
      loggedShown.value = true;
      unawaited(Analytics.track(ref, const GetStartedCardShownEvent()));
      return null;
    }, const []);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.lg),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDeep.withValues(alpha: 0.18)
                    : AppColors.primaryLight.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quick experiment · ~7 min',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'UPSC Wars gives you an edge',
                    style: AppTextStyles.h3().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Most know their weak topics. Few know where they\u2019re '
                    'confidently wrong.',
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: loading.value
                          ? null
                          : () async {
                              await showGetStartedSubjectSheet(context);
                            },
                      icon: loading.value
                          ? null
                          : const Icon(Icons.explore_outlined, size: 18),
                      label: loading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Discover Your Blind Spots'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedSubjectSheet extends ConsumerWidget {
  const _GetStartedSubjectSheet();

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    String subject,
  ) async {
    Navigator.pop(context);
    unawaited(
      Analytics.track(
        ref,
        GetStartedCardTappedEvent(subject: subject),
      ),
    );
    try {
      final uc = await ref.read(createGetStartedSessionUseCaseProvider.future);
      final id = await uc.execute(subject: subject);
      if (context.mounted) context.push('/test/$id');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: sheetBottomPadding(context)),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Where should we look first?',
              style: AppTextStyles.h3().copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Any subject works — mark how sure you feel after each answer.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
              title: const Text('Surprise me'),
              subtitle: Text(
                'We\u2019ll pick for you',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
              onTap: () => _start(
                context,
                ref,
                CreateGetStartedSessionUseCase.defaultSubject,
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.38,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: SubjectConstants.ordered.map((s) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        s.materialIcon,
                        color: AppColors.primaryDark,
                        size: 22,
                      ),
                      title: Text(s.displayName),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onTap: () => _start(context, ref, s.slug),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
