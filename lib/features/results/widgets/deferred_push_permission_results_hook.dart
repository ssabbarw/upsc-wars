import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/services/deferred_push_permission_coordinator.dart';

/// Side-effect widget: schedules the deferred notification education sheet once
/// results have loaded and the user has completed at least one session.
class DeferredPushPermissionResultsHook extends ConsumerStatefulWidget {
  const DeferredPushPermissionResultsHook({super.key});

  @override
  ConsumerState<DeferredPushPermissionResultsHook> createState() =>
      _DeferredPushPermissionResultsHookState();
}

class _DeferredPushPermissionResultsHookState
    extends ConsumerState<DeferredPushPermissionResultsHook> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        DeferredPushPermissionCoordinator.onResultsScreenMounted(context, ref),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
