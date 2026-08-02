import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../data/onboarding_fact_or_bluff_data.dart';

double _onbScale(BuildContext context) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  return (shortest / 390).clamp(0.78, 1.22);
}

double _onb(BuildContext context, double designPx) =>
    designPx * _onbScale(context);

/// Onboarding demo: three untimed fact-or-bluff statements (not the full
/// game — no countdown, no streak, no language toggle). Designed to let the
/// user *feel* a confident mistake right after the score-story page names it.
class OnboardingFactOrBluffPage extends HookWidget {
  const OnboardingFactOrBluffPage({
    super.key,
    required this.onSkip,
    required this.onContinue,
  });

  final VoidCallback onSkip;
  final VoidCallback onContinue;

  static const _statements = kOnboardingFactOrBluffStatements;

  @override
  Widget build(BuildContext context) {
    final showResult = useState(false);
    final skipSecondsLeft = useState(3);
    final skipEnabled = useState(false);

    final index = useState(0);
    final answeredIsFact = useState<bool?>(null);
    final correctCount = useState(0);

    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (timer) {
        final next = skipSecondsLeft.value - 1;
        if (next <= 0) {
          skipEnabled.value = true;
          timer.cancel();
        } else {
          skipSecondsLeft.value = next;
        }
      });
      return t.cancel;
    }, const []);

    final item = _statements[index.value];
    final answered = answeredIsFact.value != null;
    final wasCorrect = answered && answeredIsFact.value == item.isFact;

    void answer(bool isFact) {
      if (showResult.value || answered) return;
      answeredIsFact.value = isFact;
      if (isFact == item.isFact) correctCount.value++;
    }

    void next() {
      if (index.value + 1 >= _statements.length) {
        showResult.value = true;
        return;
      }
      index.value++;
      answeredIsFact.value = null;
    }

    final hPad = _onb(context, 22);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, _onb(context, 4), hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _onb(context, 8),
                  vertical: _onb(context, 4),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(_onb(context, 6)),
                ),
                child: Text(
                  'QUICK DEMO',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 10),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: skipEnabled.value ? onSkip : null,
                style: TextButton.styleFrom(
                  foregroundColor: skipEnabled.value
                      ? AppColors.onSurfaceVariantLight
                      : AppColors.gray400,
                  padding: EdgeInsets.symmetric(horizontal: _onb(context, 10)),
                ),
                child: Text(
                  skipEnabled.value
                      ? 'Skip'
                      : 'Skip (${skipSecondsLeft.value})',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _onb(context, 8)),
          if (!showResult.value) ...[
            Text(
              'Fact or bluff?',
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 22),
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.onSurfaceLight,
              ),
            ),
            SizedBox(height: _onb(context, 6)),
            Text(
              'A 30-second taste of how revision feels here — '
              'not a test, just a peek.',
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 14),
                height: 1.45,
                color: AppColors.onSurfaceVariantLight,
              ),
            ),
            SizedBox(height: _onb(context, 10)),
            Text(
              'STATEMENT ${index.value + 1} OF ${_statements.length}',
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 10),
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.onSurfaceVariantLight,
              ),
            ),
            SizedBox(height: _onb(context, 8)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatementCard(
                      statement: item.statement,
                      struckThrough: answered && !item.isFact,
                    ),
                    SizedBox(height: _onb(context, 14)),
                    if (!answered)
                      Row(
                        children: [
                          Expanded(
                            child: _AnswerButton(
                              label: 'FACT',
                              fill: AppColors.primary,
                              foreground: AppColors.onPrimary,
                              onTap: () => answer(true),
                            ),
                          ),
                          SizedBox(width: _onb(context, 10)),
                          Expanded(
                            child: _AnswerButton(
                              label: 'BLUFF',
                              fill: AppColors.surfaceSecondaryLight,
                              foreground: AppColors.onSurfaceLight,
                              border: AppColors.onSurfaceLight,
                              onTap: () => answer(false),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _VerdictBanner(
                        isFact: item.isFact,
                        wasCorrect: wasCorrect,
                        explanation: item.explanation,
                      ),
                      SizedBox(height: _onb(context, 12)),
                      FilledButton(
                        onPressed: next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: _onb(context, 13),
                          ),
                          minimumSize: Size(
                            double.infinity,
                            _onb(context, 46),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                        ),
                        child: Text(
                          index.value + 1 >= _statements.length
                              ? 'See how you did'
                              : 'Next statement',
                          style: GoogleFonts.dmSans(
                            fontSize: _onb(context, 15),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: _OnboardingFactOrBluffResult(
                  correct: correctCount.value,
                  total: _statements.length,
                  onContinue: onContinue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.statement, required this.struckThrough});

  final String statement;
  final bool struckThrough;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _onb(context, 18),
        vertical: _onb(context, 26),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Opacity(
        opacity: struckThrough ? 0.55 : 1,
        child: Text(
          '“$statement”',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 19),
            height: 1.35,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.onSurfaceLight,
            decoration: struckThrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.fill,
    required this.foreground,
    required this.onTap,
    this.border,
  });

  final String label;
  final Color fill;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: _onb(context, 15)),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: border == null
                ? null
                : Border.all(color: border!, width: 1.5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 14),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reveals the truth and whether the user's call was right.
class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({
    required this.isFact,
    required this.wasCorrect,
    required this.explanation,
  });

  final bool isFact;
  final bool wasCorrect;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final bg = wasCorrect ? AppColors.correctBg : AppColors.wrongBg;
    final fg = wasCorrect ? AppColors.correctText : AppColors.wrongText;
    return Container(
      padding: EdgeInsets.all(_onb(context, 14)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: _onb(context, 18),
                color: fg,
              ),
              SizedBox(width: _onb(context, 6)),
              Text(
                wasCorrect
                    ? 'You got it — it\'s a ${isFact ? 'FACT' : 'BLUFF'}'
                    : 'Not this time — it\'s a ${isFact ? 'FACT' : 'BLUFF'}',
                style: GoogleFonts.dmSans(
                  fontSize: _onb(context, 13),
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
          SizedBox(height: _onb(context, 6)),
          Text(
            explanation,
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 13),
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingFactOrBluffResult extends StatelessWidget {
  const _OnboardingFactOrBluffResult({
    required this.correct,
    required this.total,
    required this.onContinue,
  });

  final int correct;
  final int total;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final perfect = correct == total;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _onb(context, 56),
          height: _onb(context, 56),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sports_esports_rounded,
            size: _onb(context, 30),
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: _onb(context, 16)),
        Text(
          perfect ? 'Nice instincts.' : 'Quick reps beat long mocks.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 24),
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.onSurfaceLight,
          ),
        ),
        SizedBox(height: _onb(context, 8)),
        Text(
          'Games like this train recall in under a minute — and Fact or '
          'Bluff is just one of six revision games waiting inside.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 14),
            height: 1.5,
            color: AppColors.onSurfaceVariantLight,
          ),
        ),
        SizedBox(height: _onb(context, 14)),
        Text(
          '$correct / $total correct',
          style: GoogleFonts.dmSans(
            fontSize: _onb(context, 13),
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariantLight,
          ),
        ),
        SizedBox(height: _onb(context, 24)),
        FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: _onb(context, 14)),
            minimumSize: Size(double.infinity, _onb(context, 48)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: Text(
            'Continue',
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 16),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
