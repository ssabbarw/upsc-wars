import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// On History / Progress / Community, system back switches to the Home tab.
///
/// Uses [PopScope] for route-level pops and [BackButtonListener] so Android /
/// router back reliably reaches the shell (some shells only deliver one path).
/// [TickerMode] guards inactive [IndexedStack] branches from handling back.
class PopToShellHomeScope extends StatelessWidget {
  const PopToShellHomeScope({super.key, required this.child});

  final Widget child;

  Future<bool> _onBackButtonPressed(BuildContext context) async {
    if (!TickerMode.valuesOf(context).enabled) return false;
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null && shell.currentIndex != 0) {
      shell.goBranch(0, initialLocation: false);
      return true;
    }
    return false;
  }

  void _goHome(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return;
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell != null) {
      shell.goBranch(0, initialLocation: false);
    } else if (context.mounted) {
      GoRouter.of(context).go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () => _onBackButtonPressed(context),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _goHome(context);
        },
        child: child,
      ),
    );
  }
}
