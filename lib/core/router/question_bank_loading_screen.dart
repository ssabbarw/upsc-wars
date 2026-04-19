import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QuestionBankLoadingScreen extends HookConsumerWidget {
  const QuestionBankLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.correctTextDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome,\nPlease wait while we set up everything',
              textAlign: TextAlign.center,
              style: AppTextStyles.body().copyWith(
                color: AppColors.correctTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
