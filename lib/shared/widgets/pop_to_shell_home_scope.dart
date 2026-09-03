import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// Inner-tab back handler for the **visible** shell branch.
///
/// [RootBackButtonDispatcher] only invokes the last registered callback, so the
/// shell owns the single [BackButtonListener]. Branch widgets attach here when
/// they are on-screen ([TickerMode] is on) rather than competing for the press.
class ShellInnerBackRegistry {
  ShellInnerBackRegistry._();

  static Object? _owner;
  static bool Function()? _handler;

  static void attach(Object owner, bool Function()? handler) {
    _owner = owner;
    _handler = handler;
  }

  static void detach(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    _handler = null;
  }

  /// True if the visible branch consumed back (e.g. QOTD → Recent online).
  static bool handle() => _handler?.call() ?? false;
}

/// On History / Progress / Community, system back switches to the Home tab.
///
/// Does **not** listen for the back button itself. [_AppShell] does that once
/// above the [IndexedStack], then asks [ShellInnerBackRegistry] whether this
/// branch wants the press. A listener here would lose to the shell's, because
/// the dispatcher only calls the most recently registered callback — and the
/// shell rebuilds more often than a tab.
///
/// [TickerMode] decides whether this branch is the visible one, so an
/// off-stage [IndexedStack] child does not steal the registry.
///
/// [PopScope] still blocks a route pop of this branch (sheets use the root
/// navigator and are ignored here).
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

  bool _rootHasOverlayRoute() {
    final rootNav = Navigator.maybeOf(context, rootNavigator: true);
    return rootNav != null && rootNav.canPop();
  }

  void _syncRegistry() {
    if (!mounted) return;
    if (TickerMode.valuesOf(context).enabled) {
      ShellInnerBackRegistry.attach(this, widget.onInnerBack);
    } else {
      ShellInnerBackRegistry.detach(this);
    }
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    if (_rootHasOverlayRoute()) return;
    if (_alreadyHandledThisFrame()) return;
    if (widget.onInnerBack?.call() ?? false) return;
    // Inside a shell tab, modal/sheet pops are delivered here because [canPop]
    // is false. Switching to Home would hide any follow-up push (battle invite).
    // System back still reaches Home via the shell [BackButtonListener].
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) return;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRegistry();
  }

  @override
  void didUpdateWidget(covariant PopToShellHomeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRegistry();
  }

  @override
  void dispose() {
    ShellInnerBackRegistry.detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: widget.child,
    );
  }
}
