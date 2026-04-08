import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme/app_text_styles.dart';

class QuestionBankLoadingScreen extends HookConsumerWidget {
  const QuestionBankLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: Center(
        child: Text(
          'Setting up your question bank...',
          textAlign: TextAlign.center,
          style: AppTextStyles.body().copyWith(color: onSurface),
        ),
      ),
    );
  }
}
