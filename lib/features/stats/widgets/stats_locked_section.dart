import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/l10n.dart';
import '../providers/stats_access_provider.dart';

/// Paid sections of Stats. While [statsAccessProvider] is [StatsAccess.full]
/// this is a pass-through. [paid] marks the section that a future paywall
/// locks; free sections pass `paid: false`.
class StatsLockedSection extends ConsumerWidget {
  const StatsLockedSection({super.key, required this.child, this.paid = true});

  final Widget child;
  final bool paid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(statsAccessProvider);
    if (!paid || access == StatsAccess.full) return child;
    return Stack(
      children: [
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: child,
          ),
        ),
        Positioned.fill(
          child: Center(
            child: FilledButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(ctx.l10n.statsUnlock),
                  ),
                );
              },
              child: Text(context.l10n.statsUnlock),
            ),
          ),
        ),
      ],
    );
  }
}
