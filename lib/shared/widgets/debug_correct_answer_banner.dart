import 'package:flutter/material.dart';

import '../../core/domain/entities/test_question.dart';

class DebugCorrectAnswerBanner extends StatelessWidget {
  const DebugCorrectAnswerBanner({super.key, required this.question});

  final TestQuestion question;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
