import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/daily_revision_choice_sheet.dart';
import '../../../l10n/l10n.dart';

/// Notification / cold-start entry that lands on the revision queue.
class DailyDrillLaunchScreen extends ConsumerStatefulWidget {
  const DailyDrillLaunchScreen({super.key});

  @override
  ConsumerState<DailyDrillLaunchScreen> createState() =>
      _DailyDrillLaunchScreenState();
}

class _DailyDrillLaunchScreenState
    extends ConsumerState<DailyDrillLaunchScreen> {
  bool _started = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
  }

  Future<void> _launch() async {
    try {
      await showDailyRevisionChoiceSheet(
        context: context,
        ref: ref,
        source: 'daily_practice_reminder',
      );
      if (!mounted) return;
      if (context.mounted) context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.ddOpenFailed,
                  style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: Text(context.l10n.mpGoHome),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
