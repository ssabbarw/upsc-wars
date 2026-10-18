import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/shimmer_box.dart';

/// Test-engine skeleton: top bar + stem + four option rows.
class TestEngineQuestionShimmer extends StatelessWidget {
  const TestEngineQuestionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 40, height: 40, borderRadius: AppRadius.md),
                  const SizedBox(width: AppSpacing.sm),
                  const ShimmerBox(width: 88, height: 16),
                  const Spacer(),
                  ShimmerBox(width: 72, height: 28, borderRadius: AppRadius.sm),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ShimmerBox(width: w, height: 18),
              const SizedBox(height: AppSpacing.sm),
              ShimmerBox(width: w * 0.92, height: 18),
              const SizedBox(height: AppSpacing.sm),
              ShimmerBox(width: w * 0.64, height: 18),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                ShimmerBox(width: w, height: 52, borderRadius: AppRadius.md),
              ],
            ],
          ),
        );
      },
    );
  }
}
