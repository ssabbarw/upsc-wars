import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/layout/system_insets.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/create_get_started_session_use_case.dart';

/// Creates the 7-question mixed Get Started diagnostic (returns session id or null).
Future<String?> createGetStartedDiagnosticSession(
  WidgetRef ref, {
  String source = 'home_card',
}) async {
  unawaited(
    Analytics.track(
      ref,
      GetStartedCardTappedEvent(
        subject: CreateGetStartedSessionUseCase.mixedSubject,
        source: source,
      ),
    ),
  );
  try {
    final uc = await ref.read(createGetStartedSessionUseCaseProvider.future);
    return await uc.executeMixed();
  } on Object {
    return null;
  }
}

/// Navigates into the Get Started diagnostic test. Returns false on failure.
Future<bool> launchGetStartedDiagnostic(
  BuildContext context,
  WidgetRef ref, {
  String source = 'home_card',
  bool replaceRoute = false,
}) async {
  final sessionId = await createGetStartedDiagnosticSession(
    ref,
    source: source,
  );
  if (!context.mounted) return false;
  if (sessionId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Something went wrong. Please try again.')),
    );
    return false;
  }
  if (replaceRoute) {
    context.go('/test/$sessionId');
  } else {
    context.push('/test/$sessionId');
  }
  return true;
}

/// What to expect before the first mixed-subject diagnostic.
///
/// Returns `true` if the user started the diagnostic; `false` or `null` if dismissed.
Future<bool?> showGetStartedDiagnosticIntroSheet(
  BuildContext context, {
  bool postOnboarding = false,
}) async {
  final started = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context, rootNavigator: true),
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 280),
    ),
    builder: (ctx) => _AnimatedSheetEntrance(
      child: _GetStartedDiagnosticIntroSheet(postOnboarding: postOnboarding),
    ),
  );
  if (started != true) {
    await BattleMessagingService.requestPushAuthorizationIfNotDetermined();
  }
  return started;
}

/// Temporary onboarding invitation — hidden after first diagnosis (State B).
class GetStartedCard extends HookConsumerWidget {
  const GetStartedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    '5 min · 7 MCQs',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Find where UPSC Wars gives you an edge',
                    style: AppTextStyles.h3().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Most aspirants know weak topics. Few know where they\u2019re '
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
                      onPressed: () => unawaited(
                        showGetStartedDiagnosticIntroSheet(context),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Let\u2019s go'),
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

class _GetStartedDiagnosticIntroSheet extends HookConsumerWidget {
  const _GetStartedDiagnosticIntroSheet({this.postOnboarding = false});

  final bool postOnboarding;

  String get _analyticsSource =>
      postOnboarding ? 'post_onboarding' : 'intro_sheet';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loading = useState(false);
    final loggedOnboardingComplete = useRef(false);

    useEffect(() {
      if (!postOnboarding || loggedOnboardingComplete.value) return null;
      loggedOnboardingComplete.value = true;
      unawaited(
        logActivationMilestoneOnce(
          ref,
          ActivationMilestones.onboardingComplete,
        ),
      );
      return null;
    }, const []);

    final bottom = MediaQuery.paddingOf(context).bottom;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final headerTop = Color.lerp(
      isDark ? AppColors.primaryDeep : AppColors.primaryLight,
      scheme.surface,
      isDark ? 0.25 : 0.15,
    )!;

    Future<void> start() async {
      if (loading.value) return;
      loading.value = true;
      final sessionId = await createGetStartedDiagnosticSession(
        ref,
        source: _analyticsSource,
      );
      if (!context.mounted) return;
      if (sessionId == null) {
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
        return;
      }
      Navigator.pop(context, true);
      context.push('/test/$sessionId');
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        bottom + AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Material(
            color: scheme.surface,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray900.withValues(
                      alpha: isDark ? 0.45 : 0.1,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [headerTop, scheme.surface],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          '5-MIN DIAGNOSTIC',
                          style: AppTextStyles.caption().copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Find where UPSC Wars gives you an edge',
                          style: AppTextStyles.h2().copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Take this demo test — answers aren\u2019t saved and '
                          'won\u2019t affect your performance insights.',
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      children: const [
                        _DiagnosticExpectationRow(
                          icon: Icons.timer_outlined,
                          title: '7 MCQs · 5 minutes',
                          subtitle:
                              'Mixed Prelims-style questions — jump in straight away.',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _DiagnosticExpectationRow(
                          icon: Icons.psychology_outlined,
                          title: 'Mark your confidence',
                          subtitle:
                              'Sure, educated guess, or unsure — we spot what '
                              'feels right but isn\u2019t.',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _DiagnosticExpectationRow(
                          icon: Icons.insights_outlined,
                          title: 'Rich insights when you finish',
                          subtitle:
                              'Confident mistakes, trap patterns, and what to '
                              'revise next.',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _DiagnosticExpectationRow(
                          icon: Icons.menu_book_outlined,
                          title: 'Explanations that actually teach',
                          subtitle:
                              'Traps, elimination, statement analysis — not just '
                              'right or wrong.',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.infoBgDark
                            : AppColors.infoBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.infoTextDark
                                : AppColors.infoText,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All questions are available in Hindi too.',
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'सभी प्रश्न हिंदी में भी उपलब्ध हैं।',
                                  style: AppTextStyles.bodySm().copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      sheetBottomPadding(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: loading.value ? null : () => start(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                            ),
                            child: loading.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : Text(
                                    'Let\u2019s go',
                                    style: AppTextStyles.label().copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        if (postOnboarding) ...[
                          const SizedBox(height: AppSpacing.xs),
                          TextButton(
                            onPressed: loading.value
                                ? null
                                : () => Navigator.pop(context, false),
                            child: Text(
                              'Do it later',
                              style: AppTextStyles.labelSm().copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Staggered fade + slide for sheet content after the modal route animates in.
class _AnimatedSheetEntrance extends HookWidget {
  const _AnimatedSheetEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 380),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);
    final fade = Tween<double>(begin: 0, end: 1).animate(curve);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 60), controller.forward);
      return timer.cancel;
    }, [controller]);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _DiagnosticExpectationRow extends StatelessWidget {
  const _DiagnosticExpectationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryDeep.withValues(alpha: 0.35)
                : AppColors.primaryLight.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 22, color: AppColors.primaryDark),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
