import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import '../data/onboarding_mcq_data.dart';
import 'onboarding_scale.dart';

/// Screen 3 — markable demo MCQ with a confidence selector, plus
/// confidence-aware correct / wrong / skipped outcome states.
///
/// Picking confidence immediately reveals the answer. The question stays
/// on screen and the explanation scrolls in below it.
class OnboardingMcqPage extends StatelessWidget {
  const OnboardingMcqPage({
    super.key,
    required this.selectedIndex,
    required this.confidence,
    required this.outcome,
    required this.onSelect,
    required this.onConfidenceSelect,
    required this.onContinue,
    required this.onGotIt,
  });

  final int? selectedIndex;
  final OnboardingMcqConfidence? confidence;
  final OnboardingMcqOutcome? outcome;
  final ValueChanged<int> onSelect;
  final ValueChanged<OnboardingMcqConfidence> onConfidenceSelect;
  final VoidCallback onContinue;
  final VoidCallback onGotIt;

  @override
  Widget build(BuildContext context) {
    final revealed = outcome != null;
    // Awaiting confidence: no bottom CTA — reveal happens on chip tap.
    // No selection yet: Continue skips into the elimination outcome.
    final showBottomCta = revealed || selectedIndex == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: revealed
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _McqBody(
                    selectedIndex: selectedIndex,
                    confidence: confidence,
                    outcome: outcome,
                    onSelect: onSelect,
                    onConfidenceSelect: onConfidenceSelect,
                  ),
                )
              : OnboardingFit(
                  child: _McqBody(
                    selectedIndex: selectedIndex,
                    confidence: confidence,
                    outcome: outcome,
                    onSelect: onSelect,
                    onConfidenceSelect: onConfidenceSelect,
                  ),
                ),
        ),
        if (showBottomCta) ...[
          SizedBox(height: onb(context, 14)),
          FilledButton(
            onPressed: revealed ? onGotIt : onContinue,
            style: RgText.pillButton(
              fill: RgColors.ink,
              verticalPadding: onb(context, 16),
            ).copyWith(
              minimumSize: WidgetStatePropertyAll(
                Size(double.infinity, onb(context, 56)),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(onb(context, 14)),
                ),
              ),
            ),
            child: Text(
              revealed ? 'Got it' : 'Continue',
              style: RgText.body(
                size: onb(context, 17),
                weight: FontWeight.w700,
                color: RgColors.onDark,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _McqBody extends StatelessWidget {
  const _McqBody({
    required this.selectedIndex,
    required this.confidence,
    required this.outcome,
    required this.onSelect,
    required this.onConfidenceSelect,
  });

  final int? selectedIndex;
  final OnboardingMcqConfidence? confidence;
  final OnboardingMcqOutcome? outcome;
  final ValueChanged<int> onSelect;
  final ValueChanged<OnboardingMcqConfidence> onConfidenceSelect;

  @override
  Widget build(BuildContext context) {
    final revealed = outcome != null;
    // Answered without picking a confidence level reads as a guess.
    final conf = confidence ?? OnboardingMcqConfidence.guessing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          kOnboardingMcq.eyebrow.toUpperCase(),
          style: RgText.mono(
            size: onb(context, 12),
            letterSpacingEm: 0.13,
            color: RgColors.wrong,
          ),
        ),
        SizedBox(height: onb(context, 10)),
        Text(
          revealed && outcome == OnboardingMcqOutcome.skipped
              ? kOnboardingMcq.skippedHeadline
              : kOnboardingMcq.prompt,
          style: RgText.display(
            size: onb(context, 24),
            weight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        SizedBox(height: onb(context, 18)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: onb(context, 16),
            vertical: onb(context, 16),
          ),
          decoration: BoxDecoration(
            color: RgColors.card,
            borderRadius: BorderRadius.circular(onb(context, 16)),
            border: Border.all(color: RgColors.border),
          ),
          child: Text(
            kOnboardingMcq.question,
            style: RgText.body(
              size: onb(context, 16),
              weight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: onb(context, 14)),
        for (var i = 0; i < kOnboardingMcq.options.length; i++) ...[
          if (revealed)
            _RevealedOption(
              option: kOnboardingMcq.options[i],
              kind: _revealKindFor(
                index: i,
                outcome: outcome!,
                selectedIndex: selectedIndex,
              ),
              confidence: selectedIndex == i ? conf : null,
            )
          else ...[
            _OptionRow(
              option: kOnboardingMcq.options[i],
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
            if (selectedIndex == i) ...[
              SizedBox(height: onb(context, 10)),
              _ConfidenceSelector(
                confidence: confidence,
                onSelect: onConfidenceSelect,
              ),
            ],
            if (i < kOnboardingMcq.options.length - 1)
              SizedBox(height: onb(context, 10)),
          ],
        ],
        if (revealed) ...[
          SizedBox(height: onb(context, 10)),
          if (outcome != OnboardingMcqOutcome.skipped) ...[
            Text(
              _outcomeHeadline(outcome!, conf),
              style: RgText.display(
                size: onb(context, 18),
                weight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            SizedBox(height: onb(context, 12)),
          ],
          switch (outcome!) {
            OnboardingMcqOutcome.skipped => const _SkippedExplanation(),
            OnboardingMcqOutcome.correct => _TrapAndPromise(
              trapBody: kOnboardingMcq.trapBodyCorrect,
              promiseBody: conf == OnboardingMcqConfidence.confident
                  ? kOnboardingMcq.promiseCorrectConfident
                  : kOnboardingMcq.promiseCorrectGuess,
            ),
            OnboardingMcqOutcome.wrong => _TrapAndPromise(
              trapBody: kOnboardingMcq.trapBodyWrong,
              promiseBody: conf == OnboardingMcqConfidence.confident
                  ? kOnboardingMcq.promiseWrongConfident
                  : kOnboardingMcq.promiseWrongGuess,
            ),
          },
          SizedBox(height: onb(context, 12)),
          Text(
            kOnboardingMcq.richerNote,
            style: RgText.body(
              size: onb(context, 13),
              height: 1.45,
              color: RgColors.muted,
              weight: FontWeight.w500,
            ),
          ),
          // Extra bottom padding so the last line clears the sticky CTA.
          SizedBox(height: onb(context, 8)),
        ],
      ],
    );
  }
}

String _outcomeHeadline(
  OnboardingMcqOutcome outcome,
  OnboardingMcqConfidence conf,
) {
  final confident = conf == OnboardingMcqConfidence.confident;
  return switch (outcome) {
    OnboardingMcqOutcome.skipped => kOnboardingMcq.skippedHeadline,
    OnboardingMcqOutcome.correct => confident
        ? kOnboardingMcq.headlineCorrectConfident
        : kOnboardingMcq.headlineCorrectGuess,
    OnboardingMcqOutcome.wrong => confident
        ? kOnboardingMcq.headlineWrongConfident
        : kOnboardingMcq.headlineWrongGuess,
  };
}

_RevealKind _revealKindFor({
  required int index,
  required OnboardingMcqOutcome outcome,
  required int? selectedIndex,
}) {
  final option = kOnboardingMcq.options[index];
  if (option.isCorrect) return _RevealKind.correct;
  if (outcome == OnboardingMcqOutcome.wrong && selectedIndex == index) {
    return _RevealKind.wrongPick;
  }
  if (outcome == OnboardingMcqOutcome.skipped) {
    final elimination = index < kOnboardingMcq.eliminations.length
        ? kOnboardingMcq.eliminations[index]
        : null;
    if (elimination != null && !elimination.keep) {
      return _RevealKind.eliminated;
    }
  }
  return _RevealKind.neutral;
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingMcqOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : RgColors.card,
      borderRadius: BorderRadius.circular(onb(context, 14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(onb(context, 14)),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: onb(context, 14),
            vertical: onb(context, 16),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(onb(context, 14)),
            border: Border.all(
              color: selected ? AppColors.primary : RgColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: onb(context, 28),
                height: onb(context, 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : RgColors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : RgColors.border,
                  ),
                ),
                child: Text(
                  option.letter,
                  style: RgText.mono(
                    size: onb(context, 12),
                    weight: FontWeight.w600,
                    color: selected ? RgColors.onDark : RgColors.muted,
                  ),
                ),
              ),
              SizedBox(width: onb(context, 12)),
              Expanded(
                child: Text(
                  option.text,
                  style: RgText.body(
                    size: onb(context, 15),
                    weight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceSelector extends StatelessWidget {
  const _ConfidenceSelector({
    required this.confidence,
    required this.onSelect,
  });

  final OnboardingMcqConfidence? confidence;
  final ValueChanged<OnboardingMcqConfidence> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW SURE ARE YOU?',
          style: RgText.mono(
            size: onb(context, 11),
            letterSpacingEm: 0.1,
            color: RgColors.muted,
          ),
        ),
        SizedBox(height: onb(context, 8)),
        Row(
          children: [
            Expanded(
              child: _ConfidenceChip(
                label: 'Confident',
                icon: Icons.bolt_rounded,
                selected: confidence == OnboardingMcqConfidence.confident,
                selectedFill: RgColors.tealDeep,
                onTap: () => onSelect(OnboardingMcqConfidence.confident),
              ),
            ),
            SizedBox(width: onb(context, 10)),
            Expanded(
              child: _ConfidenceChip(
                label: 'Guessing',
                icon: Icons.casino_outlined,
                selected: confidence == OnboardingMcqConfidence.guessing,
                selectedFill: RgColors.warningText,
                onTap: () => onSelect(OnboardingMcqConfidence.guessing),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedFill,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? RgColors.onDark : RgColors.muted;
    return Material(
      color: selected ? selectedFill : RgColors.card,
      borderRadius: BorderRadius.circular(onb(context, 12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(onb(context, 12)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: onb(context, 12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(onb(context, 12)),
            border: Border.all(
              color: selected ? selectedFill : RgColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: onb(context, 17), color: fg),
              SizedBox(width: onb(context, 7)),
              Text(
                label,
                style: RgText.body(
                  size: onb(context, 14),
                  weight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrapAndPromise extends StatelessWidget {
  const _TrapAndPromise({
    required this.trapBody,
    required this.promiseBody,
  });

  final String trapBody;
  final String promiseBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TrapCard(body: trapBody),
        SizedBox(height: onb(context, 10)),
        _PromiseCard(body: promiseBody),
      ],
    );
  }
}

class _TrapCard extends StatelessWidget {
  const _TrapCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(onb(context, 16)),
      decoration: BoxDecoration(
        color: RgColors.ink,
        borderRadius: BorderRadius.circular(onb(context, 14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kOnboardingMcq.trapTitle.toUpperCase(),
            style: RgText.mono(
              size: onb(context, 11),
              letterSpacingEm: 0.08,
              color: RgColors.wrong,
            ),
          ),
          SizedBox(height: onb(context, 8)),
          Text(
            body,
            style: RgText.body(
              size: onb(context, 14),
              height: 1.5,
              color: AppColors.gray100,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromiseCard extends StatelessWidget {
  const _PromiseCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(onb(context, 14)),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(onb(context, 14)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        body,
        style: RgText.body(
          size: onb(context, 14),
          height: 1.55,
          color: RgColors.tealDeep,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RevealedOption extends StatelessWidget {
  const _RevealedOption({
    required this.option,
    required this.kind,
    this.confidence,
  });

  final OnboardingMcqOption option;
  final _RevealKind kind;
  final OnboardingMcqConfidence? confidence;

  @override
  Widget build(BuildContext context) {
    final wrong = kind == _RevealKind.wrongPick;
    final right = kind == _RevealKind.correct;
    final eliminated = kind == _RevealKind.eliminated;
    final isPick = confidence != null;
    final confident = confidence == OnboardingMcqConfidence.confident;

    return Container(
      margin: EdgeInsets.only(bottom: onb(context, 8)),
      padding: EdgeInsets.symmetric(
        horizontal: onb(context, 14),
        vertical: onb(context, 14),
      ),
      decoration: BoxDecoration(
        color: wrong
            ? AppColors.wrongBg
            : right
            ? AppColors.correctBg
            : RgColors.card,
        borderRadius: BorderRadius.circular(onb(context, 14)),
        border: Border.all(
          color: wrong
              ? RgColors.wrongBorder
              : right
              ? RgColors.correctBorder
              : RgColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: onb(context, 28),
            height: onb(context, 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: wrong
                  ? RgColors.wrong
                  : right
                  ? RgColors.teal
                  : RgColors.transparent,
              border: Border.all(
                color: wrong
                    ? RgColors.wrong
                    : right
                    ? RgColors.teal
                    : RgColors.border,
              ),
            ),
            child: Text(
              option.letter,
              style: RgText.mono(
                size: onb(context, 12),
                weight: FontWeight.w600,
                color: wrong || right ? RgColors.onDark : RgColors.muted,
              ),
            ),
          ),
          SizedBox(width: onb(context, 12)),
          Expanded(
            child: Text(
              option.text,
              style: RgText.body(
                size: onb(context, 15),
                weight: FontWeight.w500,
                color: eliminated ? RgColors.muted : RgColors.ink,
                decoration: eliminated ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isPick || wrong || right)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isPick)
                  Text(
                    confident ? 'CONFIDENT' : 'GUESSING',
                    style: RgText.mono(
                      size: onb(context, 10),
                      color: confident
                          ? RgColors.tealDeep
                          : RgColors.warningText,
                    ),
                  ),
                if (wrong || right) ...[
                  if (isPick) SizedBox(height: onb(context, 2)),
                  Text(
                    wrong ? 'YOUR PICK' : 'CORRECT',
                    style: RgText.mono(
                      size: onb(context, 10),
                      color: wrong ? RgColors.wrong : RgColors.tealDeep,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

enum _RevealKind { wrongPick, correct, eliminated, neutral }

class _SkippedExplanation extends StatelessWidget {
  const _SkippedExplanation();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in kOnboardingMcq.eliminations) ...[
          Padding(
            padding: EdgeInsets.only(bottom: onb(context, 10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.keep ? '✓' : '✕',
                  style: RgText.body(
                    size: onb(context, 15),
                    weight: FontWeight.w700,
                    color: e.keep ? RgColors.tealDeep : RgColors.wrong,
                  ),
                ),
                SizedBox(width: onb(context, 10)),
                Expanded(
                  child: Text(
                    e.text,
                    style: RgText.body(
                      size: onb(context, 15),
                      height: 1.4,
                      weight: e.keep ? FontWeight.w600 : FontWeight.w400,
                      color: e.keep ? RgColors.tealDeep : RgColors.muted,
                      decoration: e.keep ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: onb(context, 10)),
        _PromiseCard(body: kOnboardingMcq.promiseSkipped),
      ],
    );
  }
}
