# Danger Zone Review — Implementation Plan

## What This Feature Does
Identifies when UPSC aspirants are **confidently wrong** — the most dangerous pattern because of negative marking (-0.66 per wrong answer). Shows them which questions they should have been afraid of but weren't, helping them develop better exam instincts.

---

## Core User Flow

1. Student reads question and selects answer (A/B/C/D)
2. **Before seeing if they got it right**, a prompt appears: "How confident?"
   - Three options: **Very Sure** | **Somewhat Sure** | **Guessing**
   - Single tap selection, no modal dialog
3. Answer submits, explanation reveals
4. Confidence level is stored with the attempt
5. At end of session, if any "Very Sure + Wrong" questions exist:
   - Red warning card appears: "⚠️ DANGER ZONE: X questions"
   - Shows marks that would be lost: "This would cost you Y marks in real exam"
   - Button: "Review Danger Zone Questions"

---

## Why This Timing Matters

**CRITICAL**: Confidence must be captured **BEFORE answer reveal**, not after.

**Why**: Once a student sees they got it wrong, they'll claim they were "unsure" even if they were actually confident before submitting. This is hindsight bias — the brain rewrites the memory. Post-reveal confidence ratings are psychologically contaminated and useless for calibration analysis.

Medical education research confirms: confidence must be measured before outcome knowledge, or the data becomes meaningless.

---

## Why Three Levels, Not Two or Five

**Not Binary (Sure/Unsure)**: Can't distinguish between "I eliminated two options and chose between the remaining two" vs "I have absolutely no idea" — both would be "Unsure" but they're psychologically different.

**Not 5-Point Scale**: Creates decision fatigue. Students will spend cognitive energy deciding between "3 or 4?" instead of thinking about the question. Slows the flow.

**Three Levels Map to Natural Thinking**:
- **Very Sure**: "I know this, I'd bet money on it"
- **Somewhat Sure**: "I eliminated some options, this seems most likely"
- **Guessing**: "I have no idea, picking randomly"

This matches how UPSC students actually think during elimination-based problem solving.

---

## PHASE 1: Foundation + Basic Danger Zone Counter (MVP)

### Goal
Capture confidence, store it with attempts, show Danger Zone count after each session.

### Database Requirement
Add a `confidence` column to the `attempts` table:
- Type: TEXT
- Allowed values: 'very_sure', 'somewhat_sure', 'guessing'
- Nullable (for backward compatibility with existing attempts)

### UI Requirements

#### 1. Confidence Prompt Widget
- Appears immediately after user selects an answer, before submission
- Three buttons in a row: Very Sure (green) | Somewhat Sure (orange) | Guessing (gray)
- Compact design — sits at bottom of screen, doesn't cover question
- Single tap → answer submits
- Visual design: color-coded borders, not filled buttons (lighter visual weight)

#### 2. Modify Question Answering Flow
Current flow:
```
User taps option → Answer submits → Explanation reveals
```

New flow:
```
User taps option → Confidence prompt appears → User taps confidence → Answer submits → Explanation reveals
```

**State management needed**:
- Track selected answer (not yet submitted)
- Show confidence prompt when answer is selected
- Hide confidence prompt after confidence is selected
- Submit answer WITH confidence value

#### 3. Submit Answer Logic
Update the use case that saves attempts to database:
- Add `confidence` as a required parameter
- Store it alongside question_uuid, session_id, selected_answer, is_correct, etc.

#### 4. Session Summary Screen Enhancement
After a practice/learning session completes, check if any attempts have:
- confidence = 'very_sure'
- is_correct = false

If count > 0, display a prominent red warning card:

**Visual design**:
- Red border, light red background
- Warning icon
- Bold text: "⚠️ DANGER ZONE: X questions"
- Subtext: "You were Very Sure but got them wrong"
- Calculation: "In a real exam, this would cost you Y marks" (where Y = count × 0.66)
- Primary button: "Review Danger Zone Questions"

**Placement**: Show this BEFORE the regular session stats (score, time, accuracy). The danger zone is more important than celebration.

#### 5. Query Logic Needed
Create a provider/query that:
- Takes a session_id
- Returns count of attempts where confidence='very_sure' AND is_correct=false
- Use this count to show/hide the Danger Zone card and populate the text

---

## PHASE 2: Danger Zone Review Flow

### Goal
Let students review their Danger Zone questions with full explanations, understanding WHY they were overconfident.

### Review Screen Requirements

#### 1. Data to Display
For each Danger Zone question in the session:
- Question number (1, 2, 3...)
- The question text
- What the student chose vs. what was correct
- Full explanation with trap breakdown

#### 2. Question Card Design
Each question should be a card with:

**Header section** (red background):
- Question number badge
- "You were Very Sure" label
- "You chose: X | Correct: Y" subtext

**Question text section**:
- Full question display
- Preserve any formatting, tables if present

**Explanation section** (collapsible):
- Collapsed by default with "Why you got this wrong" prompt
- Tap to expand
- Show:
  - The trap explanation (from upsc_trap_explanation field)
  - Full explanation (from final_explanation field)
- Collapse/expand icon

#### 3. Navigation
When user taps "Review Danger Zone Questions" button from session summary:
- Navigate to new screen: DangerZoneReviewScreen
- Pass session_id as parameter
- Load all questions where confidence='very_sure' AND is_correct=false for that session

#### 4. Empty State
If user somehow navigates to this screen but has no Danger Zone questions:
- Show friendly message: "No Danger Zone questions in this session!"

#### 5. Query Requirements
Join attempts table with questions table where:
- session_id matches
- confidence = 'very_sure'
- is_correct = false

Fetch question details + explanation for each matched attempt.

---

## PHASE 3: Topic Risk Ranking

### Goal
Show which topics have historically been most dangerous for the student — where they're most overconfident.

### Screen Requirements

#### 1. Data Aggregation
For each topic the student has attempted:
- Count Danger Zone questions (very_sure + wrong) in last 30 days
- Calculate risk level:
  - High Risk: 8+ Danger Zone questions
  - Medium Risk: 3-7 Danger Zone questions
  - Low Risk: 0-2 Danger Zone questions

#### 2. Display Format
List of topics, sorted by Danger Zone count (descending):

Each topic card shows:
- Risk emoji: 🔴 High | 🟡 Medium | 🟢 Low
- Topic name (e.g., "Parliament")
- Subject name (e.g., "Polity")
- Risk level label with color coding
- Count text: "X Danger Zone questions"

**Color scheme**:
- Red for high risk
- Orange for medium risk
- Green for low risk

#### 3. Empty State
If student hasn't practiced enough yet (< 30 days of data or no Danger Zone questions):
- Show: "Not enough data yet. Keep practicing!"

#### 4. Navigation Entry Point
Add this screen to main navigation:
- Icon: warning symbol
- Label: "Topic Risk Ranking"
- Subtitle: "See where you're most overconfident"

#### 5. Query Requirements
Aggregate query that:
- Joins attempts → questions
- Filters: confidence='very_sure' AND is_correct=false AND attempted_at >= (today - 30 days)
- Groups by topic
- Counts Danger Zone questions per topic
- Also includes subject name for context
- Orders by count descending

---

## PHASE 4: Trap-Type Blind Spot Detection

### Goal
Use the unique `trap_type` metadata to show which specific UPSC trap patterns fool the student into false confidence. This is your competitive moat — no other app has this data.

### Screen Requirements

#### 1. Data Aggregation Per Trap Type
For each trap_type (conflation, temporal-swap, scope-extension, etc.) in last 30 days:

Calculate:
- **Very Sure Percentage**: What % of attempts on this trap were marked "very_sure"
- **Accuracy When Sure**: Of those "very_sure" attempts, what % were actually correct
- **Guessing Percentage**: What % of attempts were marked "guessing"
- **Total Attempts**: Sample size for this trap type

Determine calibration status:
- **Danger Zone**: Very Sure % is high (>50%) but Accuracy When Sure is low (<40%)
  - Meaning: This trap fools them into false confidence
- **Known Gap**: Guessing % is high (>60%)
  - Meaning: Good awareness that this trap is tricky, they know they don't know
- **Well Calibrated**: Accuracy When Sure is high (>75%)
  - Meaning: When they're sure, they're usually right
- **Needs Attention**: Middle ground — some calibration issues but not critical
- **Insufficient Data**: Fewer than 3 attempts on this trap type

#### 2. Display Format
List of trap types, sorted by status:
1. Danger Zone traps first (most critical)
2. Needs Attention
3. Known Gap
4. Well Calibrated
5. Insufficient Data last

Each trap card shows:
- Trap type name (formatted: "Conflation", "Temporal Swap" instead of "temporal-swap")
- Status icon and label:
  - ❌ DANGER ZONE (red)
  - ⚠️ Needs Attention (orange)
  - ℹ️ Known Gap (blue) — with "(Good awareness)" subtitle
  - ✅ Well Calibrated (green)
  - ❓ Insufficient Data (gray)
- Insight text explaining what the status means with their specific numbers
- Sample size: "Based on X attempts in last 30 days"

#### 3. Insight Text Examples

**Danger Zone**:
"You're Very Sure 74% of the time, but only correct 31% when sure. This trap is fooling you."

**Known Gap**:
"You're Guessing 65% of the time - good awareness that this trap is tricky."

**Well Calibrated**:
"Your confidence matches your accuracy well on this trap type!"

**Needs Attention**:
"Your confidence doesn't match your accuracy on this trap type yet."

**Insufficient Data**:
"Answer more questions with this trap type to see insights."

#### 4. Navigation Entry Point
Add to main navigation:
- Icon: psychology/brain icon
- Label: "Trap Blind Spots"
- Subtitle: "Which trap types fool you most"

#### 5. Query Requirements
Complex aggregation that:
- Joins attempts → questions
- Filters: attempted_at >= (today - 30 days) AND trap_type IS NOT NULL
- Groups by trap_type
- For each trap, calculates:
  - Count where confidence='very_sure'
  - Count where confidence='very_sure' AND is_correct=true
  - Count where confidence='guessing'
  - Total count
- Derives percentages and status from these counts

---

## Battle Mode Consideration

**DO NOT show confidence prompt in battle mode.**

Reasons:
1. Speed matters in competitive context
2. Adds friction that breaks flow
3. Wrong psychological frame — battles are about performance, not metacognition

**Alternative**: Make it an optional toggle in battle settings for power users who want metacognitive training even in competitive mode. Default: OFF.




---

## PHASE 5 (Future/Optional): Advanced Features

Build these ONLY if Phase 1-4 prove valuable to users. Don't build prematurely.

### 5.1 Historical Danger Zone Trends
**What**: Line chart showing Danger Zone question count over time
- X-axis: Date (last 7/30/90 days selectable)
- Y-axis: Number of Danger Zone questions
- Shows if student is improving (trend going down) or getting worse

**Why delay**: Charts require charting library, more complex UI, and most students won't engage with trends until they understand the basic concept first.

### 5.2 Calibration Curve Visualization
**What**: Academic-style scatter plot
- X-axis: Confidence level (guessing → somewhat sure → very sure)
- Y-axis: Actual accuracy at that confidence level
- Diagonal line = perfect calibration
- Student's actual curve vs. ideal

**Why delay**: Most academic, least emotionally resonant. Power users only. Requires significant UI work for marginal value.

### 5.3 Confidence-Based Spaced Repetition
**What**: Integrate confidence into revision queue logic
- Questions where student was "Very Sure" but wrong → add to queue with SHORTER interval (needs urgent review)
- Questions where student was "Guessing" but correct → LONGER interval (got it by luck, but knows they don't know it)

**Why delay**: Requires deeper integration with revision queue system. Test whether users even value confidence rating before making it affect their study schedule.

---

## Settings & Configuration

### User Preference Toggle
Add to Settings screen:
- **Feature Name**: "Confidence Rating"
- **Description**: "Rate your confidence before seeing answers"
- **Type**: Toggle switch (on/off)
- **Default**: ON
- **Purpose**: Let users disable if they find it slows them down

When disabled:
- Skip confidence prompt entirely
- Don't store confidence in database (leave NULL)
- Don't show Danger Zone sections

### Where This Setting Lives
Settings → Study Preferences → Confidence Rating

---

## Implementation Checklist

### Phase 1 (Foundation - Week 1)
**Database**:
- [ ] Add `confidence` column to `attempts` table with check constraint
- [ ] Create and run migration
- [ ] Verify backward compatibility (existing attempts have NULL confidence)

**UI Components**:
- [ ] Build confidence prompt widget (3 buttons, compact design)
- [ ] Integrate into question answering flow
- [ ] Test: select answer → see prompt → tap confidence → answer submits

**Data Layer**:
- [ ] Update submit attempt use case to accept confidence parameter
- [ ] Create query/provider for Danger Zone count by session
- [ ] Test: can query Danger Zone count for any session_id

**Session Summary**:
- [ ] Add Danger Zone warning card to session summary
- [ ] Show marks lost calculation
- [ ] Add "Review Danger Zone Questions" button (can be non-functional for now)
- [ ] Test: finish session with 3 very_sure+wrong → see warning card

**End-to-End Test**:
- [ ] Answer 10 questions in learning mode
- [ ] Mark 3 as "Very Sure" and get them wrong deliberately
- [ ] Verify Danger Zone count = 3
- [ ] Verify marks lost = 1.98

---

### Phase 2 (Danger Zone Review - Week 2)
**Data Layer**:
- [ ] Create query for Danger Zone questions with full question details
- [ ] Join attempts + questions + explanations
- [ ] Filter by session_id, confidence='very_sure', is_correct=false

**Review Screen**:
- [ ] Create new screen: DangerZoneReviewScreen
- [ ] Build question card component with header/question/explanation sections
- [ ] Implement expand/collapse for explanations
- [ ] Handle empty state (no Danger Zone questions)

**Navigation**:
- [ ] Wire "Review Danger Zone Questions" button to navigate to review screen
- [ ] Pass session_id as route parameter
- [ ] Add route definition

**Testing**:
- [ ] Complete session with Danger Zone questions
- [ ] Tap review button
- [ ] Verify all questions load correctly
- [ ] Tap to expand explanation
- [ ] Verify trap explanation and full explanation both show

---

### Phase 3 (Topic Risk Ranking - Week 3)
**Data Layer**:
- [ ] Create aggregation query: Danger Zone count per topic (last 30 days)
- [ ] Include subject name for context
- [ ] Calculate risk level (high/medium/low) based on count
- [ ] Sort by count descending

**Risk Screen**:
- [ ] Create new screen: TopicRiskScreen
- [ ] Build topic risk card component
- [ ] Color code by risk level (red/orange/green)
- [ ] Handle empty state (not enough data)

**Navigation**:
- [ ] Add menu item on home/dashboard
- [ ] Add route definition
- [ ] Test navigation flow

**Testing**:
- [ ] Practice questions across multiple topics
- [ ] Create Danger Zone questions in some topics
- [ ] Verify topics appear sorted by Danger Zone count
- [ ] Verify risk levels assigned correctly

---

### Phase 4 (Trap Blind Spots - Week 4)
**Data Layer**:
- [ ] Create complex aggregation query per trap_type
- [ ] Calculate: very_sure %, accuracy_when_sure %, guessing %
- [ ] Determine calibration status (danger_zone/known_gap/well_calibrated/etc.)
- [ ] Filter: last 30 days, trap_type NOT NULL

**Blind Spots Screen**:
- [ ] Create new screen: TrapBlindSpotsScreen
- [ ] Build trap calibration card component
- [ ] Format trap type names (conflation → Conflation, temporal-swap → Temporal Swap)
- [ ] Show status icon and insight text
- [ ] Sort by status priority (danger_zone first)
- [ ] Handle empty/insufficient data state

**Navigation**:
- [ ] Add menu item on home/dashboard
- [ ] Add route definition

**Testing**:
- [ ] Practice questions with different trap types
- [ ] Create patterns: high confidence + low accuracy on one trap type
- [ ] Create patterns: high guessing on another trap type
- [ ] Verify status assigned correctly (danger_zone vs known_gap)
- [ ] Verify insight text matches actual numbers

---

## Testing Strategy

### Manual Test Scenarios

**Scenario 1: Basic Flow**
1. Start learning mode session
2. Answer question, select option A
3. Confidence prompt appears
4. Tap "Very Sure"
5. Answer submits, explanation shows
6. Verify confidence stored in database = 'very_sure'

**Scenario 2: Danger Zone Detection**
1. Answer 10 questions
2. For 3 questions: mark "Very Sure" + select wrong answer
3. For 7 questions: mark any confidence + select correct answer
4. Complete session
5. Verify Danger Zone card shows: "3 questions"
6. Verify marks lost = 1.98

**Scenario 3: Danger Zone Review**
1. Session with Danger Zone questions (from Scenario 2)
2. Tap "Review Danger Zone Questions"
3. Verify navigation to review screen
4. Verify 3 questions displayed
5. Verify each shows: question text, selected answer, correct answer
6. Tap to expand explanation
7. Verify trap explanation + full explanation visible

**Scenario 4: Topic Risk**
1. Practice Ancient History with 8 Danger Zone questions
2. Practice Polity with 2 Danger Zone questions
3. Navigate to Topic Risk Ranking
4. Verify Ancient History shows "High Risk" (red)
5. Verify Polity shows "Low Risk" (green)
6. Verify sorted: Ancient History first

**Scenario 5: Trap Blind Spots**
1. Practice conflation traps: 10 attempts, 7 very_sure, 2 correct when sure
2. Practice temporal-swap traps: 10 attempts, 8 guessing
3. Navigate to Trap Blind Spots
4. Verify conflation shows "DANGER ZONE" (very sure 70%, correct 29%)
5. Verify temporal-swap shows "Known Gap" (guessing 80%)

### Edge Cases to Test

**Empty States**:
- Session with 0 Danger Zone questions → no warning card shown
- Topic Risk with no data → "Not enough data" message
- Trap Blind Spots with insufficient attempts → "Insufficient Data" status

**Null Confidence**:
- Old attempts with NULL confidence → excluded from Danger Zone calculations
- Mixed session (some with confidence, some without) → count only those with confidence

**Date Filtering**:
- Topic Risk uses last 30 days → attempts older than 30 days excluded
- Trap Blind Spots uses last 30 days → verify filtering works

**Language Handling**:
- Review screen shows question in user's selected language (en/hi)
- Explanation shown in correct language

---

## Performance Considerations

### Database Indexing
After implementing, add indexes for common queries:
- Index on `attempts.confidence`
- Index on `attempts.attempted_at` (for date filtering)
- Index on `questions.trap_type`
- Composite index on `(session_id, confidence, is_correct)` for Danger Zone queries

### Query Optimization
**Phase 3 & 4 involve aggregations**:
- Always filter by date range (last 30 days) to limit data scanned
- Use database-level aggregations (COUNT, GROUP BY) rather than loading all rows into memory
- If Danger Zone review has 50+ questions, consider pagination (load 10 at a time)

---

## Feature Naming & Branding

### Internal Code Names
Use these in code, file names, variables:
- `danger_zone` (not `overconfidence` or `calibration`)
- `confidence_rating`
- `trap_blind_spots`
- `topic_risk`

### User-Facing Labels
Use these in UI:
- "Danger Zone Review" (not "Overconfidence Report")
- "How confident?" (not "Rate your certainty")
- "Topic Risk Ranking" (not "Topic Calibration Analysis")
- "Trap Blind Spots" (not "Metacognitive Trap Assessment")

**Why**: Users buy exam survival, not academic analytics. The language should be emotionally direct and jargon-free.

---

## Success Metrics (Post-Launch)

### Engagement Metrics
- **Confidence Rating Adoption**: % of attempts with confidence value (target: >80%)
- **Danger Zone Review Rate**: % of sessions with Danger Zone where user taps review button (target: >60%)
- **Topic Risk Screen Views**: How many users navigate to this screen weekly

### Learning Outcome Metrics
- **Danger Zone Reduction**: Do students have fewer Danger Zone questions over time? (Track trend)
- **Confidence Calibration Improvement**: Does accuracy-when-sure improve over weeks?
- **Trap Awareness**: Do students shift from "very_sure" to "somewhat_sure" on their blind spot trap types?

### User Feedback
- Session summary screen gets thumbs up/down — does Danger Zone warning affect rating?
- Settings toggle usage — do users disable confidence rating? (If >20% disable, UX is too slow)

---

## Known Limitations & Future Considerations

### Current Scope Limitations
- Confidence rating not available in battle mode (by design)
- No confidence-based revision queue integration (Phase 5)
- No historical trends/charts (Phase 5)
- 30-day rolling window for analytics (not configurable)

### Technical Debt to Address Later
- If Danger Zone review loads 100+ questions, pagination needed
- Aggregation queries may slow down as attempts table grows to 100k+ rows
- No caching of topic risk / trap calibration calculations (recalculated on every screen load)

### User Experience Gaps
- No onboarding/tutorial explaining what Danger Zone means (assumes users understand negative marking)
- No way to compare your calibration against other students (peer comparison)
- No push notifications/reminders for reviewing Danger Zone questions

These are intentionally deferred — ship Phase 1-4 first, validate value, then decide what to build next.