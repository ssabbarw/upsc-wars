import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// On History / Progress / Community, system back switches to the Home tab.
///
/// Uses [PopScope] for route-level pops and [BackButtonListener] so Android /
/// router back reliably reaches the shell (some shells only deliver one path).
/// [TickerMode] guards inactive [IndexedStack] branches from handling back.
///
/// When [onInnerBack] returns true (e.g. inner tab → default tab), Home is not
/// selected. Same-frame duplicate callbacks from both listeners are ignored.
class PopToShellHomeScope extends StatefulWidget {
  const PopToShellHomeScope({
    super.key,
    required this.child,
    this.onInnerBack,
  });

  final Widget child;

  /// Return true if back was handled without leaving this shell tab.
  final bool Function()? onInnerBack;

  @override
  State<PopToShellHomeScope> createState() => _PopToShellHomeScopeState();
}

class _PopToShellHomeScopeState extends State<PopToShellHomeScope> {
  Duration? _handledFrameTime;

  bool _alreadyHandledThisFrame() {
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    if (_handledFrameTime == now) return true;
    _handledFrameTime = now;
    return false;
  }

  Future<bool> _onBackButtonPressed() async {
    if (!TickerMode.valuesOf(context).enabled) return false;
    if (_alreadyHandledThisFrame()) return true;
    if (widget.onInnerBack?.call() ?? false) return true;
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null && shell.currentIndex != 0) {
      shell.goBranch(0, initialLocation: false);
      return true;
    }
    return false;
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    if (_alreadyHandledThisFrame()) return;
    if (widget.onInnerBack?.call() ?? false) return;
    _goHome();
  }

  void _goHome() {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null && shell.currentIndex != 0) {
      shell.goBranch(0, initialLocation: false);
    } else if (shell == null && context.mounted) {
      GoRouter.of(context).go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: _onBackButtonPressed,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
        child: widget.child,
      ),
    );
  }
}
