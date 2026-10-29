import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the catalog explanation + example for a content trap.
class TrapInfoButton extends StatelessWidget {
  const TrapInfoButton({super.key, required this.trapType, this.tooltip});

  final String trapType;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: () =>
          context.push('/weak-areas/trap/${Uri.encodeComponent(trapType)}'),
      icon: Icon(
        Icons.info_outline_rounded,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
  }
}
