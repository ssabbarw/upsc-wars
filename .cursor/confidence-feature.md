# Danger Zone Review — Revised MVP Plan (Updated)

## Strategic Change Summary

This version updates the original plan to reduce complexity, improve adoption, and make the feature safer for MVP release.

### Major Product Decisions

### Keep in MVP

* Confidence capture BEFORE answer reveal
* 3 confidence levels: Very Sure / Somewhat Sure / Guessing
* Session-level Danger Zone warning
* Danger Zone Review screen
* Subject-scoped Danger Zone insights
* Topic Risk Ranking (subject-level)
* Progressive unlock system
* Global confidence toggle in settings

### Remove from MVP (defer)

* Trap Blind Spots
* Cross-subject Overall Insights screen
* Trend charts
* Calibration curves
* Battle-mode confidence toggles
* Complex trap-type scoring systems

Reason: These add major complexity before validating whether users even like confidence tracking.

We must first validate usage and retention.

---

# Core Principle

We are not building analytics for academic psychology.

We are building:

## "You were confidently wrong — this would cost marks in UPSC"

This must feel practical, urgent, and emotionally clear.

Not theoretical.

---

# Critical UX Change: Adaptive Confidence Prompt

## Do NOT ask confidence forever on every question

This creates fatigue and users will start hating the feature.

### New Rule

Ask confidence only for:

* first 100–150 attempts
* PYQ questions
* hard questions
* trap-heavy questions
* weak topics
* revision-critical questions

Do NOT interrupt every easy routine question forever.

This preserves signal quality while protecting UX.

This is mandatory.

---

# PHASE 1 — Foundation + Session-Level Danger Zone

## Goal

Capture confidence, detect dangerous overconfidence, and show one powerful post-session warning.

---

# Confidence Capture

## Flow

### Old

User taps option → answer submits

### New

User taps option → confidence prompt appears → user selects confidence → answer submits

### Confidence Options

* Very Sure
* Somewhat Sure
* Guessing

Must happen BEFORE answer reveal.

This is non-negotiable.

---

# Session Summary Change (Important)

## Show ONE Hero Message

Do not overload session summary with too many competing insights.

### Replace with:

# Today's Biggest Mistake

Example:

⚠️ You were confidently wrong on 4 questions

This would cost 2.64 marks in UPSC Prelims

[Review Danger Zone Questions]

This becomes the emotional anchor.

Secondary stats like score, accuracy, time appear below.

Danger Zone must feel primary.

---

# Database Requirement

Add nullable `confidence` column to attempts table.

Allowed values:

* very_sure
* somewhat_sure
* guessing

Existing attempts remain NULL.

Queries must ignore NULL confidence.

---

# PHASE 2 — Danger Zone Review Screen

## Goal

Let users review exactly where they were confidently wrong.

---

# Review Screen Includes

For each question:

* full question
* selected answer vs correct answer
* explanation
* UPSC trap explanation
* subject + topic context

Header should say:

## You were Very Sure

This reinforces learning.

This screen is one of the highest-value parts of the feature.

Do not make it visually weak.

---

# PHASE 3 — Subject-Level Insights

## Goal

Show Danger Zone intelligence inside:

## Subject Detail → Insights Section

Only subject-scoped.

Never global-first.

---

# Card 1 — Danger Zone Summary

Show:

* total Danger Zone questions (last 30 days)
* marks lost estimate
* Review All button

Example:

Ancient History
⚠️ 12 Danger Zone questions
Would cost 7.92 marks

If zero:

🟢 Well calibrated this month

---

# Card 2 — Topic Risk Ranking

## Purpose

Which topics inside this subject are most dangerous?

---

# Important Change

## Use Dynamic Risk Ranking

Do NOT use fixed thresholds like:

* 8+ red
* 3–7 yellow

This breaks for different user sizes.

### Use Percentile-Based Ranking

Example:

* Top 20% risky topics → Red
* Next 30% → Yellow
* Remaining → Green

This scales correctly for all users.

Much better than fixed numbers.

---

# Remove Trap Blind Spots from MVP

## Deferred Completely

Reason:

* depends heavily on trap_type quality
* too complex for first release
* easy to create low-trust noisy output
* too advanced for early users

We will revisit only after strong adoption of Danger Zone itself.

Not before.

---

# New Addition — Calibration Score

## Add a simple sticky score

This is important.

Example:

# Confidence Calibration Score

72 / 100

Meaning:

How accurately your confidence matches your actual performance.

This improves:

* repeat usage
* gamification
* habit formation
* user motivation

Users remember scores.

They do not remember raw analytics.

This should be added after basic Danger Zone flow is stable.

---

# Simplified Release Plan

## TRUE MVP

### Build First

* confidence capture
* session danger warning
* review screen
* subject danger summary
* topic risk ranking

Only this.

---

## Version 2

Add:

* adaptive prompts refinement
* calibration score
* better revision integration

---

## Version 3

Add:

* trap blind spots
* overall insights
* trend systems
* advanced analytics

Only after proof of engagement.

---

# Success Metric

Not:

"Did we build everything?"

But:

# Do users keep using it?

That is the only real metric.

This feature becomes a moat only if students repeatedly return to it.

Retention first.

Complexity later.
