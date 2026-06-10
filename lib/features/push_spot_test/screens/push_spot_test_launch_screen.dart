import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../push_spot_test_launch_params.dart';
import '../push_spot_test_launcher.dart';

/// Cold-start / notification entry: reads launch params from the route query
/// and starts the 1-question spot test.
class PushSpotTestLaunchScreen extends ConsumerStatefulWidget {
  const PushSpotTestLaunchScreen({super.key, required this.params});

  final PushSpotTestLaunchParams params;

  @override
  ConsumerState<PushSpotTestLaunchScreen> createState() =>
      _PushSpotTestLaunchScreenState();
}

class _PushSpotTestLaunchScreenState
    extends ConsumerState<PushSpotTestLaunchScreen> {
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
    final err = widget.params.validationError;
    if (err != null) {
      if (!mounted) return;
      setState(() => _error = err);
      return;
    }
    try {
      await launchPushSpotTest(
        context: context,
        ref: ref,
        subject: widget.params.subject,
        topic: widget.params.topic,
        subTopic: widget.params.subTopic,
        questionUuid: widget.params.trimmedQuestionUuid,
      );
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Could not start quick test',
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
                  child: const Text('Go home'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
